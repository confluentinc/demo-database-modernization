#! /bin/bash

echo "generating connector configuration json files from .env"
echo

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source ${DIR}/../.env

for i in example_mongodb_sink.json example_oracle_cdc.json example_rabbitmq.json; do
    sed -e "s|<add_your_api_key>|${CCLOUD_API_KEY}|g" \
    -e "s|<add_your_api_secret_key>|${CCLOUD_API_SECRET}|g" \
    -e "s|<add_mongo_host_address>|${MONGO_ENDPOINT}|g" \
    -e "s|<mongo_host_address>|${MONGO_ENDPOINT}|g" \
    -e "s|<add_mongo_username>|${MONGO_USERNAME}|g" \
    -e "s|<add_mongo_password>|${MONGO_PASSWORD}|g" \
    -e "s|<add_mongo_database_name>|${MONGO_DATABASE_NAME}|g" \
    -e "s|<add_your_rds_endpoint>|${ORACLE_ENDPOINT}|g" \
    -e "s|<add_rabbitmq_host>|${CLOUDAMQP_ENDPOINT}|g" \
    -e "s|<add_rabbitmq_username>|${CLOUDAMQP_VIRTUAL_HOST}|g" \
    -e "s|<add_rabbitmq_password>|${CLOUDAMQP_PASSWORD}|g" \
    -e "s|<add_rabbitmq_virtual_host>|${CLOUDAMQP_VIRTUAL_HOST}|g" \
    ${DIR}/$i > ${DIR}/actual_${i#example_}
done