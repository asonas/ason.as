require 'aws-sdk-cloudfront'
require 'aws-sdk-s3'
require 'fileutils'
require 'mime/types'
require 'net/http'
require 'uri'

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

default_invalidation_items = %w[
  /
  /index.html
  /feed
]
invalidation_items = default_invalidation_items

prev_revision = Net::HTTP.get(URI.parse("https://ason.as/revision")).chomp
puts prev_revision

templates = %w[
  source/articles/index.html.haml
  source/articles/show.html.haml
  source/layouts/layout.haml
]
`git diff #{prev_revision}..master --name-only`.split("\n").each do |file|
  puts file
  if templates.include? file
    invalidation_items.push "/articles"
    invalidation_items.push "/articles/*"
  elsif file.start_with? "source"
    item = "/" + file.gsub("source/", "")
    if item.end_with?(".scss") || item.end_with?(".css")
      # CSSはwebpackで /stylesheets/site.css に抽出して配信している。
      invalidation_items.push "/stylesheets/site.css"
    else
      invalidation_items.push item
    end
  elsif file.end_with? ".md"
    # e.g. articles/foo-bar.md -> /articles/foo-bar
    invalidation_items.push "/" + file.gsub(/\.md$/, "")
  end
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
