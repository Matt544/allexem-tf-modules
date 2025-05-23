# Note: I jave opted not to use versioning for this bucket on the understanding that the
# script files will be in source control.

terraform {
  required_providers {  # TODO: assess this
    aws = {
      source  = "hashicorp/aws"
      # version = "~> 4.0"
    }
  }
}

resource "aws_s3_bucket" "scripts_bucket" {
  bucket = var.bucket_name

  lifecycle {
    # prevent_destroy = true
    prevent_destroy = false
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
  bucket = aws_s3_bucket.scripts_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.scripts_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Upload all script files from local "./scripts/" directory
resource "aws_s3_object" "scripts" {
  for_each = fileset("${path.module}/scripts", "**/*.sh")  # recursive 

  bucket = aws_s3_bucket.scripts_bucket.id
  key    = "scripts/${each.value}"
  source = "${path.module}/scripts/${each.value}"
  etag   = filemd5("${path.module}/scripts/${each.value}")  # updates replace old files (?)
}
