# EnginePlus 2.0 Helm Charts

## Introduction

[EnginePlus 2.0](aws-market-place-link) is a cloud native big data analytics stack that can be easily deployed, operated and scaled on the cloud with a [Kubernetes(K8s)](https://github.com/kubernetes/kubernetes) cluster to suit your workload demand.

EnginePlus 2.0 includes the following compoments:
- Spark on K8S
- Spark history server on K8S
- Zeppelin on K8S
- Jupyter on K8S
- Airflow on K8S
- loki on K8S
- Prometheus on K8S
- Grafana on K8S
- Nginx ingress controller
- External dns

With all the components above, EnginePlus 2.0 provides unified big data analysis engine based on Apache Spark, code development environment with Zeppelin and Jupyter, job scheduling with Airflow, as well as logging, monitoring, DNS resolve, etc. Every component has been adapted to K8s environment with full autoscaling capability.

This project provides installation method for every component of EnginePlus 2.0 based on [Helm](https://helm.sh/) and step-by-step instructions. Users can choose to install all the components or just some of them.

## Prerequisites
1. A Kubernetes cluster. [AWS EKS](https://aws.amazon.com/eks/) has been throughly tested and therefore recommended. Kubenetes version 1.18 or above is required.
1. Container images of the components you need to install. The prebuilt [EnginePlus 2.0 Container Product on AWS Marketplace](aws-market-place-link) which includes all the component images is recommended. These prebuilt images have all the dependencies and execution environment inside, and help you handle the interaction with EKS, create necessary config maps and include many bug fixes for the opensource projects. Please make sure that you have the [right to subscribe the product](https://docs.aws.amazon.com/marketplace/latest/buyerguide/buyer-finding-and-subscribing-to-container-products.html).

## Prepare Your K8s(EKS) Cluster
1. Spark on K8s requires two extra node groups with node labels: `spark-applications-driver-nodes` and `spark-applications-nodes`. If you are using AWS EKS, you could use [eksctl](https://eksctl.io/) to create them following the steps: [create eks node groups](aws-eks-nodegroups).

1. Prepare a S3 bucket or a prefix of an existing S3 bucket.


## Prepare Required IAM Roles with Required Permissions

In this tutorial we will prepare an IAM role with an ID provider.

> EnginePlus needs permissions on S3, Route53(Optional) and Marketplace in EKS pods, thus, we need to use an identity provider in AWS IAM service. An identity provider allows an external user to assume roles in your AWS account by setting up a trust relationship. 

  ### 1. Create EKS Cluster OIDC Provider
  Before the step 1, please refer to [Create an IAM OIDC provider for your cluster](https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html).


  And you should provide these info when you create ID Provider:
  - Provider type 

    `OpenId Connect`
  - Audience

    `sts.amazonaws.com`

  - Provider URL

    To get your provider url you can use the following command:
    ```console
    aws eks describe-cluster --name <CLUSTER_NAME> --query "cluster.identity.oidc.issuer" --output text
    ```

  ### 2. Edit/Create IAM role
   Before the step 2, please refer to [Associate an IAM role to a service account](https://docs.aws.amazon.com/eks/latest/userguide/specify-service-account-role.html).
  - Edit/Create IAM role policy

    You need provide: 

    - YOUR_BUCKET_NAME
    - YOUR_HOST_ZONE_ID (If you need External-DNS)

  - Edit IAM role Trust RelationShip policy, to trust the EKS OIDC Provider we create.

    You need to provide:
    - ACCOUNT_NUMBER

      `your aws account id`

    - CLUSTER_OIDC_ID
    - REGION

    To get CLUSTER_OIDC_ID and REGION, you can execute the following command:

      ```console
      aws eks describe-cluster --name <cluster_name> --query "cluster.identity.oidc.issuer" --output text
      ```

      Example output:

      oidc.eks.`us-west-2`.amazonaws.com/id/`EXAMPLED539D4633E53DE1B716D3041E`
      
      |REGION|CLUSTER_OIDC_ID|
      |-----------|--------------|
      | us-west-2|EXAMPLED539D4633E53DE1B716D3041E|
   
  Then you can add IAM policy as follows :

  **Notice: Please replace all of the placeholders with correct values**

  ```json
  {
      "Version": "2012-10-17",
      "Statement": [
          {
              "Effect": "Allow",
              "Action": "s3:*",
              "Resource": "arn:aws:s3:::<YOUR_BUCKET_NAME>/*"
          },
          {
              "Action": [
                  "aws-marketplace:MeterUsage"
              ],
              "Effect": "Allow",
              "Resource": "*"
          },
          {
              "Effect": "Allow",
              "Action": [
                  "route53:ChangeResourceRecordSets"
              ],
              "Resource": [
                  "arn:aws:route53:::hostedzone/<YOUR_HOST_ZONE_ID>"
              ]
          },
          {
              "Effect": "Allow",
              "Action": [
                  "route53:ListHostedZones",
                  "route53:ListResourceRecordSets"
              ],
              "Resource": [
                  "*"
              ]
          }
      ]
  }
  ```

After new IAM policy added, IAM Trust RelationShip of engineplus:spark (namespace:serviceaccount) needs to be configured as the following example.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    },
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::<ACCOUNT_NUMBER>:oidc-provider/oidc.eks.<REGION>.amazonaws.com/id/<CLUSTER_OIDC_ID>"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "oidc.eks.<REGION>.amazonaws.com/id/<CLUSTER_OIDC_ID>:sub": "system:serviceaccount:engineplus:spark"
        }
      }
    }
  ]
}
```

## Deploy EnginePlus Components

You can choose to [install optional](#optional-components) components by our charts before installing required Components. And you only need to execute [install_all.sh](install_all.sh) to install all the required components.

### 1. Prepare environment variables

Before installing required components, a set of environment variables need to be defined. Replace place holders with appropriate values obtained from the above preparation steps.

```bash
# Public variables for all components 
# Please use your own values to replace the placeholders
ENGINEPLUS_REPO_PREFIX="<SUBSCRIBED_IMAGE_REPO_URL>"
ENGINEPLUS_INGRESS_HOST=<example.com>
ENGINEPLUS_S3_PREFIX=s3://<xxxxx>/engineplus
ENGINEPLUS_ROLE_ARN=arn:aws:iam::<ACCOUNT-NUMBER>:role/<IAM-ROLE-NAME>

