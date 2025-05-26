# Resources managed in this file:
# - IAM Role + Instance Profile (for EC2 access to ECR and S3)
# - IAM Policies and Attachments (ECR, S3 Scripts, S3 Secrets)
# - EC2 Security Group
# - Elastic IP Association (to manually created EIP)
# - EC2 Instance (staging app server)
# - Cloud-init config (writes compose files, .env files, and runs setup script)

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      # version = "~> 4.0"
    }
  }
}

# IAM role for EC2
resource "aws_iam_role" "allexem1_role_2" {
  name = var.role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach the role to an instance profile for EC2
# Note: I believe an instance profile is automatically created when you do this in the
# aws console.
resource "aws_iam_instance_profile" "allexem1_role_2_instance_profile" {
  name = var.role_instance_profile_name
  role = aws_iam_role.allexem1_role_2.name
}

# Policy to allow EC2 to pull from ECR
resource "aws_iam_policy" "ecr_pull_policy" {
  name        = var.ecr_policy_name
  description = "Allow EC2 to authenticate and pull images from ECR"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:DescribeRepositories",
          "ecr:ListImages"
        ]
        Resource = "*"  # TODO: narrow this? Note: Presently all resources are needed.
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_ecr_pull_policy" {
  role       = aws_iam_role.allexem1_role_2.name
  policy_arn = aws_iam_policy.ecr_pull_policy.arn
}

# Policy to allow read access to s3 scripts directory
resource "aws_iam_policy" "read_scripts_policy" {
  name        = var.s3_scripts_policy_name
  description = "Allow EC2 to read specific script files from the scripts bucket"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "s3:GetObject"
        Resource = [
          "arn:aws:s3:::allexem-${var.staging_or_prod}-tf-scripts",
          "arn:aws:s3:::allexem-${var.staging_or_prod}-tf-scripts/scripts/*",
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_read_scripts_policy" {
  role       = aws_iam_role.allexem1_role_2.name
  policy_arn = aws_iam_policy.read_scripts_policy.arn
}

# Policy to allow read access to s3 secrets directory
resource "aws_iam_policy" "read_secrets_policy" {
  name        = var.s3_secrets_policy_name
  description = "Allow EC2 to read specific script files from the secrets bucket"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
     {
        Effect = "Allow"
        Action = "s3:GetObject"
        Resource = "arn:aws:s3:::allexem-${var.staging_or_prod}-secrets/${var.staging_or_prod}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_read_secrets_policy" {
  role       = aws_iam_role.allexem1_role_2.name
  policy_arn = aws_iam_policy.read_secrets_policy.arn
}

# Cloud-init config: writes files to EC2 instance
locals {
  cloud_config = <<-EOF
    #cloud-config
    ${jsonencode({
      write_files = [
        {
          path        = "/home/ubuntu/compose.base.yaml"
          permissions = "0644"
          owner       = "root:root"  # Write as root first
          encoding    = "b64"  # base64 encoding for safe transfer? (GPT suggestion)
          content     = filebase64(var.compose_base_path)
        },
        {
          path        = "/home/ubuntu/compose.live.yaml"
          permissions = "0644"
          owner       = "root:root"
          encoding    = "b64"
          content     = filebase64(var.compose_extension_path)
        },
        {
          path        = "/home/ubuntu/.env.live.base"
          permissions = "0644"
          owner       = "root:root"
          encoding    = "b64"
          content     = filebase64(var.env_base_path)
        },
        {
          path        = "/home/ubuntu/.env.live.${var.staging_or_prod}"
          permissions = "0644"
          owner       = "root:root"
          encoding    = "b64"
          content     = filebase64(var.env_main_path)
        },
        {
          path        = "/home/ubuntu/.env.live.${var.staging_or_prod}.proxy-companion"
          permissions = "0644"
          owner       = "root:root"
          encoding    = "b64"
          content     = filebase64(var.env_proxy_path)
        }
      ]
    })}
  EOF
}

# bring in outside elastic IP resource
data "aws_eip" "existing_eip" {
  public_ip = var.elastic_ip
}

# Associate the existing Elastic IP with the instance
resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.allexem1.id
  allocation_id = data.aws_eip.existing_eip.id
}

# Get the default VPC subnets for outputs.tf and for user-data.sh
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

data "aws_subnet" "default" {
  for_each = toset(data.aws_subnets.default.ids)
  id       = each.value
}

# Get the default VPC to use its CIRD block for user-data.sh
data "aws_vpc" "default" {
  id = var.vpc_id
}

# Combine cloud-config and shell script into EC2 user_data
data "cloudinit_config" "instance_cloudinit_config" {
  gzip          = false
  base64_encode = false

  # Part 1: Cloud-init YAML for writing files
  part {
    content_type = "text/cloud-config"
    filename     = "cloud-config.yaml"
    content      = local.cloud_config
  }

  # Part 2: Shell script to run as user_data
  part {
    content_type = "text/x-shellscript"
    filename     = "bootstrap.sh"
    content      = templatefile(
      "${path.module}/user-data.sh", 
      {
        rds_elastic_net_ip     = data.aws_eip.existing_eip.public_ip
        aws_subnets            = join(" ", [for s in data.aws_subnet.default : s.cidr_block])
        vpc_cidr_block         = data.aws_vpc.default.cidr_block
        staging_or_prod        = var.staging_or_prod
        ecr_url                = var.ecr_url
        api_net_interface_name = "api-network-if"
        api_net_name           = "api-network"
      }
    )
  }
}

# EC2 instance
resource "aws_instance" "allexem1" {
  ami                    = var.ami
  instance_type          = var.instance_type
  key_name               = var.instance_key_name  # causes a deployment error if null
  vpc_security_group_ids = [var.allexem_security_group_id]

  # Attach IAM Role via Instance Profile
  iam_instance_profile   = aws_iam_instance_profile.allexem1_role_2_instance_profile.name

  user_data = data.cloudinit_config.instance_cloudinit_config.rendered
  user_data_replace_on_change = true  # TODO: assess this. Make an input parameter?
}

output "url" {
  value = "https://${var.domain}/"
}

output "public_url" {
  value = "http://${aws_instance.allexem1.public_ip}:8000"
}
