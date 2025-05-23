# Note: I have opted not to use versioning for this bucket on the understanding that the
# script files will be in source control.

terraform {
  required_providers {  # TODO: assess this
    aws = {
      source  = "hashicorp/aws"
      # version = "~> 4.0"
    }
  }
}

resource "aws_s3_bucket" "secrets_bucket" {
  bucket = var.bucket_name

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
  bucket = aws_s3_bucket.secrets_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.secrets_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "enabled" {
  bucket = aws_s3_bucket.secrets_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}
