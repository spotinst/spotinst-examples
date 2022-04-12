# spot-log query service 

Install this next to your spot-controller to print logs from the Spot.io Ocean. This service simply spits out logs to stdout in JSON format. Then your log aggregation service can use the container logs and publish them to your own logging platform.

## Install

`kubectl apply -f spot-logs.yaml --namespace kube-system`

The first query when first installing the service will look for logs back 1 hour and then will use the last log's timestamp for the next query's start timestamp. It will run and collect logs every 10 minutes.

> This service assumes the spot-controller was installed with standard configuration.