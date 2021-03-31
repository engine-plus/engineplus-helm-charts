## Init Description

Init aims to automatically create configmap and spark service based on the configuration, configmap and service used by third-party components on kubernetes cluster.

## Install

Execute init.sh. Firstly, generate templates/spark-configmap.yaml and templates/spark-service.yaml; then, kubectl apply, will creating kubernetes namespace、 configmap、serviceAccount、role...

```bash
$ sh ./init/init.sh
```

## Configuration

The following table lists the configurables parameters.

| Parameter                       | Description                                                                                      | Required |
| ------------------------------- | ------------------------------------------------------------------------------------------------ | -------- |
| ENGINEPLUS_S3_PREFIX            | engineplus.prefix.dir is used to configure spark.eventLog.dir/spark.kubernetes.file.upload.path. | True     |
| ENGINEPLUS_REPO_PREFIX          | engineplus repository prefix                                                                     | True     |
| ENGINEPLUS_REPO_TAG             | engineplus image tag                                                                             | True     |
| ENGINEPLUS_NAMESPACE            | kubernetes namespace                                                                             | True     |
| ENGINEPLUS_SPARK_SERVICEACCOUNT | spark.kubernetes.authenticate.driver.serviceAccountName                                          | True     |
| ENGINEPLUS_ROLE_ARN             | eks.amazonaws.com/role-arn                                                                       | True     |
| ENGINEPLUS_INGRESS_ENABLED      | spark.kubernetes.driver.ui.ingress.enabled                                                       | True     |
| ENGINEPLUS_INGRESS_HOST         | spark.kubernetes.driver.ui.ingress.host                                                          | True     |
