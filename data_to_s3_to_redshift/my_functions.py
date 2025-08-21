
import random
from datetime import datetime

import awswrangler as wr
import boto3
import pandas as pd
from airflow.models import Variable
from dotenv import load_dotenv
from faker import Faker

load_dotenv()

fake = Faker()

wr.config.engine = "python"

def random_value():
    '''returns a random integer between 500000 and 700000'''
    return random.randint(50, 70)

def create_df():
    users = [
        {
            "id": fake.uuid4(),
            "name": fake.name(),
            "email": fake.email(),
            "signup_date": fake.date_this_year(),
            "company": fake.company()
        }
        for i in range(random_value())
    ]
    df = pd.DataFrame(users)
    return df
  

df = create_df()

session = boto3.Session(
    aws_access_key_id=Variable.get('aws_access_key'),
    aws_secret_access_key=Variable.get('aws_secret_key'),
    region_name=Variable.get('region'),
)

date_value = datetime.today().strftime('%Y-%m-%d')
s3path = "s3://wofai-terraform-s3-bucket/transactional_data"
path = f"{s3path}/{date_value}_transactional_data.parquet"

def upload_to_aws_bucket():
    # """
    # Upload the generated DataFrame to S3 in Parquet format.
    # """
    wr.s3.to_parquet(
        df=df,
        path=path,
        boto3_session=session,
        mode="overwrite",
        dataset=True,
        compression="snappy"
        )
    