require 'aws-sdk-cloudfront'
require 'aws-sdk-s3'
require 'fileutils'
require 'mime/types'
require 'net/http'
require 'open3'
require 'uri'
require_relative 'models/invalidation_paths'

base_dir = "./build/"
Dir.chdir(base_dir)
bucket = "ason.as"
region = "ap-northeast-1"
acl = "public-read"

client = Aws::S3::Client.new(region: region)

# HTMLは更新を即座に反映したいので常に再検証させる。配信時はCloudFrontのinvalidationで鮮度を担保する。
html_cache_control = "public, max-age=0, must-revalidate"
# CSS/JS/画像は長期キャッシュさせる。これらが変更された場合は下のinvalidationでCloudFront側を無効化する。
asset_cache_control = "public, max-age=31536000"

Dir.glob("**/*.html").each do |file|
  client.put_object(bucket: bucket, key: file, body: File.read(file), content_type: "text/html", acl: acl,
cache_control: html_cache_control)
end
Dir.glob("articles/*").each do |file|
  client.put_object(bucket: bucket, key: file, body: File.read(file), content_type: "text/html", acl: acl,
cache_control: html_cache_control)
end

Dir.glob(["**/*.css", "images/**/*", "javascripts/*"]).each do |file|
  next if FileTest.directory?(file)
  type = MIME::Types.type_for(file).first.to_s
  client.put_object(bucket: bucket, key: file, body: File.read(file), content_type: type, acl: acl,
cache_control: asset_cache_control)
end

client.put_object(bucket: bucket, key: "feed", body: File.read("feed"), content_type: "application/rss+xml", acl: acl,
cache_control: html_cache_control)

# Bluesky OAuthのclient metadataなど、JSONはContent-Type: application/jsonで配信する必要がある。
# 通常のassetグロブには含まれないため個別にアップロードする。`**/*.json`はドットディレクトリを
# 辿らないため、.well-known配下は明示的に対象へ加える。内容更新を即反映させたいのでHTMLと同じ再検証ポリシーにする。
Dir.glob(["**/*.json", ".well-known/*.json"]).each do |file|
  next if FileTest.directory?(file)
  client.put_object(bucket: bucket, key: file, body: File.read(file), content_type: "application/json", acl: acl,
cache_control: html_cache_control)
end

begin
  revision_response = Net::HTTP.get_response(URI.parse("https://ason.as/revision"))
  prev_revision = revision_response.body.to_s.strip
rescue StandardError => e
  # アップロードは済んでいるので、ここで止めずに全体を無効化する
  puts "Failed to fetch the previous revision: #{e.class}: #{e.message}"
end
puts prev_revision

# 404 の本文や空文字列を revision として git に渡すと、別の範囲の差分が成功扱いで返る
if revision_response.is_a?(Net::HTTPSuccess) && prev_revision.match?(/\A\h{40}\z/)
  diff_output, diff_status = Open3.capture2("git", "diff", "--name-only", "#{prev_revision}..HEAD")
end

invalidation_items =
  if diff_status&.success?
    changed_files = diff_output.split("\n")
    puts changed_files
    InvalidationPaths.for_files(changed_files)
  else
    # 前回のrevisionが辿れないと変更範囲が分からないため、全体を無効化する
    ["/*"]
  end

puts invalidation_items.uniq

cloud_front_client = Aws::CloudFront::Client.new(region: region)
cloud_front_client.create_invalidation(
  distribution_id: ENV["AWS_DISTRIBUTION_ID"],
  invalidation_batch: {
    paths: {
      quantity: invalidation_items.uniq.size,
      items: invalidation_items.uniq,
    },
    caller_reference: Time.now.to_s,
  },
)
