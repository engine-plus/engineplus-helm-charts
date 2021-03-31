# Airflow Helm Chart

Airflow is a platform to programmatically author, schedule, and monitor workflows.

## Install Airflow

Two ways to install Airflow: execute ``sh install_all.sh`` in engineplus-helm-charts dir or install Airflow separately by using following commands.

1. ``Prepare env``. Before install Airflow, ensure the ['Prepare ENV Vars'](../README.md) has been declared. You can refer to the README of engineplus-helm-charts.

Here is copy from the README of engineplus-helm-charts.
```bash
# Public variables for all components 
# Please use your own values
export ENGINEPLUS_REPO_PREFIX="SUBSCRIBE_IMAGE_URL"
export ENGINEPLUS_INGRESS_HOST=example.com
export ENGINEPLUS_S3_PREFIX=s3://xxxxx/engineplus
export ENGINEPLUS_ROLE_ARN=arn:aws:iam::ACCOUNT-NUMBER:role/IAM-ROLE-NAME
export ENGINEPLUS_SPARK_SERVICEACCOUNT=spark
export ENGINEPLUS_REPO_TAG=engineplus-2.0.1
export ENGINEPLUS_NAMESPACE=engineplus
export ENGINEPLUS_INGRESS_ENABLED=true
# generate random password to login zeppelin/airflow/jupyter/spark-history-server/spark ui 
# default login user is admin 
export ENGINEPLUS_PASSWORD="YOUR_ADMIN_PASSWORD"
# Required variables For Airflow && Jupyter. If you forget it, you can get it in airflow-env of Config Maps in kube-dashboard by typing "AIRFLOW__REST_API_PLUGIN__REST_API_PLUGIN_EXPECTED_HTTP_TOKEN"
export ENGINEPLUS_AIRFLOW_REST_TOKEN=$(cat /dev/urandom | head -n 10 | md5sum | head -c 32)
export ENGINEPLUS_JUPYTER_PROXY_SECRETTOKEN=$(cat /dev/urandom | head -n 10 | md5sum | head -c 32)
```


