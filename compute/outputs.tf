output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.web_server.id
}

output "public_ip" {
  description = "Public IP address"
  value       = aws_eip.tailscale.public_ip
}

output "private_ip" {
  description = "Private IP address"
  value       = aws_instance.web_server.private_ip
}

output "ssh_command" {
  description = "SSH command"
  value       = "ssh -i ~/.ssh/web_key ubuntu@${aws_eip.tailscale.public_ip}"
}