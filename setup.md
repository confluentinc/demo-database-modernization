# Setup

## Set up Confluent Cloud
1. Sign up for a Confluent Cloud account [here](https://www.confluent.io/get-started/).
2. After verifying your email address, access Confluent Cloud sign-in by navigating [here](https://confluent.cloud).
3. When provided with the *username* and *password* prompts, fill in your credentials.
    > **Note:** If you're logging in for the first time you will see a wizard that will walk you through the some tutorials. Minimize this as you will walk through these steps in this guide.

4. Click **+ Add environment**.
    > **Note:** There is a *default* environment ready in your account upon account creation. You can use this *default* environment for the purpose of this demo if you do not wish to create an additional environment.

    * Specify a meaningful `name` for your environment and then click **Create**.
        > **Note:** It will take a few minutes to assign the resources to make this new environment available for use.

5. Now that you have an environment, let's create a cluster. Select **Create Cluster**.
    > **Note**: Confluent Cloud clusters are available in 3 types: **Basic**, **Standard**, and **Dedicated**. Basic is intended for development use cases so you should use that for this demo. Basic clusters only support single zone availability. Standard and Dedicated clusters are intended for production use and support Multi-zone deployments. If you’re interested in learning more about the different types of clusters and their associated features and limits, refer to this [documentation](https://docs.confluent.io/current/cloud/clusters/cluster-types.html).

    * Choose the **Basic** cluster type.

    * Click **Begin Configuration**.

    * Choose **AWS** as your Cloud Provider and your preferred Region. In this demo we use Oregon (West2) as the region. 

    * Specify a meaningful **Cluster Name** and then review the associated *Configuration & Cost*, *Usage Limits*, and *Uptime SLA* before clicking **Launch Cluster**.

### Create an API key pair

1. Select API keys on the navigation menu.
1. If this is your first API key within your cluster, click **Create key**. If you have set up API keys in your cluster in the past and already have an existing API key, click **+ Add key**.
1. Select **Global Access**, then click Next.
1. Save your API key and secret - you will need these during the demo.
1. After creating and saving the API key, you will see this API key in the Confluent Cloud UI in the API keys tab. If you don’t see the API key populate right away, refresh the browser.

### Enable Schema Registery
1. On the navigation menu, select **Schema Registery**.
1. Click **Set up on my own**.
1. Choose **AWS** as the cloud provider and a supported **Region**
1. Click on **Enable Schema Registry**. 

## Create RabbitMQ topic
1. Navigate to confluent.cloud
2. On the navigation menu, select **Topics** and then **+Add topic** create a new topic with following configurations
```
Topic name: rabbitmq_transactions
Partitions: 1
```

## Create ksqlDB cluster 
> At Confluent we developed ksqlDB, the database purpose-built for stream processing applications. ksqlDB is built on top of Kafka Streams, powerful Java library for enriching, transforming, and processing real-time streams of data. Having Kafka Streams at its core means ksqlDB is built on well-designed and easily understood layers of abstractions. So now, beginners and experts alike can easily unlock and fully leverage the power of Kafka in a fun and accessible way.
1. On the navigation menu, select **ksqlDB**.
1. Click on **Create cluster myself**.
1. Choose **Global access** for the access level and hit **Continue**.
1. Pick a name or leave the name as is.
1. Select **1** as the cluster size. 
1. Hit **Launch Cluster!**. 

## Create an Oracle DB instance
This demo uses AWS RDS Oracle that is publicly accessible. 
1. Navigate to https://aws.amazon.com/console/ and log into your account. 
2. Search for **RDS** and click on results. 
3. Click on **Create database** and create an Oracle database using the following configurations and leave everything else as default. 
```
Creation method: Standard create
Engine type: Oracle
Database management type: Amazon RDS
Edition: Oracle Standard Editon Two
License: License-included
Version: 19.0.0.0.ru-2021-10.rur-2021-10.r1
Templates: Dev/Test
DB instance identifier: db-mod-demo
Master username: admin
Auto generate a password: check the box
Public access: Yes
```
4. If you opted in using an auto-generated password, ensure you click on **View credentials details** while the instance is being created to download your password. 

## Connect to Oracle DB instance
1. Connect to your Oracle DB instance using [this](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_ConnectToOracleInstance.html) guide. 
2. In this demo, we use Oracle SQL Developer with following connection configuration
```
Name: DB-Mod-Demo
Username: admin
Password: <auto_generated_password_from_aws>
Hostname:db-mod-demo.***.us-west-2.rds.amazonaws.com
Port: 1521
SID: ORCL
``` 
3. Before moving forward you need to configure the Oracle database according to [this](https://docs.confluent.io/kafka-connect-oracle-cdc/current/prereqs-validation.html#oracle-database-prerequisites) doc. 

## Populate Oracle database
1. Create a new connection to Oracle database using the username and password from previous step. In this demo the configuration is
```
Name: DB-Mod-Demo-User
Username: DB_USER
Password: <secure_password>
Hostname:db-mod-demo.***.us-west-2.rds.amazonaws.com
Port: 1521
SID: ORCL
```
2. You can use `populate_database.sql` to create **Customers** table and populate it, or proceed with the following steps. 

3. Create the **Customers** table using the following query.
```SQL
create table CUSTOMERS (
        id INT PRIMARY KEY,
        first_name VARCHAR(50),
        last_name VARCHAR(50),
        dob VARCHAR(10),
        email VARCHAR(50),
        avg_credit_spend DOUBLE PRECISION
);
```
4. Populate the **Custmers** table using the following query. 
```SQL
insert into CUSTOMERS (id, first_name, last_name, dob, email, avg_credit_spend) values (1, 'Rica', 'Blaisdell', '1958-04-23', 'rblaisdell0@rambler.ru', 2000);
insert into CUSTOMERS (id, first_name, last_name, dob, email, avg_credit_spend) values (2, 'Ruthie', 'Brockherst', '1971-07-17', 'rbrockherst1@ow.ly', 3000);
insert into CUSTOMERS (id, first_name, last_name, dob, email, avg_credit_spend) values (3, 'Mariejeanne', 'Cocci', '1961-02-13', 'mcocci2@techcrunch.com', 4000);
insert into CUSTOMERS (id, first_name, last_name, dob, email, avg_credit_spend) values (4, 'Hashim', 'Rumke', '1953-04-08', 'hrumke3@sohu.com',  5000);
insert into CUSTOMERS (id, first_name, last_name, dob, email, avg_credit_spend) values (5, 'Hansiain', 'Coda', '1974-04-14', 'hcoda4@senate.gov', 6000);
insert into CUSTOMERS (id, first_name, last_name, dob, email, avg_credit_spend) values (6, 'Robinet', 'Leheude', '1993-08-02', 'rleheude5@reddit.com', 7000);
insert into CUSTOMERS (id, first_name, last_name, dob, email, avg_credit_spend) values (7, 'Fay', 'Huc', '1953-05-13', 'fhuc6@quantcast.com', 8000.00);
insert into CUSTOMERS (id, first_name, last_name, dob, email, avg_credit_spend) values (8, 'Patti', 'Rosten', '1984-05-09', 'prosten7@ihg.com', 9000.00);
insert into CUSTOMERS (id, first_name, last_name, dob, email, avg_credit_spend) values (9, 'Even', 'Tinham', '1987-12-20', 'etinham8@facebook.com', 2400.00);
insert into CUSTOMERS (id, first_name, last_name, dob, email, avg_credit_spend) values (10, 'Brena', 'Tollerton', '1990-08-28', 'btollerton9@furl.net', 3600.00);
insert into CUSTOMERS (id, first_name, last_name, dob, email, avg_credit_spend) values (11, 'Alexandro', 'Peeke-Vout', '1974-09-19', 'apeekevouta@freewebs.com', 4400.00);
insert into CUSTOMERS (id, first_name, last_name, dob, email, avg_credit_spend) values (12, 'Sheryl', 'Hackwell', '1970-12-30', 'shackwellb@paginegialle.it', 5600.00);
insert into CUSTOMERS (id, first_name, last_name, dob, email, avg_credit_spend) values (13, 'Laney', 'Toopin', '1995-11-17', 'ltoopinc@icio.us', 6400.00);
insert into CUSTOMERS (id, first_name, last_name, dob, email, avg_credit_spend) values (14, 'Isabelita', 'Talboy', '1986-12-27', 'italboyd@imageshack.us', 7600.00);
insert into CUSTOMERS (id, first_name, last_name, dob, email, avg_credit_spend) values (15, 'Rodrique', 'Silverton', '1952-06-12', 'rsilvertone@umn.edu', 8400.00);
insert into CUSTOMERS (id, first_name, last_name, dob, email, avg_credit_spend) values (16, 'Clair', 'Vardy', '1962-03-10', 'cvardyf@reverbnation.com', 9600.00);
insert into CUSTOMERS (id, first_name, last_name, dob, email, avg_credit_spend) values (17, 'Brianna', 'Paradise', '1965-11-24', 'bparadiseg@nifty.com', 10400.00);
insert into CUSTOMERS (id, first_name, last_name, dob, email, avg_credit_spend) values (18, 'Waldon', 'Keddey', '1966-05-07', 'wkeddeyh@weather.com', 11600.00);
insert into CUSTOMERS (id, first_name, last_name, dob, email, avg_credit_spend) values (19, 'Josiah', 'Brockett', '1980-09-11', 'jbrocketti@com.com', 12000.00);
insert into CUSTOMERS (id, first_name, last_name, dob, email, avg_credit_spend) values (20, 'Anselma', 'Rook', '1982-06-22', 'arookj@europa.eu', 12400.00);
```

5. Commit these changes to the database by pressing the `Commit` icon.

## Set up RabbitMQ
This demo uses RabbitMQ as a Service provided by https://www.cloudamqp.com/. 
1. Create a new RabbitMQ instance in the same region as your Confluent Cloud cluster. This demo uses AWS Oregon (US-West-2).
2. Update `creditcard_send.py` and `creditcard_receive.py` scripts to include your `AMQP URL` string.
3. Use the `creditcard_send.py` to populate the **RabbitMQ** instance with sample messages. 
4. To verify that messages are received properly by the server, run `creditcard_receive.py`. 

## Set up a MongoDB Atlas cluster
1. Sign up for a free MongoDB account [here](https://www.mongodb.com/cloud/atlas/register1). This demo uses AWS Oregon (US-West-2) as the region.
2. Create a **Shared** cluster using [this](https://www.mongodb.com/docs/atlas/tutorial/create-new-cluster/) guide. 