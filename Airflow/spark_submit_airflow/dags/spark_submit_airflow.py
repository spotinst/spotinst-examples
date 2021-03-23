from datetime import datetime, timedelta

from airflow import DAG
from airflow.operators.dummy_operator import DummyOperator
from airflow.hooks.S3_hook import S3Hook
from airflow.operators import PythonOperator
from airflow.contrib.operators.emr_add_steps_operator import EmrAddStepsOperator
from airflow.contrib.sensors.emr_step_sensor import EmrStepSensor

# Spot.io Elastigrup EMR Custom Operators
from spot_plugins.operators.create_emr_scaler import create_mrScaler
from spot_plugins.operators.delete_emr_scaler import delete_mrScaler

# Configurations
# Authentication, include Spot.io Token and Account ID
SPOT_TOKEN = "50b7427991023dc19ae0c122ec79c41202bd6cf9521a7cc7327d9942dfasdf" # replace this with your token
SPOT_ACCOUNT_ID = "act-61e1asdf" # replace this with your spot account id

BUCKET_NAME = "spotinst-airflow"  # replace this with your bucket name
local_data = "./dags/data/movie_review.csv"
s3_data = "data/movie_review.csv"
local_script = "./dags/scripts/spark/random_text_classification.py"
s3_script = "scripts/random_text_classification.py"
s3_clean = "clean_data/"
SPARK_STEPS = []

# Parameters that get passed to the Spot.io create EMR cluster API, Replace with your parameters
JOB_FLOW_OVERRIDES = {
    "mrScaler": {
        "name": "Airflow Example Job",
        "description": "this is an MRScaler created with Spot",
        "region": "us-west-2",
        "strategy": {
            "new": {
                "releaseLabel": "emr-5.29.0"
            }
        },
        "cluster": {
            "terminationProtected": "false",
            "keepJobFlowAliveWhenNoSteps": "true",
            "logUri": "s3://josh-emr-bucket",
            "jobFlowRole": "EMR_EC2_DefaultRole",
            "serviceRole": "EMR_DefaultRole"
        },
        "compute": {
            "availabilityZones": [
                {
                    "name": "us-west-2a",
                    "subnetId": "subnet-0a60fdfc059cc0c55"
                }
            ],
            "instanceGroups": {
                "masterGroup": {
                    "instanceTypes": [
                        "c1.medium",
                        "c1.xlarge"
                    ],
                    "target": 1,
                    "lifeCycle": "SPOT"
                },
                "coreGroup": {
                    "instanceTypes": [
                        "c1.medium",
                        "c1.xlarge"
                    ],
                    "capacity": {
                        "target": 1,
                        "minimum": 1,
                        "maximum": 1,
                        "unit": "instance"
                    },
                    "lifeCycle": "SPOT"
                },
                "taskGroup": {
                    "instanceTypes": [
                        "c1.medium"
                    ],
                    "capacity": {
                        "target": 0,
                        "minimum": 0,
                        "maximum": 0,
                        "unit": "instance"
                    },
                    "lifeCycle": "SPOT"
                }
            },
            "ec2KeyName": "Josh-EC2",
            "applications": [
                {
                    "name": "Hadoop"
                },
                {
                    "name": "Spark"
                }
            ],
            "configurations": {
                "file": {
                    "bucket": "josh-emr-bucket",
                    "key": "configuration.json"
                }
            }
        },
        "scheduling": {},
        "scaling": {},
        "coreScaling": {}
    }
}

# helper function
def _local_to_s3(filename, key, bucket_name=BUCKET_NAME):
    s3 = S3Hook()
    s3.load_file(filename=filename, bucket_name=bucket_name, replace=True, key=key)


default_args = {
    "owner": "airflow",
    "depends_on_past": True,
    "wait_for_downstream": True,
    "start_date": datetime(2020, 10, 17),
    "email": ["josh.lee@netapp.com"],
    "email_on_failure": True,
    "email_on_retry": False,
    "retries": 1,
    "retry_delay": timedelta(minutes=5),
}

dag = DAG(
    "spark_submit_airflow",
    default_args=default_args,
    schedule_interval="0 10 * * *",
    max_active_runs=1,
)

start_data_pipeline = DummyOperator(task_id="start_data_pipeline", dag=dag)

data_to_s3 = DummyOperator(task_id="data_to_s3", dag=dag)

script_to_s3 = DummyOperator(task_id="script_to_s3", dag=dag)

# Create EMR - custom operator - Spot.io - create emr cluster api
create_spot_mr_scaler = create_mrScaler(
    task_id='create_elastigroup_emr_cluster',
    spot_token=SPOT_TOKEN,
    account_id=SPOT_ACCOUNT_ID,
    job_flow_overrides=JOB_FLOW_OVERRIDES,
    dag=dag)

# Add your steps to the EMR cluster
step_adder = DummyOperator(task_id="add_steps", dag=dag)

last_step = len(SPARK_STEPS) - 1
# wait for the steps to complete
step_checker = DummyOperator(task_id="watch_step", dag=dag)

# Terminate EMR Cluster  - custom operator - Spot.io - terminate emr cluster api
terminate_mr_scaler = delete_mrScaler(
    task_id='terminate_elastigroup_emr_cluster',
    spot_token=SPOT_TOKEN,
    provide_context=True,
    dag=dag,
    xcom_task_id='create_elastigroup_emr_cluster',
    xcom_task_id_key='return_value'
    )

end_data_pipeline = DummyOperator(task_id="end_data_pipeline", dag=dag)

start_data_pipeline >> [data_to_s3, script_to_s3] >> create_spot_mr_scaler
create_spot_mr_scaler >> step_adder >> step_checker >> terminate_mr_scaler >> end_data_pipeline

