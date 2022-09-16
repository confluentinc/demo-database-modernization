SET 'auto.offset.reset' = 'earliest';
CREATE OR REPLACE STREAM fd_cust_raw_stream WITH (KAFKA_TOPIC = 'ORCL.ADMIN.CUSTOMERS',VALUE_FORMAT = 'JSON_SR');
CREATE OR REPLACE TABLE fd_customers WITH (FORMAT='JSON_SR') AS 
    SELECT id                            AS customer_id,
           LATEST_BY_OFFSET(first_name)  AS first_name,
           LATEST_BY_OFFSET(last_name)   AS last_name,
           LATEST_BY_OFFSET(dob)         AS dob,
           LATEST_BY_OFFSET(email)       AS email,
           LATEST_BY_OFFSET(avg_credit_spend) AS avg_credit_spend
    FROM    fd_cust_raw_stream 
    GROUP BY id;
CREATE OR REPLACE STREAM fd_transactions(
	userid DOUBLE,
  	transaction_timestamp VARCHAR,
  	amount DOUBLE,
  	ip_address VARCHAR,
  	transaction_id INTEGER,
  	credit_card_number VARCHAR
	)
WITH(KAFKA_TOPIC='rabbitmq_transactions', KEY_FORMAT='JSON', VALUE_FORMAT='JSON', timestamp ='transaction_timestamp', timestamp_format = 'yyyy-MM-dd HH:mm:ss');

CREATE OR REPLACE STREAM fd_transactions_enriched WITH (KAFKA_TOPIC = 'transactions_enriched') AS
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

CREATE OR REPLACE TABLE fd_possible_stolen_card WITH (KAFKA_TOPIC = 'FD_possible_stolen_card', KEY_FORMAT = 'JSON', VALUE_FORMAT='JSON') AS
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