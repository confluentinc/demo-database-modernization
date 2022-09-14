import os
from dotenv import load_dotenv

load_dotenv()  # take environment variables from .env.

username = os.environ.get("ORACLE_USERNAME")
password = os.environ.get("ORACLE_PASSWORD")
dsn = os.environ.get("ORACLE_ENDPOINT")
port = 1512