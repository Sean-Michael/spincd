output "scan_bucket" {
  description = "S3 bucket name for scan images"
  value       = aws_s3_bucket.content.bucket
}

output "scan_base_url" {
  description = "Value to set as SCAN_BASE_URL on the spinCD app"
  value       = "https://${aws_s3_bucket.content.bucket}.s3.${data.aws_region.current.region}.amazonaws.com/${var.scan_prefix}"
}

output "uploader_credentials" {
  description = "Access keys for the scan-uploader IAM user (use with `pipeline upload`)"
  sensitive   = true
  value = {
    AWS_ACCESS_KEY_ID     = aws_iam_access_key.scan_uploader_key.id
    AWS_SECRET_ACCESS_KEY = aws_iam_access_key.scan_uploader_key.secret
    AWS_REGION            = data.aws_region.current.region
  }
}
