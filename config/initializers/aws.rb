require 'aws-sdk-s3'

Aws.config.update({
  region: 'us-east-1', # e.g. 'us-west-2'
  credentials: Aws::Credentials.new(
    Rails.application.credentials.aws[:access_key_id],
    Rails.application.credentials.aws[:secret_access_key]
  )
})

S3_CLIENT = Aws::S3::Client.new
