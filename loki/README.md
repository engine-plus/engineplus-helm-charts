# EnginePlus Loki QuickStart
When you need to install loki && promtail by engineplus-helm-charts, you can follow these steps:

## 1. Quick Helm Install 

```shell
#Please Define Your S3 Region and Bucket
REGION="us-east-1"
# loki will create s3://YOUR_BUCKET/index/ and s3://YOUR_BUCKET/fake/
BUCKET="YOUR_BUCKET"

kubectl create namespace loki
helm install promtail ./promtail --set "loki.serviceName=loki" --namespace=loki
helm install loki ./loki --namespace=loki --set config.storage_config.aws.s3="s3://${REGION}/${BUCKET}"
```

## 2. Uninstall

```shell
helm uninstall promtail --namespace=loki
helm uninstall loki --namespace=loki
```
