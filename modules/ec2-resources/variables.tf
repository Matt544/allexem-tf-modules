variable "subnet_id" {
  type        = string
  description = "The ID of the subnet to attach the network interface to."
}

variable "elastic_ip_name" {
  type        = string
  description = "Name tag for the elastic IP."
}

variable "ssh_ingress_prefix_list_ids" {
  type = list
}

variable "security_group_name_prefix" {
  type = string
}
