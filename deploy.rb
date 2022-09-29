require 'aws-sdk-cloudfront'
require 'aws-sdk-s3'
require 'fileutils'
require 'mime/types'

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

cloud_front_client = Aws::CloudFront::Client.new(region: region)
cloud_front_client.create_invalidation(
  distribution_id: ENV["AWS_DISTRIBUTION_ID"],
  invalidation_batch: {
    paths: {
      quantity: 1,
      items: ["/index.html", "/feed"],
    },
    caller_reference: Time.now.to_s,
  },
)
