# Teardown
You want to delete any resources that were created during the demo so you don't incur additional charges. 

## Confluent Cloud 
1. Navigate to https://confluent.cloud
Use the left hand-side menu and click on **ksqlDB** and step into your **ksqlDB application**.

2. SET 'auto.offset.reset' = 'earliest';

3. Use the editor and run the following queries.
```SQL
drop table fd_possible_stolen_card;
drop stream fd_transactions_enriched;
drop stream fd_transactions;
drop table fd_customers;
drop stream fd_cust_raw_stream;
```
4. Use the left hand-side menue select **Data Integration** and then **Connectors**.

5. Click on each connector's name and delete them. 
> Alternatively, you can delete connectors through REST API calls. Refer to our [docs](https://docs.confluent.io/cloud/current/connectors/connect-api-section.html) for detailed instructions. 

6. Use the left hand-side menue select **Data Integration** and then **API Keys**.

7. Click on each key and hit **Delete API key**. 

8. Finally, delete the cluster and the environment. 

## AWS 
1. Navigate to https://aws.amazon.com/console/ and log into your account. 

2. Search for **RDS** and click on results. 

3. Use the left hand-side menu and click on **Databases → db-mod-demo → Actions → Delete** and proceed with deleting the database instance. 

## RabbitMQ
1. Navigate to https://customer.cloudamqp.com/user/settings
2. Click on **Delete Account**