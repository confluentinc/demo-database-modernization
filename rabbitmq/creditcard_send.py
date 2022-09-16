import pika 
import os
import time
import datetime
import json
import random
import ccard
from dotenv import load_dotenv

load_dotenv()  # take environment variables from .env.


ACCOUNT_ID_COUNT = 20  #This number should match the number of customers in Oracle database
account_ids = [i + 1 for i in range(ACCOUNT_ID_COUNT)]

if __name__ == '__main__':
    url = os.environ.get('CLOUDAMQP_URL')
    params = pika.URLParameters(url)
    connection = pika.BlockingConnection(params)
    channel = connection.channel() # start a channel
    channel.queue_declare(queue='txs',durable=True) # Declare a queue
    rand = random.Random()

    try:
        while True:
            curr_id = rand.choice(account_ids)
            curr_amount = round(rand.random() * 10000, 2)   
            epoch = datetime.datetime.now().timestamp()
            curr_timestamp = time.strftime('%Y-%m-%d %H:%M:%S',time.localtime(epoch))
            curr_ip_address = '.'.join('%s'%rand.randint(0, 255) for i in range(4))
            curr_credit_card = str(rand.choice([ccard.visa(), ccard.americanexpress()]))
            curr_transaction_id = rand.randint(1,100)
            message = json.dumps(
                {'userid': curr_id,
                'transaction_timestamp': curr_timestamp,
                'amount': curr_amount,
                'ip_address': curr_ip_address,
                'transaction_id': curr_transaction_id,
                'credit_card_number': curr_credit_card})
            channel.basic_publish(
                exchange='',
                routing_key='txs',
                body=message,
                properties=pika.BasicProperties(delivery_mode=pika.spec.PERSISTENT_DELIVERY_MODE))
            time.sleep(1)
            print(" [x] Sent %r" % message) 
    except KeyboardInterrupt:
        print("\nstopping\n")
    finally:
        print("closing connection")
        connection.close()
