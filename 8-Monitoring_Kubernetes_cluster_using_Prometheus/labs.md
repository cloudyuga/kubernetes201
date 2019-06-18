
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
cat rbac_helm.yaml
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
kubectl apply -f configs/rbac_helm.yaml 
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
helm install --name prometheus --set rbac.create='true' --set server.service.type='NodePort' --set server.ingress.enabled='true',server.ingress.hosts={prometheus.cloudyuga.io} stable/prometheus
```

- Install Grafana

```command
helm install  --name grafana --set rbac.create='true' --set server.service.type='NodePort' --set server.ingress.enabled='true' --set server.service.nodePort=30500,server.ingress.hosts={grafana.cloudyuga.io} stable/grafana
```
