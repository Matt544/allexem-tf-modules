# main-app S3 and DynamoDB Resources for Staging
# 
# This module provisions:
# - An S3 bucket for storing application data
# - Server-side encryption for the S3 bucket
# - A public access block for the S3 bucket
# - A DynamoDB table for managing S3 locks

# NOTE: For now, don't implement versioning? (consider if worthwhile for recovery of 
# users docx or my own templates?)


terraform {
  required_providers {  # TODO: assess this
    aws = {
      source  = "hashicorp/aws"
      # version = "~> 4.0"
    }
  }
}

# S3 Bucket for main application data
resource "aws_s3_bucket" "main_app_s3" {
  bucket = var.bucket_name

  lifecycle {
    prevent_destroy = true
  }
}

# S3 Bucket Encryption (AES256)
resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
  bucket = aws_s3_bucket.main_app_s3.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access to the S3 bucket
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.main_app_s3.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# DynamoDB table for S3 lock management
resource "aws_dynamodb_table" "staging_s3_locks" {
  name = var.lock_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "LockID"

  attribute {
    name = "LockID"
    type = "S"  # String type for LockID
  }
}
