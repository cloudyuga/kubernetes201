# Role Based Access Control 

## Slides
<iframe src="https://docs.google.com/presentation/d/e/2PACX-1vQ7Vx9ZNTZxM-_K1HXhnpR78CEwsBSltMObYNjaRdQ1N56XZzaN7G4OPHAi02ZM65f9cMCEd3eQLg51/embed?start=false&loop=false&delayms=3000" frameborder="0" width="960" height="569" allowfullscreen="true" mozallowfullscreen="true" webkitallowfullscreen="true"></iframe>

## Labs

### Role.

Lets define some Roles within the `cloudyuga` namespace.

```yaml
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  namespace: cloudyuga
  name: deployment-manager
rules:
- apiGroups: ["", "apps"]
  resources: ["deployments", "replicasets", "pods"]
  verbs: ["get", "list", "watch", "create", "update"]
```

In this yaml file we are creating the rule that allows a user to execute several operations on Deployments, Pods and ReplicaSets, which belong to the core (expressed by "" in the yaml file), apps, and extensions API Group.

### Lets deploy the Role which are defined in above configuration file.

```command
kubectl apply -f configs/1-role.yaml 
```

### Role Bindings 

Lets Bind this roles to the user `cloudyuga`.

```yaml
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: deployment-manager-binding
  namespace: cloudyuga
subjects:
- kind: User
  name: cloudyuga
  apiGroup: "rbac.authorization.k8s.io"  
roleRef:
  kind: Role
  name: deployment-manager
  apiGroup: "rbac.authorization.k8s.io"
```
In this file, we are binding the deployment-manager Role to the User Account `cloudyuga` inside the `cloudyuga` namespace

### Deploy the Role binding from above file.

```command
kubectl apply -f configs/2-rolebinding.yaml 
```

### When we have successfuly deployed the Role and Role-binding then execute the following commands.

```command
kubectl --context=cloudyuga-context run nginx --image=nginx:1.9.1
```

```command
kubectl --context=cloudyuga-context get pods
```
```
NAME                     READY     STATUS    RESTARTS   AGE
nginx-1530578888-fzv1n   1/1       Running   0          45s
```
Now, we can access the pods deployed within namespace `cloudyuga`.

If we run the same command with the `--namespace=default` argument, it will fail, as the `cloudyuga` user does not have access to this namespace.

```command
kubectl --context=cloudyuga-context get pods --namespace=default
```
```
Error from server (Forbidden): User "cloudyuga" cannot list pods in the namespace "default". (get pods)
```


### Cluster Role

Lets define the Cluster Role as shown in following configuration file.

```yaml
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: deployment-manager-cluster
rules:
- apiGroups: ["", "apps"]
  resources: ["deployments", "replicasets", "pods"]
  verbs: ["get", "list", "watch", "create", "update"]
```

- Deploy this Cluster Role.

```command
kubectl apply -f configs/3-cluster-role.yaml
```

### Cluster Role Bindings.

- Lets bind above created `cluster-manager` Cluster Role to user `cloudyuga`.

```yaml
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: cluster-manager-binding
subjects:
- kind: User
  name: cloudyuga
  apiGroup: "rbac.authorization.k8s.io"
roleRef:
  kind: ClusterRole
  name: deployment-manager-cluster
  apiGroup: "rbac.authorization.k8s.io"
```

### Deploy this Cluster Role Binding.

```command
kubectl apply -f configs/4-clusterrole-binding.yaml 
```

### If we run the same command with the `--namespace=default argument`, it will get output as we have configured the permissions for user `cloudyuga` for all the namespaces available in the cluster. 

```command
kubectl run nginx --image=nginx:1.9.1
```

```command
kubectl --context=cloudyuga-context get pods --namespace=default
```
```
NAME                     READY     STATUS    RESTARTS   AGE
nginx-1530578888-948kp   1/1       Running   0          3s
```


