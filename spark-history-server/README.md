# EnginePlus Spark History Server QuickStart
When you need to install spark history server by engineplus-helm-charts, you can follow these steps:

## 1. Quick Helm Install

```shell
# helm install command
helm install spark-history-server ./spark-history-server \
      --namespace ${ENGINEPLUS_NAMESPACE} \
      --set s3.enableIAM=true \
      --set s3.enableS3=true \
      --set ingress.enabled=${ENGINEPLUS_INGRESS_ENABLED} \
      --set ingress.auth.password=${ENGINEPLUS_PASSWORD} \
      --set ingress.hosts={spark-history-server.${ENGINEPLUS_INGRESS_HOST}} \
      --set image.repository=${ENGINEPLUS_REPO_PREFIX}/spark-history-server \
      --set image.tag=${ENGINEPLUS_REPO_TAG}
```

## 2. Uninstall 

```shell
helm uninstall spark-history-server -n $ENGINEPLUS_NAMESPACE
```
