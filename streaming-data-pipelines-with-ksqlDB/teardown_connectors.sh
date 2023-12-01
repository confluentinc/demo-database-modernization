#!/bin/bash

# Source the .env file
source .env

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

# Get the ID for all connectors
oracle_id=$(confluent connect cluster list -o json | jq -r '.[] | select(.name | contains ("OracleCdcSourceConnector_0")) | .id')
rabbitmq_id=$(confluent connect cluster list -o json | jq -r '.[] | select(.name | contains ("RabbitMQSourceConnector_0")) | .id')
mongodb_id=$(confluent connect cluster list -o json | jq -r '.[] | select(.name | contains ("MongoDbAtlasSinkConnector_0")) | .id')

# Delete all connectors
echo "Deleting connectors..."
confluent connect cluster delete --force "$oracle_id"
confluent connect cluster delete --force "$rabbitmq_id"
confluent connect cluster delete --force "$mongodb_id"
