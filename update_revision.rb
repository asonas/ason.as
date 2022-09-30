require 'aws-sdk-cloudfront'
require 'aws-sdk-s3'

base_dir = "./build/"
Dir.chdir(base_dir)
bucket = "ason.as"
region = "ap-northeast-1"
acl = "public-read"

client = Aws::S3::Client.new(region: region)

client.put_object(bucket: bucket, key: "revision", body: File.read("revision"), content_type: "text/plain", acl: acl)
cloud_front_client = Aws::CloudFront::Client.new(region: region)
cloud_front_client.create_invalidation(
  distribution_id: ENV["AWS_DISTRIBUTION_ID"],
  invalidation_batch: {
    paths: {
      quantity: 1,
      items: ["/revision"],
    },
    caller_reference: Time.now.to_s,
  },
)
