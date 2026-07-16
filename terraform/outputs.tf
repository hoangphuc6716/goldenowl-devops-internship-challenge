output "ec2_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.app.public_ip
}

output "app_url" {
  description = "Deployment link"
  value       = "http://${aws_instance.app.public_ip}:3000"
}
