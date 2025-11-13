# frozen_string_literal: true

unless Rails.env.test?
  Aws.config.update(
    region: ENV.fetch("MINIO_REGION", "us-east-1"),
    endpoint: ENV.fetch("MINIO_ENDPOINT", "http://localhost:9000"),
    force_path_style: true,
    credentials: Aws::Credentials.new(
      ENV.fetch("MINIO_ROOT_USER", "minioadmin"),
      ENV.fetch("MINIO_ROOT_PASSWORD", "minioadmin")
    )
  )
end

Rails.application.config.documents_bucket = ENV.fetch("MINIO_BUCKET", "bucket")
