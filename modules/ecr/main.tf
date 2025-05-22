terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      # version = "~> 4.0"
    }
  }
}

resource "aws_ecr_repository" "ecr" {
  name                 = var.repository_name
  image_tag_mutability = "MUTABLE"
  
  image_scanning_configuration {
    scan_on_push = true
  }
  encryption_configuration {
    encryption_type = "AES256"
  }
}