2. RDS Mysql database should be already created. [how to create a RDS](https://aws.amazon.com/rds/?nc1=h_ls)
```bash
# connect to your RDS Mysql and type the password
mysql -h mysql_host -u mysql_user_name -p

# then create a new database
CREATE DATABASE engineplus_airflow

# Export RDS Mysql envs
export ENGINEPLUS_AIRFLOW_DB_RDS_MYSQL_HOST=mysql_host
export ENGINEPLUS_AIRFLOW_DB_RDS_MYSQL_PORT=mysql_port
export ENGINEPLUS_AIRFLOW_DB_RDS_MYSQL_USER=mysql_user_name
export ENGINEPLUS_AIRFLOW_DB_RDS_MYSQL_PASSWORD=mysql_user_password
export ENGINEPLUS_AIRFLOW_DB_RDS_MYSQL_DATEBASE=engineplus_airflow

```

3. Set TimeZone
```bash
# example: "America/New_York"
export ENGINEPLUS_AIRFLOW_TIMEZONE="UTC"

```


Install the Airflow Chart by running this command.

```bash
helm install airflow \
  ./airflow/charts \
  --namespace ${ENGINEPLUS_NAMESPACE} \
  --set web.admin_passwd=${ENGINEPLUS_PASSWORD} \
  --set airflow.image.repository=${ENGINEPLUS_REPO_PREFIX}/airflow \
  --set airflow.image.tag=${ENGINEPLUS_REPO_TAG} \
  --set dags.git.image.gitSync.repository=${ENGINEPLUS_REPO_PREFIX}/airflow-git \
  --set airflow.s3Sync.s3Path=${ENGINEPLUS_S3_PREFIX}/jupyter-sdk-s3-sync \
  --set externalDatabase.host=${ENGINEPLUS_AIRFLOW_DB_RDS_MYSQL_HOST} \
  --set externalDatabase.port=${ENGINEPLUS_AIRFLOW_DB_RDS_MYSQL_PORT} \
  --set externalDatabase.database=${ENGINEPLUS_AIRFLOW_DB_RDS_MYSQL_DATEBASE} \
  --set externalDatabase.user=${ENGINEPLUS_AIRFLOW_DB_RDS_MYSQL_USER} \
  --set externalDatabase.DATABASE_PASSWORD=${ENGINEPLUS_AIRFLOW_DB_RDS_MYSQL_PASSWORD} \
  --set ingress.enabled=${ENGINEPLUS_INGRESS_ENABLED} \
  --set ingress.web.host=airflow.${ENGINEPLUS_INGRESS_HOST} \
  --set web.baseUrl=http://airflow.${ENGINEPLUS_INGRESS_HOST} \
  --set ingress.flower.host=airflow.${ENGINEPLUS_INGRESS_HOST} \
  --set airflow.s3Sync.image=${ENGINEPLUS_REPO_PREFIX}/airflow \
  --set airflow.s3Sync.tag=${ENGINEPLUS_REPO_TAG} \
  --set airflow.config.AIRFLOW__REST_API_PLUGIN__REST_API_PLUGIN_EXPECTED_HTTP_TOKEN=${ENGINEPLUS_AIRFLOW_REST_TOKEN} \
  --set airflow.config.AIRFLOW__CORE__REMOTE_BASE_LOG_FOLDER=${ENGINEPLUS_S3_PREFIX}/logs \
  --set airflow.extraEnv[0].name="TZ",airflow.extraEnv[0].value=${ENGINEPLUS_AIRFLOW_TIMEZONE} 

```

## Uninstall Airflow

Uninstall Airflow Release.

```bash
helm uninstall airflow -n ${ENGINEPLUS_NAMESPACE}
```

## Upgrade Airflow

Before upgrade Airflow Release, it also needed to ``Prepare env``.
Then execute the following command. 

```bash
helm upgrade airflow ./airflow/charts \
  --namespace ${ENGINEPLUS_NAMESPACE} \
  --set web.admin_passwd=${ENGINEPLUS_PASSWORD} \
  --set airflow.image.repository=${ENGINEPLUS_REPO_PREFIX}/airflow \
  --set airflow.image.tag=${ENGINEPLUS_REPO_TAG} \
  --set dags.git.image.gitSync.repository=${ENGINEPLUS_REPO_PREFIX}/airflow-git \
  --set airflow.s3Sync.s3Path=${ENGINEPLUS_S3_PREFIX}/jupyter-sdk-s3-sync \
  --set externalDatabase.host=${ENGINEPLUS_AIRFLOW_DB_RDS_MYSQL_HOST} \
  --set externalDatabase.port=${ENGINEPLUS_AIRFLOW_DB_RDS_MYSQL_PORT} \
  --set externalDatabase.database=${ENGINEPLUS_AIRFLOW_DB_RDS_MYSQL_DATEBASE} \
  --set externalDatabase.user=${ENGINEPLUS_AIRFLOW_DB_RDS_MYSQL_USER} \
  --set externalDatabase.DATABASE_PASSWORD=${ENGINEPLUS_AIRFLOW_DB_RDS_MYSQL_PASSWORD} \
  --set ingress.enabled=${ENGINEPLUS_INGRESS_ENABLED} \
  --set ingress.web.host=airflow.${ENGINEPLUS_INGRESS_HOST} \
  --set web.baseUrl=http://airflow.${ENGINEPLUS_INGRESS_HOST} \
  --set ingress.flower.host=airflow.${ENGINEPLUS_INGRESS_HOST} \
  --set airflow.s3Sync.image=${ENGINEPLUS_REPO_PREFIX}/airflow \
  --set airflow.s3Sync.tag=${ENGINEPLUS_REPO_TAG} \
  --set airflow.config.AIRFLOW__REST_API_PLUGIN__REST_API_PLUGIN_EXPECTED_HTTP_TOKEN=${ENGINEPLUS_AIRFLOW_REST_TOKEN} \
  --set airflow.config.AIRFLOW__CORE__REMOTE_BASE_LOG_FOLDER=${ENGINEPLUS_S3_PREFIX}/logs \
  --set airflow.extraEnv[0].name="TZ",airflow.extraEnv[0].value=${ENGINEPLUS_AIRFLOW_TIMEZONE} 
```
## Add Airflow users

You can add new users by executing the script in worker/web/scheduler pods.

```bash
/usr/bin/python /opt/airflow/create_airflow_user.py -u YOUR_USER_NAME -p YOUR_PASSWORD
```