output "instance_id" {
  value = aws_instance.kernel_dev.id
}

output "public_ip" {
  value = aws_instance.kernel_dev.public_ip
}
