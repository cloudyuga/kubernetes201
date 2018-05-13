- Install Prometheus
```
$    helm install --name prometheus --set rbac.create='true' --set server.service.type='NodePort' --set server.ingress.enabled='true',server.ingress.hosts={prometheus.cloudyuga.io} stable/prometheus
```

- Install Grafana
```
$  helm install  --name grafana --set rbac.create='true' --set server.service.type='NodePort' --set server.ingress.enabled='true' --set server.service.nodePort=30500,server.ingress.hosts={grafana.cloudyuga.io} stable/grafana
```
