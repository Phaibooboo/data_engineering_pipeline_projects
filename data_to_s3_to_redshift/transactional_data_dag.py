from datetime import datetime

from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.amazon.aws.transfers.s3_to_redshift import \
    S3ToRedshiftOperator
from my_functions import upload_to_aws_bucket

date_value = datetime.today().strftime('%Y-%m-%d')
s3path = "s3://wofai-terraform-s3-bucket/transactional_data"
path = f"{s3path}/{date_value}_transactional_data.parquet"

with DAG(dag_id="random_data_dag", 
        start_date=datetime(2025,8,1),
        schedule="@daily",
        catchup=False) as dag:
    
    
    extract_transactional_data = PythonOperator(
        task_id="extract_random_data",
        python_callable= upload_to_aws_bucket
    )

    s3_bucket_to_redshift = S3ToRedshiftOperator(
    task_id="s3_bucket_to_redshift",
    schema="public",
    table="transactions_table",
    s3_bucket="wofai-terraform-s3-bucket/transactional_data",
    s3_key=path,
    copy_options=["FORMAT AS PARQUET"],
    redshift_conn_id="wofai_redshift_conn_id",
    aws_conn_id="wofai_aws_conn_id",
    dag=dag
)
    extract_transactional_data >> s3_bucket_to_redshift