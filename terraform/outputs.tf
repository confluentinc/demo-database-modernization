output "oracle_endpoint" {
  value = aws_db_instance.db-mod-demo
  sensitive = true
}

output "cloudamqp_virtual_host" {
  description = "RabbitMQ virtual host name to be used in Confluent Cloud connector"
  value       = cloudamqp_instance.instance.vhost
}

output "cloudamqp_username" {
  description = "RabbitMQ username to be used in Confluent Cloud connector"
  value       = cloudamqp_instance.instance.vhost
}
output "cloudamqp_url" {
  description = "RabbitMQ URL to be used in Confluent Cloud connector"
  value       = cloudamqp_instance.instance.url
  sensitive   = true
}

output "cloudamqp_password" {
  description = "RabbitMQ password to be used in Confluent Cloud connector"
  value       = data.cloudamqp_credentials.credentials.password
  sensitive   = true
}

output "cloudamqp_host" {
  description = "RabbitMQ host to be used in Confluent Cloud connector"
  value       = cloudamqp_instance.instance.host
}

output "mongodbatlas_connection_string" {
  description = "Connection string for MongoDB Atlas database to be used in Confluent Cloud connector"
  value       = mongodbatlas_cluster.demo-database-modernization.connection_strings[0].standard_srv
}