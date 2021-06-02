# OpsWorks prefix hostname

This is an extension to the Spotinst user data script that will add a prefix to opsworks hostname.

To use this script change your user data of the Elastigroup like this example - 

```
#!/bin/bash

curl -fsSL <URL to S3 with this script or Github> | \
OPSWORKS_STACK_TYPE="REGIONAL" \
OPSWORKS_STACK_ID="<OPSWORKS_STACK_ID>" \
OPSWORKS_LAYER_ID="<OPSWORKS_LAYER_ID>" \
HOSTNAME_PREFIX="<HOSTNAME_PREFIX>" \
bash
```