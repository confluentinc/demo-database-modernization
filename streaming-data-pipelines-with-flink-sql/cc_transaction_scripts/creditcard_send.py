from confluent_kafka import Producer
from confluent_kafka.serialization import SerializationContext, MessageField
from confluent_kafka.schema_registry import SchemaRegistryClient
from confluent_kafka.schema_registry.json_schema import JSONSerializer
from config import config, sr_config
import datetime
from faker import Faker
import time
import random

fake = Faker()
USER_ID_COUNT = 20  #This number should match the number of customers in Oracle database

class CreditCardTransaction(object):
    def __init__(self, user_id, transaction_timestamp, amount, ip_address, transaction_id, credit_card_number):
        self.user_id = user_id
        self.transaction_timestamp = transaction_timestamp
        self.amount = amount
        self.ip_address = ip_address
        self.transaction_id = transaction_id
        self.credit_card_number = credit_card_number

schema_str = """{
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "title": "CreditCardTransaction",
    "description": "Credit card transaction data",
    "type": "object",
    "properties": {
        "user_id": {
            "description": "User ID",
            "type": "integer"
        },
        "transaction_timestamp": {
            "description": "Timestamp of the transaction in ms since epoch",
            "type": "string"
        },
        "amount": {
            "description": "Transaction amount",
            "type": "number"
        },
        "ip_address": {
            "description": "IP address of the transaction",
            "type": "string"
        },
        "transaction_id": {
            "description": "Transaction ID",
            "type": "string"
        },
        "credit_card_number": {
            "description": "Credit card number",
            "pattern": "^[0-9]{16}$",
            "type": "string"
        }
    }
}"""

def transaction_to_dict(transaction, ctx):
    return {
        "user_id": transaction.user_id,
        "transaction_timestamp": transaction.transaction_timestamp,
        "amount": transaction.amount,
        "ip_address": transaction.ip_address,
        "transaction_id": transaction.transaction_id,
        "credit_card_number": transaction.credit_card_number
    }

def generate_fake_credit_card_transaction():
    rand = random.Random()
    epoch = datetime.datetime.now().timestamp()

    user_id = random.randint(1, USER_ID_COUNT)  # Generate a random user ID
    transaction_timestamp = time.strftime('%Y-%m-%d %H:%M:%S',time.localtime(epoch))
    amount = round(rand.random() * 10000, 2)
    ip_address = fake.ipv4()  # Generate a random IPv4 address
    transaction_id = fake.uuid4()  # Generate a random transaction ID
    credit_card_number = fake.credit_card_number(card_type="mastercard")  # Generate a random credit card number (you can specify card types)
    return CreditCardTransaction(user_id, transaction_timestamp, amount, ip_address, transaction_id, credit_card_number)

def delivery_report(err, event):
    if err is not None:
        print(f'Delivery failed for userid {event.key().decode("utf8")}: {err}')
    else:
        print(f'Transaction data for userid {event.key().decode("utf8")} produced to {event.topic()}')

if __name__ == '__main__':
    topic = 'credit_card_transactions'
    schema_registry_client = SchemaRegistryClient(sr_config)

    json_serializer = JSONSerializer(schema_str,
                                     schema_registry_client,
                                     transaction_to_dict)

    producer = Producer(config)

    while True:  # Generate and send fake credit card transactions in an infinite loop
        transaction = generate_fake_credit_card_transaction()
        producer.produce(topic=topic, key=str(transaction.user_id),  # Convert user_id to string
                         value=json_serializer(transaction, SerializationContext(topic, MessageField.VALUE)),
                         on_delivery=delivery_report)

        producer.flush()  # Ensure that messages are sent immediately

        # Sleep for a while before generating the next transaction (adjust the sleep time as needed)
        time.sleep(1)  # Sleep for 1 second before generating the next transaction