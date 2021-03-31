# EnginePlus kube-prometheus-stack QuickStart

Before we install the prometheues stack , you should know we add our custom spark-mointor-dashboard in `engineplus-helm-charts/kube-prometheus-stack/charts/grafana/dashboards/spark-monitor-dashboard.json `, if you have installed prometheues stack, your can import the json called `spark-monitor-dashboard.json` to your grafana directly.

When you need to install spark history server by engineplus-helm-charts, you can follow these steps:

## 1. prometheus-stack Helm Install

```bash
kubectl create namespace monitoring
helm install prometheus-stack ./kube-prometheus-stack -n monitoring \
             --set grafana.enabled=true \ 
             --set grafana.adminPassword=${ENGINEPLUS_PASSWORD} \
             --set grafana.ingress=${ENGINEPLUS_INGRESS_ENABLED}   \
             --set grafana.ingress.hosts={grafana.${ENGINEPLUS_INGRESS_HOST}}

```
## 2. Uninstall

```shell
helm uninstall prometheus-stack -n monitoring
kubectl delete crd alertmanagerconfigs.monitoring.coreos.com
kubectl delete crd alertmanagers.monitoring.coreos.com
kubectl delete crd podmonitors.monitoring.coreos.com
kubectl delete crd probes.monitoring.coreos.com
kubectl delete crd prometheuses.monitoring.coreos.com
kubectl delete crd prometheusrules.monitoring.coreos.com
kubectl delete crd servicemonitors.monitoring.coreos.com
kubectl delete crd thanosrulers.monitoring.coreos.com
```
