#======================================================
#OUTPUTS JENKINS PUBLIC IP ADDRESS
#======================================================
output "jenkins_instance_public_ip" {
  description = "public ip for the jenkins instance"
  value       = aws_instance.jenkins_instance.public_ip
}