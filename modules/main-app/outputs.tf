output "rendered_user_data" {
  value = data.cloudinit_config.instance_cloudinit_config.rendered
}

output "subnet_cidr_blocks" {
  value = [for s in data.aws_subnet.default : s.cidr_block]
}
