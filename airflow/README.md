# Airflow Helm Chart

Airflow is a platform to programmatically author, schedule, and monitor workflows.

## Install Airflow

Two ways to install Airflow: execute ``sh install_all.sh`` in  parent directory **or** install separately by using following steps.

1. RDS Mysql database should be already created. Click this [how to create a RDS](https://aws.amazon.com/rds/?nc1=h_ls).
2. **Prepare ENV Vars**. Before installation, envs should be declared from parent directory, refer to [Prepare ENV Vars](../README.md).
3. Execute the install following command.

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

 Before install Jupyter, ensure the ['Prepare ENV Vars'](../README.md) from parent directory has been declared.

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