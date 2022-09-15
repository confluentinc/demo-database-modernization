#! /bin/bash

confluent login --save

for i in actual_mongodb_sink.json actual_oracle_cdc.json actual_rabbitmq.json; do
    confluent connect create --config $i
done