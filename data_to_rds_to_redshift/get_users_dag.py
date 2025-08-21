from datetime import datetime

from airflow import DAG
from airflow.operators.python import PythonOperator
from get_users_function import get_users

api_user_dag = DAG(
     dag_id="api_get_user_dag",
     start_date=datetime(2025,8,1),
     schedule="@daily",
     catchup=False
    )

data_from_api = PythonOperator(
    task_id="data_from_api", 
    dag=api_user_dag,
    python_callable=get_users
                                                      
    )
data_from_api 