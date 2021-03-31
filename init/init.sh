#!/bin/bash

set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

ENGINEPLUS_S3_PREFIX="$ENGINEPLUS_S3_PREFIX"
SPARK_IMAGE="$ENGINEPLUS_REPO_PREFIX/spark:$ENGINEPLUS_REPO_TAG"
ENGINEPLUS_NAMESPACE="$ENGINEPLUS_NAMESPACE"
ENGINEPLUS_SPARK_SERVICEACCOUNT="$ENGINEPLUS_SPARK_SERVICEACCOUNT"
ENGINEPLUS_ROLE_ARN="$ENGINEPLUS_ROLE_ARN"
ENGINEPLUS_INGRESS_HOST="$ENGINEPLUS_INGRESS_HOST"
ENGINEPLUS_INGRESS_ENABLED=$ENGINEPLUS_INGRESS_ENABLED

if [[ -z ${ENGINEPLUS_S3_PREFIX} || -z ${ENGINEPLUS_REPO_PREFIX} || -z ${ENGINEPLUS_REPO_TAG} || -z ${ENGINEPLUS_NAMESPACE} || -z \
  ${ENGINEPLUS_SPARK_SERVICEACCOUNT} || -z ${ENGINEPLUS_INGRESS_ENABLED} || -z ${ENGINEPLUS_INGRESS_HOST} || -z ${ENGINEPLUS_ROLE_ARN} ]]; then
  echo "Must define the environment variables in bash."
  exit 0
fi

if [[ ${ENGINEPLUS_S3_PREFIX} =~ .*/$ ]]; then
  ENGINEPLUS_S3_PREFIX=${ENGINEPLUS_S3_PREFIX%?}
fi

touch ${DIR}/temp

aws s3 cp ${DIR}/temp ${ENGINEPLUS_S3_PREFIX}/event-log/

aws s3 cp ${DIR}/temp ${ENGINEPLUS_S3_PREFIX}/spark-upload/

aws s3 cp ${DIR}/../zeppelin/demo/spark_tutorial_2G21PEM9Z.zpln ${ENGINEPLUS_S3_PREFIX}/zeppelin/notebook/notebook/

if [ ! -d $DIR/templates ]; then
  mkdir $DIR/templates
fi

set +e

exist=$(kubectl get namespace | grep -w "${ENGINEPLUS_NAMESPACE}")

if [[ -z $exist ]]; then
  kubectl create namespace ${ENGINEPLUS_NAMESPACE}
  if [[ $? -ne 0 ]]; then
    exit 255
  fi
fi

cat <<EOF >$DIR/templates/spark-configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: spark-configmap
data:
  spark-defaults.conf: |-
    spark.master k8s://https://kubernetes.default:443
    spark.kubernetes.namespace ${ENGINEPLUS_NAMESPACE}
    spark.eventLog.enabled true
    spark.eventLog.dir ${ENGINEPLUS_S3_PREFIX}/event-log
    spark.kubernetes.file.upload.path ${ENGINEPLUS_S3_PREFIX}/spark-upload
    spark.kubernetes.driver.volumes.hostPath.spark-local-dir-0.mount.path /opt/spark/local_dir
    spark.kubernetes.executor.volumes.hostPath.spark-local-dir-0.mount.path /opt/spark/local_dir
    spark.kubernetes.driver.volumes.hostPath.spark-local-dir-0.options.path /mnt
    spark.kubernetes.executor.volumes.hostPath.spark-local-dir-0.options.path /mnt
    spark.kubernetes.driver.podTemplateFile /opt/spark/conf/driver-podTemplate.yaml
    spark.kubernetes.executor.podTemplateFile /opt/spark/conf/executor-podTemplate.yaml
    spark.kubernetes.driver.container.image ${SPARK_IMAGE}
    spark.kubernetes.executor.container.image ${SPARK_IMAGE}
    spark.kubernetes.authenticate.driver.serviceAccountName ${ENGINEPLUS_SPARK_SERVICEACCOUNT}
    spark.hadoop.mapreduce.fileoutputcommitter.algorithm.version 2
    spark.hadoop.fs.s3a.impl org.apache.hadoop.fs.s3a.S3AFileSystem
    spark.hadoop.fs.s3.impl org.apache.hadoop.fs.s3a.S3AFileSystem
    spark.hadoop.mapred.output.committer.class org.apache.hadoop.mapred.FileOutputCommitter
    spark.kubernetes.driver.ui.ingress.host ${ENGINEPLUS_INGRESS_HOST}
    spark.kubernetes.driver.ui.ingress.enabled ${ENGINEPLUS_INGRESS_ENABLED}
    spark.kubernetes.driver.ui.ingress.annotation.kubernetes.io/ingress.class nginx
    spark.kubernetes.driver.ui.ingress.annotation.nginx.ingress.kubernetes.io/auth-type basic
    spark.kubernetes.driver.ui.ingress.annotation.nginx.ingress.kubernetes.io/auth-secret basic-auth
    spark.kubernetes.driver.ui.ingress.annotation.nginx.ingress.kubernetes.io/auth-realm "Authentication Required - admin"

  driver-podTemplate.yaml: |-
    apiVersion: v1
    kind: Pod
    metadata:
      annotations:
        cluster-autoscaler.kubernetes.io/safe-to-evict: "false"
    spec:
      securityContext:
        fsGroup: 65534
      nodeSelector:
        nodestype: spark-applications-driver-nodes

  executor-podTemplate.yaml: |-
    apiVersion: v1
    kind: Pod
    metadata:
      annotations:
        cluster-autoscaler.kubernetes.io/safe-to-evict: "false"
    spec:
      securityContext:
        fsGroup: 65534
      nodeSelector:
        nodestype: spark-applications-nodes
EOF

kubectl apply -n ${ENGINEPLUS_NAMESPACE} -f ${DIR}/templates/spark-configmap.yaml --validate=false

if [[ $? -ne 0 ]]; then
  exit 255
fi

cat <<EOF >$DIR/templates/spark-service.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ${ENGINEPLUS_SPARK_SERVICEACCOUNT}
  namespace: ${ENGINEPLUS_NAMESPACE}
  annotations:
    eks.amazonaws.com/role-arn: "${ENGINEPLUS_ROLE_ARN}"

---

apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: ${ENGINEPLUS_NAMESPACE}
  name: ${ENGINEPLUS_SPARK_SERVICEACCOUNT}-role
rules:
  - apiGroups: [""]
    resources: ["pods", "services", "configmaps"]
    verbs: ["*"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: ${ENGINEPLUS_SPARK_SERVICEACCOUNT}-role-binding
  namespace: ${ENGINEPLUS_NAMESPACE}
subjects:
  - kind: ServiceAccount
    name: ${ENGINEPLUS_SPARK_SERVICEACCOUNT}
    namespace: ${ENGINEPLUS_NAMESPACE}
roleRef:
  kind: Role
  name: spark-role
  apiGroup: rbac.authorization.k8s.io
EOF

kubectl apply -n ${ENGINEPLUS_NAMESPACE} -f ${DIR}/templates/spark-service.yaml --validate=false

if [[ $? -ne 0 ]]; then
  exit 255
fi

rm -rf $DIR/templates

rm -rf ${DIR}/temp
