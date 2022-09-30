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

Dir.glob("**/*.html").each do |file|
  client.put_object(bucket: bucket, key: file, body: File.read(file), content_type: "text/html", acl: acl)
end
Dir.glob("articles/*").each do |file|
  client.put_object(bucket: bucket, key: file, body: File.read(file), content_type: "text/html", acl: acl)
end

Dir.glob(["**/*.css", "images/**/*", "javascripts/*"]).each do |file|
  next if FileTest.directory?(file)
  type = MIME::Types.type_for(file).first.to_s
  client.put_object(bucket: bucket, key: file, body: File.read(file), content_type: type, acl: acl)
end

client.put_object(bucket: bucket, key: "feed", body: File.read("feed"), content_type: "application/rss+xml", acl: acl)

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
    if item.end_with? ".scss"
      invalidation_items.push "/javascripts/site.js"
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
