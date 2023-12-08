variable "confluent_cloud_api_key" {
  description = "Confluent Cloud API Key (also referred as Cloud API ID)"
  type        = string
}

variable "confluent_cloud_api_secret" {
  description = "Confluent Cloud API Secret"
  type        = string
  sensitive   = true
}

variable "sg_package" {
  description = "Stream Governance Package: Advanced or Essentials"
  type        = string
  default     = "ADVANCED"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "rds_instance_class" {
  description = "Amazon RDS (Oracle) instance size"
  type        = string
  default     = "db.m5.large"
}

variable "rds_instance_identifier" {
  description = "Amazon RDS (Oracle) instance identifier"
  type        = string
  default     = "demo-db-mod"
}

variable "rds_username" {
  description = "Amazon RDS (Oracle) master username"
  type        = string
  default     = "admin"
}

variable "rds_password" {
  description = "Amazon RDS (Oracle) database password. You can change it through command line"
  type        = string
  default     = "db-mod-c0nflu3nt!"
}

variable "rds_vpc_cidr" {
  type        = string
  description = "VPC IPv4 CIDR"
  default     = "10.0.0.0/16"
}

variable "rds_subnet_1_cidr" {
  type        = string
  description = "IPv4 CIDR for RDS Oracle subnet 1"
  default     = "10.0.1.0/24"
}

variable "rds_subnet_2_cidr" {
  type        = string
  description = "IPv4 CIDR for  RDS Oracle subnet 2"
  default     = "10.0.2.0/24"
}

variable "mongodbatlas_public_key" {
  description = "The public API key for MongoDB Atlas"
  type        = string
}

variable "mongodbatlas_private_key" {
  description = "The private API key for MongoDB Atlas"
  type        = string
}

# Atlas Organization ID 
variable "mongodbatlas_org_id" {
  type        = string
  description = "MongoDB Atlas Organization ID"
}

# Atlas Project Name
variable "mongodbatlas_project_name" {
  type        = string
  description = "MongoDB Atlas Project Name"
  default     = "demo-database-mod"
}

variable "mongodbatlas_region" {
  description = "MongoDB Atlas region https://www.mongodb.com/docs/atlas/reference/amazon-aws/#std-label-amazon-aws"
  type        = string
  default     = "US_EAST_1"
}

variable "mongodbatlas_database_username" {
  description = "MongoDB Atlas database username. You can change it through command line"
  type        = string
  default     = "admin"
}

variable "mongodbatlas_database_password" {
  description = "MongoDB Atlas database password. You can change it through command line"
  type        = string
  default     = "db-mod-c0nflu3nt!"
}
