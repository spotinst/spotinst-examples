# OpsWorks prefix hostname

This is an extension to the Spotinst user data script

To use this script change your user data to -

```
#!/bin/bash

curl -fsSL <URL to S3 with this script or Github> | \
OPSWORKS_STACK_TYPE="REGIONAL" \
OPSWORKS_STACK_ID="491710be-e1df-4969-9309-3e069306d4ed" \
OPSWORKS_LAYER_ID="3952abc0-ae83-4444-b523-6186c632e9f0" \
HOSTNAME_PREFIX="Prefix" \
bash
```