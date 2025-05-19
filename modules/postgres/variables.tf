variable "identifier_prefix" {
  type = string
}

variable "engine" { 
  default = "postgres"
  type = string
}

variable "engine_version" { 
  default = "13.20"
  type = string
}

variable "instance_class" {
  type = string
}

variable "allocated_storage" {
    default = 20
    type = number
}

variable "max_allocated_storage" { 
  default = 100
  type = number
}

variable "storage_type" { 
  default = "gp2"
  type = string
}

variable "db_name" {
  type = string
}

variable "username" {
  type = string
}

variable "password" {
  type = string
}

variable "port" { 
  default = 5432
  type = number
}

variable "publicly_accessible" { 
  default = false
  type = bool
}

variable "db_subnet_group_name" {
  type = string
}

variable "backup_retention_period" { 
  default = 7
  type = number
}

variable "backup_window" { 
  default = "03:01-04:01"
  type = string
}

variable "maintenance_window" { 
  default = "Mon:00:00-Mon:03:00"
  type = string
}

variable "performance_insights_enabled" { 
  default = false
  type = bool
}

variable "allexem_security_group_id" {
  type = string
}

variable "vpc_id" {
  type = string
}
