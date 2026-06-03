output "ec2_public_ip" {
  value = aws_instance.web_server.public_ip
}

output "rds_endpoint" {
  value = aws_db_instance.mysql_db.endpoint
}

output "ec2_instance_id" {
  value = aws_instance.web_server.id
}

output "rds_identifier" {
  value = aws_db_instance.mysql_db.identifier
}