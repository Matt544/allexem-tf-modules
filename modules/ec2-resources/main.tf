# This module provisions:
# - An Elastic Network Interface (ENI) attached to a specified subnet and security group
# - An Elastic IP address associated with the ENI


terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      # version = "~> 4.0"
    }
  }
}

# Bring in the subnet to get its vpc_id as an output in outputs.tf
data "aws_subnet" "current" {
  id = var.subnet_id
}

# Elastic IP
resource "aws_eip" "main_eip" {
  domain            = "vpc"

  tags = {
    Name = var.elastic_ip_name
  }
}

# Security group for EC2 instance
# Note: I create this here instead of in main-app because both main-app and RDS are 
# dependent on this security group and I don't want to be able to start RDS before EC2,
# so that it's available to EC2.
resource "aws_security_group" "allexem1" {  # TODO: change name / move to independent resources
  name_prefix = var.security_group_name_prefix

  ingress {  # For Let's Encrypt
    description = "for Lets Encrypt, HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {  # For Let's Encrypt
    description = "for Lets Encrypt, HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Note: The prefix list is used in lieu of CIDR blocks to allow ssh into the instance 
  # via the aws console's "connect" button. 
  # For some context and possible altrnative approach, see this SO post: 
  # https://stackoverflow.com/questions/79560458/how-do-you-allow-the-amazon-ec2-console-to-connect-to-an-instance-with-terrafor/79560459#79560459
  # Note: Reviewing the docs it wasn't quickly clear to me how to implement the 
  # commentor's alternative suggestions and I decided not to proceed with it, for now.
  ingress {
    description = "for SSH via EC2 Connect (AWS Console)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    prefix_list_ids = var.ssh_ingress_prefix_list_ids
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
