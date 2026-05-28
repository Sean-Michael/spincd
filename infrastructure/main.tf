data "aws_region" "current" {}

# S3 bucket holding processed CD scan images (front/back/disc per album).
resource "aws_s3_bucket" "content" {
  bucket = "${var.project_name}-content"

  tags = {
    Name    = "${var.project_name}-content"
    Project = var.project_name
  }
}

resource "aws_s3_bucket_versioning" "content" {
  bucket = aws_s3_bucket.content.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Allow a public bucket policy (but not public ACLs) so scans can be served
# directly to browsers via their S3 URLs.
resource "aws_s3_bucket_public_access_block" "content" {
  bucket = aws_s3_bucket.content.id

  block_public_acls       = true
  block_public_policy     = false
  ignore_public_acls      = true
  restrict_public_buckets = false
}

# Public read scoped to the scans/ prefix only.
resource "aws_s3_bucket_policy" "content_scans_public" {
  bucket     = aws_s3_bucket.content.id
  depends_on = [aws_s3_bucket_public_access_block.content]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadScans"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.content.arn}/${var.scan_prefix}/*"
      }
    ]
  })
}

# IAM user used to upload processed scans (via `pipeline upload`).
resource "aws_iam_user" "scan_uploader" {
  name = "${var.project_name}-scan-uploader"
}

resource "aws_iam_user_policy" "scan_uploader_s3" {
  name = "${var.project_name}-scan-upload"
  user = aws_iam_user.scan_uploader.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ScanUpload"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.content.arn,
          "${aws_s3_bucket.content.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_access_key" "scan_uploader_key" {
  user = aws_iam_user.scan_uploader.name
}
