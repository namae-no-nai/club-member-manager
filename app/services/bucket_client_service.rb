# frozen_string_literal: true

class BucketClientService
  def initialize(
    bucket_name: Rails.application.config.documents_bucket,
    client: Aws::S3::Client.new
  )
    @bucket = Aws::S3::Resource.new(client:).bucket(bucket_name)
  end

  def read_file_content(file_name:)
    s3_object = @bucket.object(file_name)
    s3_object.get.body.read
  end

  def upload_file(file_name:, file_content:)
    @bucket.put_object(body: file_content, key: file_name)
  end

  def generate_public_url(file_name:, url_expires_in:)
    @bucket
      .object(file_name)
      .presigned_url(:get, expires_in: url_expires_in.to_i)
  end
end
