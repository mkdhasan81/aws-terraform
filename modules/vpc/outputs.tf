output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.this.cidr_block
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = [for s in aws_subnet.private : s.id]
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = [for s in aws_subnet.public : s.id]
}

output "nat_gateway_id" {
  description = "ID of the NAT gateway"
  value       = aws_nat_gateway.this.id
}

output "default_security_group_id" {
  description = "ID of the default security group"
  value       = aws_security_group.default.id
}

output "public_nacl_id" {
  description = "ID of the public subnet NACL"
  value       = aws_network_acl.public.id
}

output "private_nacl_id" {
  description = "ID of the private subnet NACL"
  value       = aws_network_acl.private.id
}
