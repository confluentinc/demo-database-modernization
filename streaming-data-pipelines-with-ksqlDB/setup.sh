#!/bin/bash

# Source the .env file
source .env
sleep_time=2

# Use confluent environment
confluent login --save
export CCLOUD_ENV_ID=$(confluent environment list -o json \
    | jq -r '.[] | select(.name | contains('\"${CCLOUD_ENV_NAME:-Demo_Database_Modernization}\"')) | .id')

confluent env use $CCLOUD_ENV_ID

# Use kafka cluster
export CCLOUD_CLUSTER_ID=$(confluent kafka cluster list -o json \
    | jq -r '.[] | select(.name | contains('\"${CCLOUD_CLUSTER_NAME:-demo_kafka_cluster}\"')) | .id')

confluent kafka cluster use $CCLOUD_CLUSTER_ID

# Get cluster bootstrap endpoint
export CCLOUD_BOOTSTRAP_ENDPOINT=$(confluent kafka cluster describe -o json | jq -r .endpoint)
STRIPPED_CCLOUD_BOOTSTRAP_ENDPOINT=$(echo $CCLOUD_BOOTSTRAP_ENDPOINT | sed 's/SASL_SSL:\/\///')

# use sed to replace kafka-cluster-endpoint with the replacement string
sed -i .bak "s/kafka-cluster-endpoint/$STRIPPED_CCLOUD_BOOTSTRAP_ENDPOINT/g" .env
sleep $sleep_time

# Create an API key pair to use for connectors
echo "Creating Kafka cluster API key"
CREDENTIALS=$(confluent api-key create --resource $CCLOUD_CLUSTER_ID --description "demo-database-modernization" -o json)
kafka_api_key=$(echo $CREDENTIALS | jq -r '.api_key')
kafka_api_secret=$(echo $CREDENTIALS | jq -r '.api_secret')

sleep $sleep_time

# use sed to replace all instances of $kafka_api_key with the replacement string
sed -i .bak "s^api-key^\"$kafka_api_key\"^g" .env 
sed -i .bak "s^api-secret^\"$kafka_api_secret\"^g" .env 

sleep $sleep_time

# Read values from resources.json and update the .env file.
# These resources are created by Terraform
json=$(cat resources.json)

oracle_endpoint=$(echo "$json" | jq -r '.oracle_endpoint.value.address')
cloudamqp_host=$(echo "$json" | jq -r '.cloudamqp_host.value')
cloudamqp_password=$(echo "$json" | jq -r '.cloudamqp_password.value')
cloudamqp_url=$(echo "$json" | jq -r '.cloudamqp_url.value')
cloudamqp_virtual_host=$(echo "$json" | jq -r '.cloudamqp_virtual_host.value')
mongodbatlas_connection_string=$(echo "$json" | jq -r '.mongodbatlas_connection_string.value'| sed 's/mongodb+srv:\/\///')

# Updating the .env file with sed command
sed -i .bak "s^oracle-endpoint^$oracle_endpoint^g" .env 
sed -i .bak "s^cloudamqp-host^$cloudamqp_host^g" .env 
sed -i .bak "s^cloudamqp-password^$cloudamqp_password^g" .env 
sed -i .bak "s^cloudamqp-url^$cloudamqp_url^g" .env 
sed -i .bak "s^cloudamqp-vhost^$cloudamqp_virtual_host^g" .env 
sed -i .bak "s^mongodb-endpoint^$mongodbatlas_connection_string^g" .env 
