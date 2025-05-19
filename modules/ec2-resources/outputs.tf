output "eip_allocation_id" {
  value = aws_eip.main_eip.id
}

output "eip_public_ip" {
  value = aws_eip.main_eip.public_ip
}

output "vpc_id" {
  value = data.aws_subnet.current.vpc_id
}

output "allexem_security_group_id" {
  value = aws_security_group.allexem1.id
}
