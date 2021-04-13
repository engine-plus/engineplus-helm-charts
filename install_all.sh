#!/bin/bash

set -e

ENGINEPLUS_REPO_PREFIX=YOUR_REPO_URL/mobvista
ENGINEPLUS_REPO_TAG=engineplus-2.0.2
ENGINEPLUS_NAMESPACE=engineplus
ENGINEPLUS_INGRESS_ENABLED=true
ENGINEPLUS_INGRESS_HOST=YOUR_INGRESS_HOST_DOMAIN
ENGINEPLUS_S3_PREFIX=YOUR_S3_PREFIX
ENGINEPLUS_SPARK_SERVICEACCOUNT=spark
ENGINEPLUS_ROLE_ARN=arn:aws:iam::YOUR-ACCOUNT-NUMBER:role/YOUR-ROLE-NAME
# generate random password to login zeppelin/airflow/jupyter/spark-history-server/spark ui 
# default login user is admin 
ENGINEPLUS_PASSWORD=`cat /dev/urandom | head -n 10 | md5sum | head -c 16`
# Required variables For Airflow && Jupyter 
ENGINEPLUS_AIRFLOW_REST_TOKEN=$(cat /dev/urandom | head -n 10 | md5sum | head -c 32)
ENGINEPLUS_JUPYTER_PROXY_SECRETTOKEN=$(cat /dev/urandom | head -n 10 | md5sum | head -c 32)
ENGINEPLUS_AIRFLOW_DB_RDS_MYSQL_HOST="YOUR_RDS_ADDRESS"
ENGINEPLUS_AIRFLOW_DB_RDS_MYSQL_PORT=3306
ENGINEPLUS_AIRFLOW_DB_RDS_MYSQL_USER="YOUR_RDS_USER_NAME"
ENGINEPLUS_AIRFLOW_DB_RDS_MYSQL_PASSWORD="YOUR_RDS_PASSWORD"
ENGINEPLUS_AIRFLOW_DB_RDS_MYSQL_DATEBASE="YOUR_RDS_DATABASE_FOR_AIRFLOW"
ENGINEPLUS_AIRFLOW_TIMEZONE="UTC"

. ./init/init.sh

# install airflow 
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

# install jupyter
helm upgrade jupyter --install ./jupyter \
    --namespace ${ENGINEPLUS_NAMESPACE} \
    --set auth.dummy.password=${ENGINEPLUS_PASSWORD} \
    --set proxy.secretToken=${ENGINEPLUS_JUPYTER_PROXY_SECRETTOKEN} \
    --set singleuser.image.name=${ENGINEPLUS_REPO_PREFIX}/jupyter \
    --set singleuser.image.tag=${ENGINEPLUS_REPO_TAG} \
    --set ingress.enabled=${ENGINEPLUS_INGRESS_ENABLED} \
    --set ingress.hosts={jupyter.${ENGINEPLUS_INGRESS_HOST}} \
    --set singleuser.extraEnv.AIRFLOW_S3_SYNC_PATH=${ENGINEPLUS_S3_PREFIX}/jupyter-sdk-s3-sync \
    --set singleuser.extraEnv.AIRFLOW_REST_AUTHORIZATION_TOKEN=${ENGINEPLUS_AIRFLOW_REST_TOKEN} \
    --set singleuser.extraEnv.AIRFLOW_HOST=http://airflow-web.${ENGINEPLUS_NAMESPACE}:8080 \
    --set singleuser.networkTools.image.name=${ENGINEPLUS_REPO_PREFIX}/jupyterhub-k8s-network-tools \
    --set prePuller.hook.image.name=${ENGINEPLUS_REPO_PREFIX}/jupyterhub-k8s-image-awaiter \
    --set prePuller.pause.image.name=${ENGINEPLUS_REPO_PREFIX}/jupyterhub-pause \
    --set hub.image.name=${ENGINEPLUS_REPO_PREFIX}/jupyterhub-k8s-hub \
    --set proxy.secretSync.image.name=${ENGINEPLUS_REPO_PREFIX}/jupyterhub-k8s-secret-sync \
    --set proxy.chp.image.name=${ENGINEPLUS_REPO_PREFIX}/jupyterhub-configurable-http-proxy \
    --set proxy.traefik.image.name=${ENGINEPLUS_REPO_PREFIX}/jupyterhub-traefik \
    --set scheduling.userScheduler.image.name=${ENGINEPLUS_REPO_PREFIX}/jupyterhub-kube-scheduler \
    --wait --timeout 10m

# install spark-history
helm install spark-history-server ./spark-history-server \
      --namespace ${ENGINEPLUS_NAMESPACE} \
      --set s3.enableIAM=true \
      --set s3.enableS3=true \
      --set ingress.enabled=${ENGINEPLUS_INGRESS_ENABLED} \
      --set ingress.auth.password=${ENGINEPLUS_PASSWORD} \
      --set ingress.hosts={spark-history-server.${ENGINEPLUS_INGRESS_HOST}} \
      --set image.repository=${ENGINEPLUS_REPO_PREFIX}/spark-history-server \
      --set image.tag=${ENGINEPLUS_REPO_TAG}


# install zeppelin

ZEPPELIN_IMAGE_REPO=${ENGINEPLUS_REPO_PREFIX}/zeppelin:${ENGINEPLUS_REPO_TAG}
ZEPPELIN_CONF_DIR=${ENGINEPLUS_S3_PREFIX}/zeppelin/conf/
ZEPPELIN_NOTEBOOK_S3_BUCKET=$(cut -d/ -f3 <<<${ENGINEPLUS_S3_PREFIX})
ZEPPELIN_NOTEBOOK_S3_USER=${ENGINEPLUS_S3_PREFIX#*$ZEPPELIN_NOTEBOOK_S3_BUCKET/}/zeppelin/notebook
ZEPPELIN_SPARK_IMAGE_REPO=${ENGINEPLUS_REPO_PREFIX}/spark:${ENGINEPLUS_REPO_TAG}
ZEPPELIN_INGRESS_HOST=zeppelin.${ENGINEPLUS_INGRESS_HOST}

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

echo "Created Airflow Web: http://airflow.${ENGINEPLUS_INGRESS_HOST}"
echo "Created Jupyter Hub: http://jupyter.${ENGINEPLUS_INGRESS_HOST}"
echo "Created Zeppelin Web: http://zeppelin.${ENGINEPLUS_INGRESS_HOST}"
echo "Created Spark History Server: http://spark-history-server.${ENGINEPLUS_INGRESS_HOST}"
echo "Please use username: 'admin' and the randomly generated password: '${ENGINEPLUS_PASSWORD}' to login into Zeppelin, Jupyter, Airflow, Spark UI and Spark History Server."
