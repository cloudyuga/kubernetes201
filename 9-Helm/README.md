- Install Helm 

```
$ curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > get_helm.sh
$ chmod 700 get_helm.sh
$ ./get_helm.sh
```

- Setup Tiller Service Account and Role Bindings

```
$ kubectl apply -f rbac-helm.yaml 
```

- Initialize Tiller
```
$ helm init --service-account tiller
```
