#!/usr/bin/env python3
import os

import aws_cdk as cdk

from cdk_ocean.cdk_ocean_stack import CdkOceanStack


app = cdk.App()

CdkOceanStack(app, "CdkOceanStack",
    env=cdk.Environment(account=os.getenv('CDK_DEFAULT_ACCOUNT'), region=os.getenv('CDK_DEFAULT_REGION')),
    )

app.synth()
