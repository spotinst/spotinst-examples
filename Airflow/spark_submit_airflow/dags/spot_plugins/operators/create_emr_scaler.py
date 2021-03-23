from airflow.models.baseoperator import BaseOperator
from airflow.utils.decorators import apply_defaults
from spot_plugins.operators.helper_mrscaler import create_cluster

class create_mrScaler(BaseOperator):

    @apply_defaults
    def __init__(
            self,
            job_flow_overrides=None,
            spot_token=None,
            account_id=None,
            # spot_mr_scaler=None,
            **kwargs) -> None:
        super().__init__(**kwargs)
        self.job_flow_overrides = job_flow_overrides
        self.spot_token = spot_token
        self.account_id = account_id

    def execute(self, context):#: Dict[str, Any]) -> List[str]:
        self.log.info(
            'Creating JobFlow using Spot.io Elastigroup MR Scaler'
        )
        response = create_cluster(self.job_flow_overrides, self.spot_token, self.account_id)
        print(response)
        return response