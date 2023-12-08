import os
from dotenv import load_dotenv

load_dotenv()

# Define your configuration dictionary
config = {
    'bootstrap.servers': os.getenv('CCLOUD_BOOTSTRAP_ENDPOINT'),
    'security.protocol': 'SASL_SSL',
    'sasl.mechanisms': 'PLAIN',
    'sasl.username': os.getenv('CCLOUD_API_KEY'),
    'sasl.password': os.getenv('CCLOUD_API_SECRET')
}

sr_config = {
    'url': os.getenv('SR_URL'),
    'basic.auth.user.info': os.getenv('SR_USER_INFO')
}
