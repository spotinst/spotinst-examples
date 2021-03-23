from airflow.models.baseoperator import BaseOperator
from airflow.utils.decorators import apply_defaults
from spot_plugins.operators.helper_mrscaler import terminate_cluster

template_fields = ['mrScaler_id']

class delete_mrScaler(BaseOperator):

    @apply_defaults
    def __init__(self, xcom_task_id, xcom_task_id_key, spot_token, *args, **kwargs):
        super(delete_mrScaler, self).__init__(*args, **kwargs)
        self.xcom_task_id = xcom_task_id
        self.xcom_task_id_key = xcom_task_id_key
        self.spot_token = spot_token

    def execute(self, context):
        task_instance = context['task_instance']
        mrScaler_id = task_instance.xcom_pull(self.xcom_task_id, key=self.xcom_task_id_key)
        self.log.info(mrScaler_id)
        response = terminate_cluster(mrScaler_id, self.spot_token)
        print(response)