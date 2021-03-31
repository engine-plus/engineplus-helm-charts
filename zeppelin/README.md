# Zeppelin Chart

[Zeppelin](https://zeppelin.apache.org/) is a web based notebook for interactive data analytics with Spark, SQL and Scala.

## Chart Details

### Installing the Chart
##### 1.Before installation, you need the following configuration chart, modify and save the contents of the values.yaml file according to your own environment configuration

##### 2.To install the chart:
There are two ways to install, you can use -set or modify values.yaml
###### type：1. By modifying values.yaml, the parameters can be viewed in the following Configuration table，After modifying, execute the command
```bash
$ helm install zeppelin ./zeppelin
```

###### type: 2. Use -set to install
```bash
# please use your own value 
ZEPPELIN_IMAGE_REPO=${ENGINEPLUS_REPO_PREFIX}/zeppelin:${ENGINEPLUS_REPO_TAG}
ZEPPELIN_CONF_DIR=${ENGINEPLUS_S3_PREFIX}/zeppelin/conf/
ZEPPELIN_NOTEBOOK_S3_BUCKET=$(cut -d/ -f3 <<<${ENGINEPLUS_S3_PREFIX})
ZEPPELIN_NOTEBOOK_S3_USER=${ENGINEPLUS_S3_PREFIX#*$ZEPPELIN_NOTEBOOK_S3_BUCKET/}/zeppelin/notebook
ZEPPELIN_SPARK_IMAGE_REPO=${ENGINEPLUS_REPO_PREFIX}/spark:${ENGINEPLUS_REPO_TAG}
ZEPPELIN_INGRESS_HOST=zeppelin.${ENGINEPLUS_INGRESS_HOST}

# helm install command
helm install zeppelin ./zeppelin \
      --namespace ${ENGINEPLUS_NAMESPACE} \
      --set zeppelin.image=${ZEPPELIN_IMAGE_REPO} \
      --set zeppelin.password=${ENGINEPLUS_PASSWORD} \
      --set zeppelin.confStorage=${ZEPPELIN_CONF_DIR} \
      --set zeppelin.noteBookS3Bucket=${ZEPPELIN_NOTEBOOK_S3_BUCKET} \
      --set zeppelin.noteBookS3User=${ZEPPELIN_NOTEBOOK_S3_USER} \
      --set spark.image=${ZEPPELIN_SPARK_IMAGE_REPO} \
      --set ingress.enabled=${ENGINEPLUS_INGRESS_ENABLED} \
      --set ingress.suffix=${ENGINEPLUS_INGRESS_HOST} \
      --set ingress.hosts=${ZEPPELIN_INGRESS_HOST}
```
### uninstall the Chart
To uninstall the chart:
```bash
$ helm uninstall zeppelin
```
### upgrade the Chart
The current upgrade operation does not support hot restart, so you need to restart the zeppelin-server pod after modification to take effect.

```bash
$ helm upgrade --set zeppelin.image=xxxxxx zeppelin zeppelin
$ kubectl delete -n default pod $(kubectl get pods -n default| grep zeppelin-server|awk '{print $1}')
```

## Configuration

The following tables lists the configurable parameters of the Zeppelin Sever chart and their default values

| Parameter                            | Required | Description                                                       |Example                           |
| ------------------------------------ | ---------|----------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| zeppelin.image     | yes | you zeppelin image | xxxxxxxx.amazonaws.com/xxxxxx/zeppelin:v.xx |
| zeppelin.password  | yes | admin password | your password|
| zeppelin.confStorage  | yes | save you zeppelin conf to s3 | s3://home/xxxx/zeppelin/conf/ |
| zeppelin.noteBookS3Buckt  | yes | Save the notebook file to the s3 path：s3://home/xxxx/zeppelin/ (s3://{bucket}/{username}/) | home|
| zeppelin.noteBookS3User | yes | Save the notebook file to the s3 path：s3://home/xxxx/zeppelin/ (s3://{bucket}/{username}/) | enginplus/zeppelin |
| zeppelin.notebookCronEnable | yes  |  notebook cron enable | true/false |
| spark.image         | yes | you spark image | xxxxxxxxx.amazonaws.com/xxxx/spark:v.xx |
| ingress.enabled     | yes     | ingress switch | true/false |
| ingress.suffix     | yes     | ingress suffix | xxxxx.com |
| ingress.hosts  | yes      | zeppelin UI |zeppelin.xxxxx.com|

## interperter conf
For the configuration of the interpreter, please refer to the official website document: [https://zeppelin.apache.org/docs/0.9.0/usage/interpreter/overview.html]
