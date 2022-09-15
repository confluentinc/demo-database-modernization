from sqlite3 import DatabaseError
import pika 
import os
import signal
import sys
import time
import datetime
import json
import random
import math
import ccard

def signal_handler(signal, frame):
    sys.exit(0)

signal.signal(signal.SIGINT, signal_handler)

account_ids = []
timestamps = []
amounts = []
ip_addresses = []
transaction_ids = []
credit_cards_number = []

account_id_count = 20  #This number should match the number of customers in Oracle database
timestamp_count = 10 
amount_count = 10
ip_address_count = 10
transaction_id_count = 100
credit_card_count = 10


def generate_data():

    # Creating a list of IDs for customers. The count and format should match data in Oracle Database
    # Our database has 20 customers and the ID type is Integer
    for i in range (0,account_id_count):
        account_ids.append(i+1)

    for i in range (0, timestamp_count):
        epoch = datetime.datetime.now().timestamp()
        ts = time.strftime('%Y-%m-%d %H:%M:%S',time.localtime(epoch))
        time.sleep(1)
        timestamps.append(ts)

    # Creating a list of amounts
    for i in range (0, amount_count):
        random.seed(None)
        amount = random.random()
        amount = round((amount * 10000),2)
        amounts.append(amount)
    
    # Creating a list of ip addresses
    for i in range (0, ip_address_count):
        ip = '.'.join('%s'%random.randint(0, 255) for i in range(4))
        ip_addresses.append(ip)
    
    # Creating a list of transaction ids
    for i in range (0, transaction_id_count):
        transaction_ids.append(i+1)
    
    # Creating a list of credit cards
    for i in range (0, credit_card_count):
        if(i%2 == 0):
            credit_cards_number.append(ccard.visa())
        else:
            credit_cards_number.append(ccard.americanexpress())

    

if __name__ == '__main__':
    generate_data()
    url = os.environ.get('CLOUDAMQP_URL')
    params = pika.URLParameters(url)
    connection = pika.BlockingConnection(params)
    channel = connection.channel() # start a channel
    channel.queue_declare(queue='txs',durable=True) # Declare a queue

    for i in range(0,50):
        # Seeding random function with current time
        random.seed(None)
        rand = random.random()
        curr_id = i % account_id_count
        curr_timestamp = int(rand * timestamp_count)
        curr_amount = int(rand * amount_count)
        curr_ip_address = int(rand * ip_address_count)
        curr_transaction_id = int(rand * transaction_id_count)
        curr_credit_card = int(rand * credit_card_count)

        message = json.dumps({'userid':account_ids[curr_id], 'transaction_timestamp':str(timestamps[curr_timestamp]), 'amount':amounts[curr_amount], 'ip_address':ip_addresses[curr_ip_address], 'transaction_id':transaction_ids[curr_transaction_id], 'credit_card_number':credit_cards_number[curr_credit_card]})
        channel.basic_publish(
            exchange='',
            routing_key='txs',
            body=message,
            properties=pika.BasicProperties(delivery_mode=pika.spec.PERSISTENT_DELIVERY_MODE))
        time.sleep(1)
        print(" [x] Sent %r" % message) 

    connection.close()

