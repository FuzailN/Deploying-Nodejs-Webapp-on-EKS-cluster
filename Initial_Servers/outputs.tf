output "jenkins_public_ip_address" {
  value       = aws_instance.jenkins.public_ip
  description = "The public IP address of the jenkins server."
}

output "nexus_public_ip_address" {
  value       = aws_instance.nexus.public_ip
  description = "The public IP address of the nexus server."
}

output "nginx_public_ip_address" {
  value       = aws_instance.nginx.public_ip
  description = "The public IP address of the nginx server."
}