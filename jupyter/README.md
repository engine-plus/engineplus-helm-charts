# Jupyter

This repo contains a Helm chart for JupyterHub and a guide to use it. Together they allow you to make a JupyterHub available to a very large group of users such as the staff and students of a university.

## Install Jupyter
Two ways to install Jupyter: execute ``sh install_all.sh`` in engineplus-helm-charts dir or install Jupyter separately by using following commands.


1. ``Prepare env``. Before install Jupyter, ensure the ['Prepare ENV Vars'](../README.md) has been declared. You can refer to the README of engineplus-helm-charts.

Here is copy from the README of engineplus-helm-charts.(note: ENGINEPLUS_AIRFLOW_REST_TOKEN must be same with airflow's ENGINEPLUS_AIRFLOW_REST_TOKEN)
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
export ENGINEPLUS_AIRFLOW_REST_TOKEN="YOUR_ENGINEPLUS_AIRFLOW_REST_TOKEN"
export ENGINEPLUS_JUPYTER_PROXY_SECRETTOKEN=$(cat /dev/urandom | head -n 10 | md5sum | head -c 32)
```
2. execute the install command

```bash
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
```

## Uninstall JupyterHub

Uninstall JupyterHub Release.


```
helm uninstall jupyter -n ${ENGINEPLUS_NAMESPACE}

```

## Upgrade JupyterHub

Before upgrade JupyterHub Release, it also needed to ``Prepare env``.
Then execute the following command. 

```
helm upgrade --cleanup-on-fail jupyter ./jupyter \
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
```

## Demo

### Submit Pyspark to airflow
```python

import mindalpha.experiment as ma_exp
from datetime import datetime
import pyspark

job_name='train'
experiment_name='experiment1'
business_name='business1'

def execute(*args, **kwargs):
    execute_date = kwargs['next_execution_date']
    execute_date_format = datetime.fromtimestamp(execute_date.timestamp()).strftime('%Y%m%d%H')
    conf = pyspark.SparkConf()
    conf.set("spark.executor.instances", "2")
    sc = pyspark.SparkContext(conf=conf)
    print(sc.uiWebUrl)
    sqlContext = pyspark.SQLContext(sc)
    cols = ['ID', 'NAME', 'last.name', 'airflow_execute_date']
    val = [(1, 'Sam', 'SMITH', execute_date_format), (2, 'RAM', 'Reddy', execute_date_format)]
    df = sqlContext.createDataFrame(val, cols)
    df.show()
    sc.stop()
    
experiment=ma_exp.Experiment(
              job_name=job_name,
              experiment_name=experiment_name,
              business_name=business_name,
              owner='admin',
              schedule_interval='@hourly',
              func=execute,
              start_date='2021-03-03 15:00:00',
              end_date='2021-03-03 18:00:00'
              )
# experiment.submit_online()    
experiment.submit_backfill()
```


## Add Airflow users

1. You can add new user by editing ``auth.whitelist.users`` in the values.yaml.

```bash
# auth relates to the configuration of JupyterHub's Authenticator class.
auth:
  type: dummy
  whitelist:
    - user1
    - user2
```
2. update the chart. Refer to ``Upgrade JupyterHub``.