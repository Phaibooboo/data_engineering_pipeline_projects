from datetime import datetime

import pandas as pd
import requests
from airflow.models import Variable
from dotenv import load_dotenv
#import boto3
#import json
from sqlalchemy import create_engine

load_dotenv

def get_users():
    
    url = "https://randomuser.me/api/?results=500"
    response = requests.get(url)
    data = response.json()
    profiles = data['results']
    full_names = []

    for profile in profiles[:10]:
        full_names.append(profile['name']['title'] + ' ' + profile['name']['first'] + ' ' +profile['name']['last'] )
    df = pd.DataFrame(full_names)

    user = Variable.get("db_username")
    password = Variable.get("db_password")
    host = Variable.get("db_host")
    port = Variable.get("db_port")
    database = Variable.get("db_name")

    engine = create_engine(f'postgresql+psycopg2://{user}:{password}@{host}:{port}/{database}')

    df.to_sql('competitions', engine, if_exists='replace', index=False) 