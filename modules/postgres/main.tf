# This module provisions:
# - An AWS RDS PostgreSQL instance with customizable settings.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      # version = "~> 4.0"
    }
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  description = "Allow DB access from EC2"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.allexem_security_group_id]  # allow w/ security group vs. cidr block
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "postgres" {
  identifier_prefix            = var.identifier_prefix
  engine                       = var.engine
  engine_version               = var.engine_version
  allow_major_version_upgrade = true  # consider this
  instance_class               = var.instance_class
  allocated_storage            = var.allocated_storage
  max_allocated_storage        = var.max_allocated_storage
  storage_type                 = var.storage_type
  db_name                      = var.db_name
  username                     = var.username
  password                     = var.password
  port                         = var.port
  publicly_accessible          = var.publicly_accessible
  db_subnet_group_name         = var.db_subnet_group_name
  skip_final_snapshot          = true  # make a var?
  apply_immediately            = true  # ????
  backup_retention_period      = var.backup_retention_period
  backup_window                = var.backup_window
  maintenance_window           = var.maintenance_window
  performance_insights_enabled = var.performance_insights_enabled
  vpc_security_group_ids       = [aws_security_group.rds_sg.id]

  lifecycle {
    ignore_changes = [
      password,
      username,
      db_name
    ]
  }
}

# add prevent destroy?
