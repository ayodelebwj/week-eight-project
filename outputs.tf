output "vpc" {
  value = aws_vpc.techbleatvpc.id
}

output "publicsubnet2" {
  value = aws_subnet.public_2.id
}

output "privatesubnet2" {
  value = aws_subnet.private_2.id
}

output "privatesubnet1" {
  value = aws_subnet.private_1.id
}

output "publicsubnet1" {
  value = aws_subnet.public_1.id
}

output "internetgateway" {
  value = aws_internet_gateway.igw.id
}


output "publicsubnetroutetableid" {
  value = aws_route_table.public.id
}

output "privatesubnetroutetableid" {
  value = aws_route_table.private.id
}

output "bastionhostpublicip" {
  value = aws_instance.bastion.public_ip
}

output "privatehostprivateip" {
  value = aws_instance.private_host.private_ip
}