ENGINEPLUS_SPARK_SERVICEACCOUNT=spark
ENGINEPLUS_REPO_TAG=engineplus-2.0.1
ENGINEPLUS_NAMESPACE=engineplus
ENGINEPLUS_INGRESS_ENABLED=true
# generate random password to login zeppelin/airflow/jupyter/spark-history-server/spark ui 
# default login user name is 'admin'
ENGINEPLUS_PASSWORD=`cat /dev/urandom | head -n 10 | md5sum | head -c 16`
# Required variables For Airflow && Jupyter. If you forget it, you can get it in airflow-env of Config Maps in kube-dashboard by typing "AIRFLOW__REST_API_PLUGIN__REST_API_PLUGIN_EXPECTED_HTTP_TOKEN"
ENGINEPLUS_AIRFLOW_REST_TOKEN=$(cat /dev/urandom | head -n 10 | md5sum | head -c 32)
ENGINEPLUS_JUPYTER_PROXY_SECRETTOKEN=$(cat /dev/urandom | head -n 10 | md5sum | head -c 32)
ENGINEPLUS_AIRFLOW_DB_RDS_MYSQL_HOST="<MySQL/RDS endpoint>"
ENGINEPLUS_AIRFLOW_DB_RDS_MYSQL_PORT="<MySQL port>"
ENGINEPLUS_AIRFLOW_DB_RDS_MYSQL_USER="<MySQL user name>"
ENGINEPLUS_AIRFLOW_DB_RDS_MYSQL_PASSWORD="<MySQL password>"
ENGINEPLUS_AIRFLOW_DB_RDS_MYSQL_DATEBASE="<MySQL database for Airflow>"
```

### 2. Execute Engineplus Install Shell

```shell
sh ./install_all.sh
```

This script would install all required components under default settings. This script will print ingress address for each component and admin password after finished.

### Customization

If you would like to customize the compoments, please refer to the compoment docs.

#### Optional Components

1. [Install Nginx Ingress Controller](ingress-nginx)
1. [Install External DNS](external-dns)
1. [Install loki && Promtail](loki)
1. [Install Prometheus && Grafana](kube-prometheus-stack)
> Note:  When your EKS cluster has installed the optional components, you can igore this step, and we
strongly recommend you can install ingress-nginx and external-dns in your EKS cluster before deploy Engineplus.

#### Required Components

1. [Install Spark History Server](spark-history-server)
1. [Install Zeppelin](zeppelin)
1. [Install Jupyter](jupyter)
1. [Install Airflow](airflow)

> Note: All compoents will be installed in enginelus namespace by default.


## Contact us for support

Feel free to open issue or send PR.

[EnginePlus Team Support Mail Group](mailto:engineplus-team@mobvista.com)

[![Gitter](https://badges.gitter.im/EnginePlusStack/community.svg)](https://gitter.im/EnginePlusStack/community?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)