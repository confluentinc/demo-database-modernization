#!/usr/bin/env python
import pika
import time
import os
import json

if __name__ == '__main__':
    url = os.environ.get('CLOUDAMQP_URL')
    params = pika.URLParameters(url)
    connection = pika.BlockingConnection(params)
    channel = connection.channel() 

    channel.queue_declare(queue='txs',durable=True)
    print(' [*] Waiting for messages. To exit press CTRL+C')


    def callback(ch, method, properties, body):
        print(json.loads(body))
        print(" [x] Done")
        ch.basic_ack(delivery_tag=method.delivery_tag)


    channel.basic_qos(prefetch_count=1)
    channel.basic_consume(queue='txs', on_message_callback=callback)

    channel.start_consuming()