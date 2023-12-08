SELECT * FROM `ORCL.ADMIN.CUSTOMERS`;

SELECT * FROM credit_card_transactions;

CREATE TABLE fd_transactions_enriched(
  `user_id` BIGINT, 
  `credit_card_number` STRING, 
  `amount` DOUBLE, 
  `transaction_timestamp` TIMESTAMP(0), 
  `first_name` STRING, 
  `last_name` STRING, 
  `email` STRING, 
  `avg_credit_spend` DOUBLE,
  WATERMARK FOR transaction_timestamp AS transaction_timestamp
  );

INSERT INTO fd_transactions_enriched
  SELECT T.user_id, 
    T.credit_card_number, 
    T.amount, 
    CAST(T.transaction_timestamp AS TIMESTAMP), 
    C.FIRST_NAME, 
    C.LAST_NAME, 
    C.EMAIL, 
    C.AVG_CREDIT_SPEND
  FROM credit_card_transactions T
  INNER JOIN `ORCL.ADMIN.CUSTOMERS` C 
  ON T.user_id = C.ID;


CREATE TABLE fd_possible_stolen_card(
  `window_start` TIMESTAMP(0), 
  `window_end` TIMESTAMP(0), 
  `user_id` BIGINT, 
  `credit_card_number` STRING, 
  `first_name` STRING, 
  `last_name` STRING, 
  `email` STRING, 
  `transaction_timestamp` TIMESTAMP(0), 
  `total_credit_spend` DOUBLE, 
  `avg_credit_spend` DOUBLE
  );

INSERT INTO fd_possible_stolen_card 
  SELECT window_start, window_end, user_id, credit_card_number, first_name, last_name, email, transaction_timestamp, SUM(amount) AS total_credit_spend, MAX(avg_credit_spend) as avg_credit_spend
  FROM TABLE (
    TUMBLE(TABLE fd_transactions_enriched, DESCRIPTOR(transaction_timestamp), INTERVAL '2' HOUR )) 
  GROUP BY window_start, window_end, user_id, credit_card_number, first_name, last_name, email, transaction_timestamp
  HAVING SUM(amount) > MAX(avg_credit_spend);
