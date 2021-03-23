## Elastigroup Spark EMR Integration
This guide is intended to walk you through the integration of Airflow with Elastigroup EMR by leveraging the spot plugin for Airflow.

### Prerequisites

* [docker](https://docs.docker.com/get-docker/) (make sure to have docker-compose as well).
* [Spot.io Account & Token](https://spot.io/) to set up required cloud services.

##### Step 1:

Download the code located within the 'spot_plugins/operators' directory. Within this directory, there should be three files, 'create_emr_scaler.py', 'delete_emr_scaler.py', and 'helper_mrscaler.py'.

##### Step 2: 
Place the spot_plugins/operators directory inside of your dag directory.
Example path airflow/spark_submit_airflow/dags/spot_plugins/operators.

##### Step3: 
Within your DAG’s spark job python file, include the Spot.io custom operators. Import the Spot.io Elastigroup EMR Custom Operators
```python
from spot_plugins.operators.create_emr_scaler import create_mrScaler
from spot_plugins.operators.delete_emr_scaler import delete_mrScaler
```
Then include inside your spark job configuration parameters:
```python
SPOT_TOKEN - this will be your Spot.io programmatic token
SPOT_ACCOUNT_ID - this will be your spot.io account id
```
Authentication, include your Spot.io Token and Account ID.
```python
SPOT_TOKEN = "50b7427991023dc19ae0c122ec79c41202bd6cf9521a7ccasdf"
SPOT_ACCOUNT_ID = "act-61e1asdf"
```
Parameters that get passed to the Spot.io create EMR cluster API.
JOB_FLOW_OVERIDES - this will be in json format, following the spot.io API payload format. https://docs.spot.io/api/#operation/elastigroupAwsEmrCreate
```python
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
```

###### Step 4:
Include the Spot.io customer operator to create the EMR cluster using Elastigroup. This will use 'from spot_plugins.operators.create_emr_scaler import create_mrScaler' python module. 
```python
create_spot_mr_scaler = create_mrScaler(
   task_id='create_elastigroup_emr_cluster',
   spot_token=SPOT_TOKEN,
   account_id=SPOT_ACCOUNT_ID,
   job_flow_overrides=JOB_FLOW_OVERRIDES,
   dag=dag)
```
###### Step 5:
Include the Spot.io customer operator to terminate the EMR cluster when the spark job is complete. This will use 'from spot_plugins.operators.delete_emr_scaler import delete_mrScaler' python module. 
```python
terminate_mr_scaler = delete_mrScaler(
   task_id='terminate_elastigroup_emr_cluster',
   spot_token=SPOT_TOKEN,
   provide_context=True,
   dag=dag,
   xcom_task_id='create_elastigroup_emr_cluster',
   xcom_task_id_key='return_value'
   )
```
###### Step 6:
Update the Airflow workflow sequence.
```python
start_data_pipeline >> [data_to_s3, script_to_s3] >> create_spot_mr_scaler
create_spot_mr_scaler >> step_adder >> step_checker >> terminate_mr_scaler >> end_data_pipeline
```

###### To run Airflow locally
start instance
```bash
docker-compose -f docker-compose-LocalExecutor.yml up -d
```

go to [http://localhost:8080/admin/](http://localhost:8080/admin/) and turn on the `spark_submit_airflow` DAG. You can check the status at [http://localhost:8080/admin/airflow/graph?dag_id=spark_submit_airflow](http://localhost:8080/admin/airflow/graph?dag_id=spark_submit_airflow). 


stop instance

```bash
docker-compose -f docker-compose-LocalExecutor.yml down
```