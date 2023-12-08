terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.16.2"
    }
    confluent = {
      source  = "confluentinc/confluent"
      version = "1.55.0"
    }
    mongodbatlas = {
      source  = "mongodb/mongodbatlas"
      version = "1.12.1"
    }
  }
}

provider "confluent" {
  cloud_api_key    = var.confluent_cloud_api_key
  cloud_api_secret = var.confluent_cloud_api_secret
}

provider "confluent" {
  # https://developer.hashicorp.com/terraform/language/providers/configuration#alias-multiple-provider-configurations
  alias = "kafka"

  cloud_api_key    = var.confluent_cloud_api_key
  cloud_api_secret = var.confluent_cloud_api_secret

  #   kafka_id            = confluent_kafka_cluster.basic.id
  kafka_rest_endpoint = confluent_kafka_cluster.basic.rest_endpoint
  kafka_api_key       = confluent_api_key.app-manager-kafka-api-key.id
  kafka_api_secret    = confluent_api_key.app-manager-kafka-api-key.secret
}

provider "aws" {
  region = var.region
}

# Configure the MongoDB Atlas Provider 
provider "mongodbatlas" {
  public_key  = var.mongodbatlas_public_key
  private_key = var.mongodbatlas_private_key
}

resource "confluent_environment" "demo" {
  display_name = "Demo_Database_Modernization"
}

data "confluent_schema_registry_region" "sg_package" {
  cloud   = "AWS"
  region  = var.region
  package = var.sg_package
}

resource "confluent_schema_registry_cluster" "sr_package" {
  package = data.confluent_schema_registry_region.sg_package.package

  environment {
    id = confluent_environment.demo.id
  }

  region {
    # See https://docs.confluent.io/cloud/current/stream-governance/packages.html#stream-governance-regions
    id = data.confluent_schema_registry_region.sg_package.id
  }
}

resource "confluent_kafka_cluster" "basic" {
  display_name = "demo_kafka_cluster"
  availability = "SINGLE_ZONE"
  cloud        = "AWS"
  region       = var.region
  basic {}

  environment {
    id = confluent_environment.demo.id
  }
}

# 'app-manager' service account is required in this configuration to create 'rabbitmq_transactions' topic and grant ACLs
# to 'app-producer' and 'app-consumer' service accounts.
resource "confluent_service_account" "app-manager" {
  display_name = "app-manager"
  description  = "Service account to manage 'demo' Kafka cluster"
}

resource "confluent_role_binding" "app-manager-kafka-cluster-admin" {
  principal   = "User:${confluent_service_account.app-manager.id}"
  role_name   = "CloudClusterAdmin"
  crn_pattern = confluent_kafka_cluster.basic.rbac_crn
}

resource "confluent_api_key" "app-manager-kafka-api-key" {
  display_name = "app-manager-kafka-api-key"
  description  = "Kafka API Key that is owned by 'app-manager' service account"
  owner {
    id          = confluent_service_account.app-manager.id
    api_version = confluent_service_account.app-manager.api_version
    kind        = confluent_service_account.app-manager.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.basic.id
    api_version = confluent_kafka_cluster.basic.api_version
    kind        = confluent_kafka_cluster.basic.kind

    environment {
      id = confluent_environment.demo.id
    }
  }

  # The goal is to ensure that confluent_role_binding.app-manager-kafka-cluster-admin is created before
  # confluent_api_key.app-manager-kafka-api-key is used to create instances of
  # confluent_kafka_topic, confluent_kafka_acl resources.

  # 'depends_on' meta-argument is specified in confluent_api_key.app-manager-kafka-api-key to avoid having
  # multiple copies of this definition in the configuration which would happen if we specify it in
  # confluent_kafka_topic, confluent_kafka_acl resources instead.
  depends_on = [
    confluent_role_binding.app-manager-kafka-cluster-admin
  ]
}

# Create Oracle redo log topic 
resource "confluent_kafka_topic" "oracle_redo_log" {
  kafka_cluster {
    id = confluent_kafka_cluster.basic.id
  }

  topic_name       = "OracleCdcSourceConnector-dbmod-redo-log"
  rest_endpoint    = confluent_kafka_cluster.basic.rest_endpoint
  partitions_count = 1
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}

# Create credit card transactions topic 
resource "confluent_kafka_topic" "credit_card_transactions" {
  kafka_cluster {
    id = confluent_kafka_cluster.basic.id
  }

  topic_name       = "credit_card_transactions"
  rest_endpoint    = confluent_kafka_cluster.basic.rest_endpoint
  partitions_count = 1
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}

resource "confluent_flink_compute_pool" "demo-flink" {
  display_name = "demo-flink"
  cloud        = "AWS"
  region       = var.region
  max_cfu      = 5
  environment {
    id = confluent_environment.demo.id
  }
}

#####################################
# ### Amazon RDS (Oracle)
#####################################

# AWS Availability Zones data
data "aws_availability_zones" "available" {}

