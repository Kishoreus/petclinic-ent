output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "all_subnet_ids" {
  value = concat(aws_subnet.public[*].id, aws_subnet.private[*].id)
}

output "eice_security_group_id" {
  value = aws_security_group.eice.id
}

output "eice_id" {
  value = aws_ec2_instance_connect_endpoint.eks.id
}
