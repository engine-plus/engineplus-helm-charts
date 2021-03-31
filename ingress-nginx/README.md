# EnginePlus ingress-nginx QuickStart
When you need to install ingress-nginx  by engineplus-helm-charts, you can follow these steps:

## 1. ingress-nginx Helm Install 

```shell
kubectl create namespace ingress-nginx
helm install ingress-nginx ./ingress-nginx \
     --namespace=ingress-nginx \
     --set controller.service.annotations."external-dns\.alpha\.kubernetes\.io/hostname"=${ENGINEPLUS_INGRESS_HOST}

```
## 2. Uninstall

```shell
helm uninstall ingress-nginx -n ingress-nginx
```