# Create the VPC
resource "aws_vpc" "rds-vpc" {
  cidr_block           = var.rds_vpc_cidr
  enable_dns_hostnames = true

  tags = {
    Name       = "demo-db-mod-rds-vpc"
    created_by = "terraform"
  }
}

# Create the RDS Oracle Subnet AZ1
resource "aws_subnet" "rds-subnet-az1" {
  vpc_id            = aws_vpc.rds-vpc.id
  cidr_block        = var.rds_subnet_1_cidr
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name       = "demo-db-mod-rds-subnet-az1"
    created_by = "terraform"
  }
}

# Create the RDS Oracle Subnet AZ2
resource "aws_subnet" "rds-subnet-az2" {
  vpc_id            = aws_vpc.rds-vpc.id
  cidr_block        = var.rds_subnet_2_cidr
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name       = "demo-db-mod-rds-subnet-az2"
    created_by = "terraform"
  }
}

# Create the RDS Oracle Subnet Group
resource "aws_db_subnet_group" "rds-subnet-group" {
  depends_on = [
    aws_subnet.rds-subnet-az1,
    aws_subnet.rds-subnet-az2,
  ]

  name       = "demo-db-mod-rds-subnet-group"
  subnet_ids = [aws_subnet.rds-subnet-az1.id, aws_subnet.rds-subnet-az2.id]

  tags = {
    Name       = "demo-db-mod-rds-subnet-group"
    created_by = "terraform"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "rds-igw" {
  vpc_id = aws_vpc.rds-vpc.id

  tags = {
    Name       = "demo-db-mod-rds-igw"
    created_by = "terraform"
  }
}

# Define the RDS Oracle route table to Internet Gateway
resource "aws_route_table" "rds-rt-igw" {
  vpc_id = aws_vpc.rds-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.rds-igw.id
  }

  tags = {
    Name       = "demo-db-mod-rds-public-route-igw"
    created_by = "terraform"
  }
}

# Assign the Oracle RDS route table to the RDS Subnet az1 for IGW 
resource "aws_route_table_association" "rds-subnet-rt-association-igw-az1" {
  subnet_id      = aws_subnet.rds-subnet-az1.id
  route_table_id = aws_route_table.rds-rt-igw.id
}

# Assign the public route table to the RDS Subnet az2 for IGW 
resource "aws_route_table_association" "rds-subnet-rt-association-igw-az2" {
  subnet_id      = aws_subnet.rds-subnet-az2.id
  route_table_id = aws_route_table.rds-rt-igw.id
}

resource "aws_security_group" "rds_security_group" {
  name        = "demo_db_mod_rds_security_group_${split("-", uuid())[0]}"
  description = "Security Group for RDS Oracle instance. Used in Confluent Cloud Database Modernization workshop."
  vpc_id      = aws_vpc.rds-vpc.id

  ingress {
    description = "RDS Oracle Port"
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Allow all outbound."
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name       = "demo-db-mod-rds-security-group"
    created_by = "terraform"
  }
}

resource "aws_db_instance" "demo-db-mod" {
  identifier             = var.rds_instance_identifier
  engine                 = "oracle-se2"
  engine_version         = "19"
  instance_class         = var.rds_instance_class
  username               = var.rds_username
  password               = var.rds_password
  port                   = 1521
  license_model          = "license-included"
  db_subnet_group_name   = aws_db_subnet_group.rds-subnet-group.name
  vpc_security_group_ids = [aws_security_group.rds_security_group.id]
  #   parameter_group_name = "default.oracle-se2-19.0"
  allocated_storage   = 20
  storage_encrypted   = false
  skip_final_snapshot = true
  publicly_accessible = true
  tags = {
    name       = "demo-db-mod"
    created_by = "terraform"
  }
}

# Create a Project
resource "mongodbatlas_project" "atlas-project" {
  org_id = var.mongodbatlas_org_id
  name   = var.mongodbatlas_project_name
}

# Create MongoDB Atlas resources
resource "mongodbatlas_cluster" "demo-database-modernization" {
  project_id = mongodbatlas_project.atlas-project.id
  name       = "demo-db-mod"

  # Provider Settings "block"
  provider_instance_size_name = "M0"
  provider_name               = "TENANT"
  backing_provider_name       = "AWS"
  provider_region_name        = var.mongodbatlas_region
}

resource "mongodbatlas_project_ip_access_list" "demo-database-modernization-ip" {
  project_id = mongodbatlas_project.atlas-project.id
  cidr_block = "0.0.0.0/0"
  comment    = "Allow connections from anywhere for demo purposes"
}

# Create a MongoDB Atlas Admin Database User
resource "mongodbatlas_database_user" "demo-database-modernization-db-user" {
  username           = var.mongodbatlas_database_username
  password           = var.mongodbatlas_database_password
  project_id         = mongodbatlas_project.atlas-project.id
  auth_database_name = "admin"

  roles {
    role_name     = "readWrite"
    database_name = mongodbatlas_cluster.demo-database-modernization.name
  }
}
