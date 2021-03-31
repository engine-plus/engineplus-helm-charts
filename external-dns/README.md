# EnginePlus external-dns QuickStart
When you need to install external-dns by engineplus-helm-charts, you can follow these steps:

## 1. Prepare IAM role policy

If you need update ingress route records by external dns, you need add the followling policy, please replace `YOUR_HOST_ZONE_ID`(Id of your hosted zone in AWS. You can find this information in the AWS console (Route53))

- Add IAM Policy

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "route53:ChangeResourceRecordSets"
            ],
            "Resource": [
                "arn:aws:route53:::hostedzone/YOUR_HOST_ZONE_ID"
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
- Add Trust Trust Relation
```json
{
  "Version": "2012-10-17",
  "Statement": [
    //The original policy , please hold this
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    },
    //Add IAM Trust RelationShip of default:external-dns (namespace:serviceaccount), please replace CLUSTER_OIDC_ID
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::<ACCOUNT_NUMBER>:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/<CLUSTER_OIDC_ID>"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "oidc.eks.<REGION>.amazonaws.com/id/<CLUSTER_OIDC_ID>:sub": "system:serviceaccount:default:external-dns"
        }
      }
    }
  ]
}

```
## 2. Helm external-dns Install

```bash
# please use your own values in (ENGINEPLUS_INGRESS_HOST,ENGINEPLUS_HOST_ZONE,ENGINEPLUS_ROLE_ARN)
# ENGINEPLUS_INGRESS_HOST: something like "example.com"
# ENGINEPLUS_HOST_ZONE: id of your hosted zone in AWS. You can find this information in the AWS console (Route53)
# ENGINEPLUS_ROLE_ARN: something like "arn:aws:iam::<YOUR_ACCOUNT_ID>:role/<YOUR_ROLE_NAME>"

# For Example:
ENGINEPLUS_INGRESS_HOST="example.com"
ENGINEPLUS_HOST_ZONE="Z0067429XXXXXXXXXQT7JPN"
ENGINEPLUS_ROLE_ARN="arn:aws:iam::<ACCOUNT_NUMBER>:role/<YOUR_ROLE_NAME>"

helm install  external-dns ./external-dns \
--set provider=aws \
--set domainFilters[0]=${ENGINEPLUS_INGRESS_HOST} \
--set policy=upsert-only \
--set registry=txt \
--set txtOwnerId=${ENGINEPLUS_HOST_ZONE} \
--set interval=1m \
--set serviceAccount.create=true \
--set serviceAccount.name=external-dns \
--set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=${ENGINEPLUS_ROLE_ARN}
```
## 2. Uninstall

```bash
helm uninstall external-dns
```