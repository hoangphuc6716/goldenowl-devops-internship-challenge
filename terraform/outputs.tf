output "ec2_public_ip" {
  value       = aws_instance.app.public_ip
}

output "app_url" {
  description = "Deployment link"
  value       = "http://${aws_instance.app.public_ip}:3000"
}
