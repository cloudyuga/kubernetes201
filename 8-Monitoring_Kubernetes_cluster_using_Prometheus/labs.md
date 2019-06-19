
##  Setup Helm Package Manager for Kubernetes

`Helm` helps you manage Kubernetes applications. Helm Charts helps you define, install, and upgrade even the most complex Kubernetes application.Charts are easy to create, version, share, and publish.
The latest version of Helm is maintained by the CNCF in collaboration with Microsoft, Google, Bitnami and the Helm contributor community.

### Install Helm binaries.

- Download Helm installation script. Change the permission of the script and execute the script using following commands.

```command
curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > get_helm.sh
chmod 700 get_helm.sh
./get_helm.sh
```

- Lets create Service account `tiller` and RBAC rule for `tiller` service account.

**Service Accounts**
Kubernetes enables access control for workloads by providing [Service Accounts](https://kubernetes.io/docs/reference/access-authn-authz/service-accounts-admin/). A service account represents an identity for processes that run in a pod. When a process is authenticated through a service account, it can contact the API server and access cluster resources. If a pod doesn’t have an assigned service account, it gets the default service account. 

```command
cat configs/rbac-helm.yaml
```
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: tiller
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: tiller
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
  - kind: ServiceAccount
    name: tiller
    namespace: kube-system

  - kind: User
    name: "admin"
    apiGroup: rbac.authorization.k8s.io

  - kind: User
    name: "kubelet"
    apiGroup: rbac.authorization.k8s.io

  - kind: Group
    name: system:serviceaccounts
    apiGroup: rbac.authorization.k8s.io
```

- Deploy above configuration.

```command
kubectl apply -f configs/rbac-helm.yaml
```

This will create `tiller` Service Account and it also create a clusterrole and bind this clusterrole to created ServiceAccount. 

In Kubernetes RBAC API, a role contains rules that represent a set of permissions.  A role can be defined within a namespace  or cluster-wide. A `Role` can only be used to grant access to resources within a single namespace. While `ClusterRole` can be used to grant the same permissions as a Role, but they are cluster-scoped. `ClusterRole` can al be used to grant access to `cluster-scoped resources like Nodes` and `namespaced resources like pods`. In this RBAC file, we are granting `cluster-admin` access to `tiller`.

- Initialize the Helm.

```command
helm init --service-account tiller 
```
```output
Creating /home/root/.helm 
Creating /home/root/.helm/repository 
Creating /home/root/.helm/repository/cache 
Creating /home/root/.helm/repository/local 
Creating /home/root/.helm/plugins 
Creating /home/root/.helm/starters 
Creating /home/root/.helm/cache/archive 
Creating /home/root/.helm/repository/repositories.yaml 
Adding stable repo with URL: https://kubernetes-charts.storage.googleapis.com 
Adding local repo with URL: http://127.0.0.1:8879/charts 
$HELM_HOME has been configured at /home/root/.helm.
Tiller (the Helm server-side component) has been installed into your Kubernetes Cluster.
Happy Helming!
```
This will create `.helm` default repository for helm in your `$HOME` directory. It will configure default `Helm Stable Chart Repository` at `https://kubernetes-charts.storage.googleapis.com`. It also configure Local Helm repo at `http://127.0.0.1:8879/charts `


- Verify tiller pod is running in the `kube-system` namespace.

```command
kubectl --namespace kube-system get pods | grep tiller
```

## Architecture and working of Prometheus.

- Prometheus generally work with technique of scraping or pulling the data from the applications. The time-series data of application is often exposed as HTTP endpoint via exporter( client-libraries or proxies).
- Sometime time-series data cannot be pulled if the application or targets in such a condition Prometheus may have the `Push gateway` to receive small volumes of data.
-  An endpoint usually corresponds to a single process, host, service, or application. To scrape data from an endpoint, Prometheus defines configuration(how to connect endpoint, authentications required to connect endpoints etc) called a target.
- Groups of targets with the same role are called as Job.
- Time series data is stored locally on the Prometheus server or it can be shipped to external storage.
- Prometheus queries the time-series data and it will also aggregate time-series data. With aggregation it can create new time-series data from existing time-series data.
- Prometheus doesn't come with inbuilt alerting system, you have to configure external alertmanager server for sending you the alert about monitoring.
- PromQL is prometheus in built query language which process time-series data and extract out the required information.
- For faster querying, we should use faster data storage(SSDs), so data can processed faster.
- We can run prometheus server as HA mode.
-  Prometheus collects time series data. To handle this data it has a multi-dimensional time series data model. The time series data model combines time series names and key/value pairs called labels; these labels provide the dimensions. Each time series is uniquely identified by the combination of time series name and any assigned labels.


![](https://prometheus.io/assets/architecture.png)


### Demo.

#### Prerequisites : Helm must be installed and tiller pod must be running in your kubernetes cluster.
                                                                                                        

- Install Prometheus

```command
helm install --name prometheus \
--set server.service.type=NodePort,pushgateway.persistentVolume.enabled=false,server.persistentVolume.enabled=false,alertmanager.persistentVolume.enabled=false  \
stable/prometheus
```

- Get the list of the Pods.

```command
kubectl get pods
```
```
prometheus-alertmanager-5ddc7cbfd4-8gqgg         2/2     Running   0          20m
prometheus-kube-state-metrics-848699f4d6-68rrd   1/1     Running   0          20m
prometheus-node-exporter-58b7z                   1/1     Running   0          20m
prometheus-pushgateway-56cd66b4bd-4x5fj          1/1     Running   0          20m
prometheus-server-647bd99bcd-tqlcw               2/2     Running   0          20m
```
- Get the list of the services.

```command
kubectl get svc
```
```output
prometheus-alertmanager         ClusterIP   10.245.80.251   <none>        80/TCP         21m
prometheus-kube-state-metrics   ClusterIP   None            <none>        80/TCP         21m
prometheus-node-exporter        ClusterIP   None            <none>        9100/TCP       21m
prometheus-pushgateway          ClusterIP   10.245.211.75   <none>        9091/TCP       21m
prometheus-server               NodePort    10.245.70.23    <none>        80:31748/TCP   21m
```

Now try to access the Prometheus UI by using NodePort shown above. In Prometheus UI if go to the `Status`-> `Rule`, You see `No rules defined`. Similarly, in Prometheus UI if go to `Alert` you can see `No alerting rules defined`.

Let's configure `Record Rules` and `Alert Rules`.

- Get the  [values.yaml](https://raw.githubusercontent.com/helm/charts/master/stable/prometheus/values.yaml) and modifiy as below.

- In `values.yaml` find the section of `alertmanagerFiles` and update as below.

```yaml
.
.
.
.
## alertmanager ConfigMap entries
##
alertmanagerFiles:
  alertmanager.yml:
    global: {}
    global:
      smtp_smarthost: 'smtp.gmail.com:587'
      smtp_from: 'sender@cloudyuga.guru'
    templates:
    - '/etc/alertmanager/template/*.tmpl'
    route:
      receiver: email
    receivers:
    - name: 'email'
      email_configs:
      - to: 'reciever@cloudyuga.guru'
        from: "sender@cloudyuga.guru"
        smarthost: smtp.gmail.com:587
        auth_username: "sender@cloudyuga.guru"
        auth_identity: "sender@cloudyuga.guru"
        auth_password: "************"
.
.
.
.
.
.
```

Update SMTP Host, the Sender and reciever Email-ID. Update authentication for sender. 

- Configure the `Alert Rule` in `values.yaml`, Find a `serverFiles:` section and update with your alert rules in `alerts` section. For example take a look at the following configuration

```yaml
.
.
.
.
## Prometheus server ConfigMap entries
##
serverFiles:

  ## Alerts configuration
  ## Ref: https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/
  alerts: 
    groups:
      - name: k8s_alerts
        rules:
        - alert: MoreThan30Deployments
          expr: count(kube_deployment_created) >= 30
          for: 2m
          labels:
            severity: critical
          annotations:
            summary: Hey Admin!!!!! More Than 30 Deployments are running in cluster
      - name: node_alerts
        rules:
        - alert: HighNodeCPU
          expr: instance:node_cpu:avg_rate5m > 20
          for: 10s
          labels:
            severity: warning
          annotations:
            summary: High Node CPU of {{ humanize $value}}% for 1 hour
.
.
.
.
.
```

- Configure the `Record Rule` in `values.yaml`, Find a `serverFiles:` section and update with your record rules in `rules` section. For example it will look like the following configuration

```yaml
.
.
.
serverFiles:

  ## Alerts configuration
  ## Ref: https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/
  alerts: 
    groups:
      - name: k8s_alerts
        rules:
        - alert: MoreThan30Deployments
          expr: count(kube_deployment_created) >= 30
          for: 2m
          labels:
            severity: critical
          annotations:
            summary: Hey Admin!!!!! More Than 30 Deployments are running in cluster
      - name: node_alerts
        rules:
        - alert: HighNodeCPU
          expr: instance:node_cpu:avg_rate5m > 20
          for: 10s
          labels:
            severity: warning
          annotations:
            summary: High Node CPU of {{ humanize $value}}% for 1 hour

  rules: 
    groups:
      - name: kubernetes_rules
        rules:
        - record: apiserver_latency_seconds:quantile
          expr: histogram_quantile(0.99, rate(apiserver_request_latencies_bucket[5m])) / 1e+06
          labels:
            quantile: "0.99"
        - record: apiserver_latency_seconds:quantile
          expr: histogram_quantile(0.9, rate(apiserver_request_latencies_bucket[5m])) / 1e+06
          labels:
            quantile: "0.9"
        - record: apiserver_latency_seconds:quantile
          expr: histogram_quantile(0.5, rate(apiserver_request_latencies_bucket[5m])) / 1e+06
          labels:
            quantile: "0.5"
      - name: node_rules
        rules:
        - record: instance:node_cpu:avg_rate5m
          expr: 100 - avg (irate(node_cpu_seconds_total{mode="idle"}[5m])) by (instance) * 100
        - record: instance:node_memory_usage:percentage
          expr: (node_memory_MemTotal_bytes - (node_memory_MemFree + node_memory_Cached_bytes + node_memory_Buffers_bytes)) / node_memory_MemTotal_bytes * 100
        - record: instance:root:node_filesystem_usage:percentage
          expr: (node_filesystem_size_bytes{mountpoint="/"} - node_filesystem_free_bytes{mountpoint="/"}) / node_filesystem_size_bytes{mountpoint="/"}* 100
      - name: k8s_rules
        rules:
        - record: k8s:service:count
          expr: count(kube_service_created)
        - record: k8s:pod:count
          expr: count(kube_pod_created)
        - record: k8s:deploy:count
          expr: count(kube_deployment_created)
        - record: k8s:clusterrole:count
          expr: etcd_object_counts{job="kubernetes-apiservers",resource="clusterroles.rbac.authorization.k8s.io"}
        - record: k8s:serviceaccount:count
          expr: etcd_object_counts{job="kubernetes-apiservers",resource="serviceaccounts"}	

  prometheus.yml:
    rule_files:
      - /etc/config/rules
      - /etc/config/alerts

    scrape_configs:
      - job_name: prometheus
        static_configs:
          - targets:
            - localhost:9090        
```

Once you update the `values.yaml` Lets now upgrade the Helm chart.

- Upgrade the Helm release.

```command
helm upgrade prometheus --set server.service.type=NodePort stable/prometheus -f configs/values.yaml
```

Once you upgrade the Helm release. Access the Prometheus UI. In Prometheus UI if go to the `Status`-> `Rule`, You see new rules we have configure earlier are present there. Similarly, in Prometheus UI if you go to `Alert`, you can see that Alert rules are present there.


### Install Grafana using helm


- Install Grafana

```command
helm install  --name grafana \
 --set service.type=NodePort  \
 stable/grafana
```



## Clean UP.

- Remove the Helm release and all its components.

```command
helm del --purge prometheus
```
- remove Grafana and its components.

```command
helm del ---purge  grafana

```
