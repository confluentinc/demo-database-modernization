# Demo

## Configure Oracle CDC Source Premium Connector
> Confluent offers 120+ pre-built [connectors](https://www.confluent.io/product/confluent-connectors/), enabling you to modernize your entire data architecture even faster. These connectors also provide you peace-of-mind with enterprise-grade security, reliability, compatibility, and support.
1. Log into Confluent Cloud by navigating to https://confluent.cloud
2. On the navigation menu, select **Data Integration** and then **Connectors** and **+ Add connector**.
3. In the search bar search for **Oracle** and select the **Oracle CDC Source Premium** which is a fully-managed connector. 
4. Use the following parameters to configure your connector
```
{
    "name": "OracleCdcSourceConnector_0",
    "config": {
      "connector.class": "OracleCdcSource",
      "name": "OracleCdcSourceConnector_0",
      "kafka.auth.mode": "KAFKA_API_KEY",
      "kafka.api.key": "<add_your_api_key>",
      "kafka.api.secret": "<add_your_api_secret_key>",
      "oracle.server": "db-mod-demo.***.us-west-2.rds.amazonaws.com",
      "oracle.port": "1521",
      "oracle.sid": "ORCL",
      "oracle.username": "DB_USER",
      "oracle.password": "<add_your_password>",
      "table.inclusion.regex": "ORCL[.]DB_USER[.]CUSTOMERS",
      "start.from": "snapshot",
      "query.timeout.ms": "60000",
      "redo.log.row.fetch.size": "1",
      "table.topic.name.template": "${databaseName}.${schemaName}.${tableName}",
      "lob.topic.name.template": "${databaseName}.${schemaName}.${tableName}.${columnName}",
      "enable.large.lob.object.support": "true",
      "numeric.mapping": "best_fit_or_double",
      "output.data.key.format": "JSON",
      "output.data.value.format": "JSON_SR",
      "transforms": "DoB_Mask",
      "transforms.DoB_Mask.type": "org.apache.kafka.connect.transforms.MaskField$Value",
      "transforms.DoB_Mask.fields": "DOB",
      "transforms.DoB_Mask.replacement": "<xxxx-xx-xx>",
      "tasks.max": "1"
    }
  }
```
Alternatively you can use Confluent Cloud CLI to start a new connector by running the following command
```confluent connect create --config oracle_cdc.json```

> In this demo, we are using Apache Kafka's Single Message Transforms (SMT) to mask customer PII field before data streams into Confluent Cloud. For more information on SMTs refer to our [documentation](https://docs.confluent.io/cloud/current/connectors/single-message-transforms.html)

5. Once the connector is in **Running** state verify the messages exist in **ORCL.DB_USER.CUSTOMERS** topic. 

## Configure RabbitMQ Source Connector 
1. On the navigation menu, select **Data Integration** and then **Connectors** and **+ Add connector**.
2. In the search bar search for **RabbitMQ** and select the **RabbitMQ Source** which is a fully-managed connector. 
3. Use the following parameters to configure your connector
```
{
  "name": "RabbitMQSourceConnector_0",
  "config": {
    "connector.class": "RabbitMQSource",
    "name": "RabbitMQSourceConnector_0",
    "kafka.auth.mode": "KAFKA_API_KEY",
    "kafka.api.key": "<add_your_api_key>",
    "kafka.api.secret": "<add_your_api_secret_key>",
    "kafka.topic": "rabbitmq_transactions",
    "rabbitmq.host": "<add_rabbitmq_host>",
    "rabbitmq.username": "<add_rabbitmq_username>",
    "rabbitmq.password": "<add_rabbitmq_password>",
    "rabbitmq.virtual.host": "<add_rabbitmq_virtual_host>",
    "rabbitmq.queue": "txs",
    "tasks.max": "1"
  }
}
```
Alternatively you can use Confluent Cloud CLI to start a new connector by running the following command
```confluent connect create --config rabbitmq.json```
> Refer to our [documentation](https://docs.confluent.io/cloud/current/connectors/cc-rabbitmq-source.html) for detailed instructions.
4. Once the connector is in **Running** state verify the messages exist in **rabbitmq_transactions** topic.

## Enrich data streams with ksqlDB
> Now that you have data flowing through Confluent, you can now easily build stream processing applications using ksqlDB. You are able to continuously transform, enrich, join, and aggregate your data using simple SQL syntax. You can gain value from your data directly from Confluent in real-time. Also, ksqlDB is a fully managed service within Confluent Cloud with a 99.9% uptime SLA. You can now focus on developing services and building your data pipeline while letting Confluent manage your resources for you.
> With ksqlDB, you have the ability to leverage streams and tables from your topics in Confluent. A stream in ksqlDB is a topic with a schema and it records the history of what has happened in the world as a sequence of events.
1. On the navigation menu click on **ksqlDB** and step into the cluster you created during setup.
> You can interact with ksqlDB through the Editor. You can create a stream by using the CREATE STREAM statement and a table using the CREATE TABLE statement. If you’re interested in learning more about ksqlDB and the differences between streams and tables, I recommend reading these two blogs [here](https://www.confluent.io/blog/kafka-streams-tables-part-3-event-processing-fundamentals/) and [here](https://www.confluent.io/blog/how-real-time-stream-processing-works-with-ksqldb/) or watch ksqlDB 101 course on Confluent Developer [webiste](https://developer.confluent.io/learn-kafka/ksqldb/intro/). 

To write streaming queries against topics, you will need to register the topics with ksqlDB as a stream and/or table.

2. SET 'auto.offset.reset' = 'earliest';

3. Create a ksqlDB stream from `ORCL.DB_USER.CUSTOMERS` topic.
```SQL
CREATE STREAM fd_cust_raw_stream WITH (KAFKA_TOPIC = 'ORCL.DB_USER.CUSTOMERS',VALUE_FORMAT = 'JSON_SR');
```

4. Use the following statement to query `fd_cust_raw_stream` stream to ensure it's being populated correctly.
```SQL
SELECT * FROM fd_cust_raw_stream EMIT CHANGES;
```

5. Stop the running query by clicking on **Stop**.

6. Create `fd_customers` table based on the `fd_cust_raw_stream` stream you just created. 
```SQL
CREATE TABLE fd_customers WITH (FORMAT='JSON_SR') AS 
    SELECT id                            AS customer_id,
           LATEST_BY_OFFSET(first_name)  AS first_name,
           LATEST_BY_OFFSET(last_name)   AS last_name,
           LATEST_BY_OFFSET(dob)         AS dob,
           LATEST_BY_OFFSET(email)       AS email,
           LATEST_BY_OFFSET(avg_credit_spend) AS avg_credit_spend
    FROM    fd_cust_raw_stream 
    GROUP BY id;
```

7. Use the following statement to query `fd_customers` table to ensure it's being populated correctly.
```SQL
SELECT * FROM fd_customers;
```

8. Create the stream of transactions from `rabbitmq_transactions` topic.
```SQL
CREATE STREAM fd_transactions(
	userid DOUBLE,
  	transaction_timestamp VARCHAR,
  	amount DOUBLE,
  	ip_address VARCHAR,
  	transaction_id INTEGER,
  	credit_card_number VARCHAR
	)
WITH(KAFKA_TOPIC='rabbitmq_transactions', KEY_FORMAT='JSON', VALUE_FORMAT='JSON', timestamp ='transaction_timestamp', timestamp_format = 'yyyy-MM-dd HH:mm:ss');
```
9. Use the following statement to query `fd_transactions` stream to ensure it's being populated correctly.
```SQL
SELECT * FROM fd_transactions EMIT CHANGES;
```

10. Stop the running query by clicking on **Stop**.

11. Join the transactions streams to customer information table.
```SQL
CREATE STREAM fd_transactions_enriched WITH (KAFKA_TOPIC = 'transactions_enriched') AS
  SELECT
    T.USERID,
    T.CREDIT_CARD_NUMBER,
    T.AMOUNT,
    T.TRANSACTION_TIMESTAMP,
    C.FIRST_NAME + ' ' + C.LAST_NAME AS FULL_NAME,
    C.AVG_CREDIT_SPEND,
    C.EMAIL
  FROM fd_transactions T
  INNER JOIN fd_customers C
  ON T.USERID = C.CUSTOMER_ID;
```

12. Use the following statement to query `fd_transactions_enriched` stream to ensure it's being populated correctly.
```SQL
SELECT * FROM fd_transactions_enriched EMIT CHANGES;
```

13. Stop the running query by clicking on **Stop**.

14. Aggregate the stream of transactions for each account ID using a two-hour tumbling window, and filter for accounts in which the total spend in a two-hour period is greater than the customer’s average.
```SQL
CREATE TABLE fd_possible_stolen_card WITH (KAFKA_TOPIC = 'FD_possible_stolen_card', KEY_FORMAT = 'JSON', VALUE_FORMAT='JSON') AS
  SELECT
    TIMESTAMPTOSTRING(WINDOWSTART, 'yyyy-MM-dd HH:mm:ss') AS WINDOW_START,
    T.USERID,
    T.CREDIT_CARD_NUMBER,
    T.FULL_NAME,
    T.EMAIL,
    T.TRANSACTION_TIMESTAMP,
    SUM(T.AMOUNT) AS TOTAL_CREDIT_SPEND,
    MAX(T.AVG_CREDIT_SPEND) AS AVG_CREDIT_SPEND
  FROM fd_transactions_enriched T
  WINDOW TUMBLING (SIZE 2 HOURS)
  GROUP BY T.USERID, T.CREDIT_CARD_NUMBER, T.FULL_NAME, T.EMAIL, T.TRANSACTION_TIMESTAMP
  HAVING SUM(T.AMOUNT) > MAX(T.AVG_CREDIT_SPEND);
```
15. Use the following statement to query `fd_possible_stolen_card` table to ensure it's being populated correctly.
```SQL
SELECT * FROM fd_possible_stolen_card;
```

## Connect MongoDB Atlas to Confluent Cloud
1. On the navigation menu, select **Data Integration** and then **Connectors** and **+ Add connector**.
2. In the search bar search for **MongoDB** and select the **MongoDB Atlas Sink** which is a fully-managed connector. 
3. Use the following parameters to configure your connector
```
{
  "name": "MongoDbAtlasSinkConnector_0",
  "config": {
    "connector.class": "MongoDbAtlasSink",
    "name": "MongoDbAtlasSinkConnector_0",
    "input.data.format": "JSON",
    "kafka.auth.mode": "KAFKA_API_KEY",
    "kafka.api.key": "<add_your_api_key>",
    "kafka.api.secret": "<add_your_api_secret_key>",
    "topics": "FD_possible_stolen_card",
    "connection.host": "<database-host-address>",
    "connection.user": "<add_MongoDB_username>",
    "connection.password": "<add_MongoDB_password>",
    "database": "<database-name>",
    "doc.id.strategy": "FullKeyStrategy",
    "tasks.max": "1"
  }
}
```
Alternatively you can use Confluent Cloud CLI to start a new connector by running the following command
```confluent connect create --config mongodb_sink.json```
> Refer to our [documentation](https://docs.confluent.io/cloud/current/connectors/cc-mongo-db-sink.html) for detailed instructions. 

4. Once the connector is in **Running** state navigate to **cloud.mongodb.com → Collections → <DATABASE_NAME>_FD_possible_stolen_card** and verify messages are showing up correctly. 

## Confluent Cloud Stream Lineage 
Confluent gives you tools such as Stream Quality, Stream Catalog, and Stream Lineage to ensure your data is high quality, observable and discoverable. Learn more about the **Stream Governance** [here](https://www.confluent.io/product/stream-governance/) and refer to the [docs](https://docs.confluent.io/cloud/current/stream-governance/overview.html) page for detailed information. 
1. Navigate to https://confluent.cloud
2. Use the left hand-side menu and click on **Stream Lineage**. 
Stream lineage provides a graphical UI of the end to end flow of your data. Both from the a bird’s eye view and drill-down magnification for answering questions like:
    * Where did data come from?
    * Where is it going?
    * Where, when, and how was it transformed?
In the bird's eye view you see how one stream feeds into another one. As your pipeline grows and becomes more complex, you can use Stream lineage to debug and see where things go wrong and break.
<div align="center" padding=25px>
   <img src="stream-lineage.png" width =75% heigth=75%>
</div>