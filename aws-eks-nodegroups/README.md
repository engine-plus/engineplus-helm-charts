# Examples to create Spark node groups on AWS EKS

1. Get `eksctl` from [weaveworks/eksctl](https://github.com/weaveworks/eksctl) and follow the installation guide to get correct permissions.
1. Create a cluster or use an existing cluster with Kubenetes version at 1.18.
1. Modify `eks-cluster-nodes.yaml`
    1. Change cluster name, region, etc according to your EKS cluster
    1. Change VPCs, subnets you would like to use for Spark node groups
    1. Change the IAM Roles to create the nodes

    Note that in this example config, we choose to use AWS EC2 M5d.4xlarge which comes with a local SSD disk that provides fast disk IO. You can choose other EC2 instance types according to your needs.
1. Execute eksctl to create the two node groups:
    ```shell
    eksctl create nodegroup --config-file eks-cluster-nodes.yaml
    ```