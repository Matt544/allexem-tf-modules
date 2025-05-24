variable "role_name" {
  type = string
}

variable "role_instance_profile_name" {
  type = string
}

variable "ecr_policy_name" {
  type = string
}

variable "s3_scripts_policy_name" {
  type = string
}
variable "s3_secrets_policy_name" {
  type = string
}

variable "allexem_security_group_id" {
  type = string
}

variable "elastic_ip" {
  type = string
}

variable "ami" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "instance_key_name" {
  type = string
}

variable "compose_base_path" {
  description = "Path to the base Docker Compose file"
  type        = string
}

variable "compose_extension_path" {
  description = "Path to the environment-specific Compose file (e.g. staging, prod)"
  type        = string
}

variable "env_base_path" {
  description = "Path to base environment file"
  type        = string
}

variable "env_main_path" {
  description = "Path to main environment file"
  type        = string
}

variable "env_proxy_path" {
  description = "Path to env file for proxy-companion"
  type        = string
}

variable "domain" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "staging_or_prod" {
  description = "The environment: either 'staging' or 'prod'."
  type        = string
}

variable "ecr_url" {
  description = "The URL of the repository (in the form aws_account_id.dkr.ecr.region.amazonaws.com/repositoryName)."
  type        = string
}
