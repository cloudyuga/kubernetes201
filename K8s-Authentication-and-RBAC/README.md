
# Kubernetes Authentication process and Role Based Access Control 

## RBAC
Role-Based Access Control (`RBAC`),  policies are important for the proper management of your cluster, RBAC policies allow you to specify which types of actions are permitted depending on the user and their role in your organization.
For e.g.
- Secure your cluster by granting privileged operations (accessing secrets, for example) only to admin users.
- Force user authentication in your cluster.

Lets get familier with following terms.
- Rules: A rule is a set of operations (verbs) that can be carried out on a group of resources which belong to different API Groups.
- Roles :  In a Role, the rules are applicable to a single namespace.
- ClusterRoles: In a ClusterRole is cluster-wide, so the rules are applicable to more than one namespace. 


## Minikube [Only for minikube]

- Download the required `minikube` binary from this [link](https://github.com/kubernetes/minikube/releases/tag/v0.24.0).

- Start the Minikube with following option.
```
$ minikube start --extra-config=apiserver.Authorization.Mode=RBAC --extra-config=controller-manager.ClusterSigningCertFile="/root/.minikube/ca.crt" --extra-config=controller-manager.ClusterSigningKeyFile="/root/.minikube/ca.key"
```

## Create kubectl configuration files.
Before Demonstrate To Role and ClusterRole. We have to carry out following tasks.


- Create a new directory.
```
$ mkdir -p ~/rbac
$ cd ~/rbac
```

- Crete new Namespace `cloudyuga`.
```
$ kubectl create namespace cloudyuga
namespace "cloudyuga" created
```

- Create Private Key for user named `nkhare`.
```
$ openssl genrsa -out nkhare.key 2048
Generating RSA private key, 2048 bit long modulus
............................................+++
............................+++
e is 65537 (0x10001)
```

- Create a certificate sign request `nkhare.csr` using the private key you just have created.In following command CN is for the username and O for the group.
```
$ openssl req -new -key nkhare.key -out nkhare.csr -subj "/CN=nkhare/O=cloudyuga"

```

- Generate the final certificate nkhare.crt by approving the certificate sign request, nkhare.csr.
```
$ openssl x509 -req -in nkhare.csr -CA /etc/kubernetes/pki/ca.crt \
-CAkey /etc/kubernetes/pki/ca.key \
-CAcreateserial -out nkhare.crt -days 500

```

- Add a new context with the new credentials for your Kubernetes cluster.
```
$ kubectl config set-credentials nkhare --client-certificate=/root/rbac/nkhare.crt \
--client-key=/root/rbac/nkhare.key

$ kubectl config set-context nkhare-context --cluster=kubernetes \
--namespace=cloudyuga --user=nkhare
```

- Try to get pod list with this above created context. You should get an access denied error when using the kubectl CLI with this configuration file. Because we have not described any roles or clusterrole for this user.
```
$ kubectl --context=nkhare-context get pods
Error from server (Forbidden): User "nkhare" cannot list pods in the namespace "cloudyuga". (get pods)
```
## Role Bindings 

- Lets define some Roles within the `cloudyuga` namespace.
```
  kind: Role
  apiVersion: rbac.authorization.k8s.io/v1beta1
  metadata:
    namespace: cloudyuga
    name: deployment-manager
  rules:
  - apiGroups: ["", "extensions", "apps"]
    resources: ["deployments", "replicasets", "pods"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
```
In this yaml file we are creating the rule that allows a user to execute several operations on Deployments, Pods and ReplicaSets, which belong to the core (expressed by "" in the yaml file), apps, and extensions API Group.

- Lets deploy the Role which are defined in above configuration file.
```
$ kubectl create -f role.yaml 
role "deployment-manager" created
```


- Lets Bind this roles to the user `nkhare`.
```
  kind: RoleBinding
  apiVersion: rbac.authorization.k8s.io/v1beta1
  metadata:
    name: deployment-manager-binding
    namespace: cloudyuga
  subjects:
  - kind: User
    name: nkhare
    apiGroup: ""
  roleRef:
    kind: Role
    name: deployment-manager
    apiGroup: ""
```
In this file, we are binding the deployment-manager Role to the User Account `nkhare` inside the `cloudyuga` namespace

- Deploy the Role binding from above file.
```
$  kubectl create -f rolebinding.yaml 
rolebinding "deployment-manager-binding" created
```

- When we have successfuly deployed the Role and Role-binding then execute the following commands.
```
$ kubectl --context=nkhare-context run nginx --image=nginx:1.9.1
deployment "nginx" created

$ kubectl --context=nkhare-context get pods
NAME                     READY     STATUS    RESTARTS   AGE
nginx-1530578888-fzv1n   1/1       Running   0          45s
```
Now, we can access the pods deployed within namespace `cloudyuga`.

If we run the same command with the `--namespace=default` argument, it will fail, as the `nkhare` user does not have access to this namespace.

```
$ kubectl --context=nkhare-context get pods --namespace=default
Error from server (Forbidden): User "nkhare" cannot list pods in the namespace "default". (get pods)
```
## Cluster Role Bindings.

- Lets define the Cluster Role as shown in following configuration file.
```
  kind: ClusterRole
  apiVersion: rbac.authorization.k8s.io/v1beta1
  metadata:
    name: cluster-manager
  rules:
  - apiGroups: ["", "extensions", "apps"]
    resources: ["deployments", "replicasets", "pods"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
```

- Deploy this Cluster Role.
```
$ kubectl create -f cluster-role.yaml
clusterrole "cluster-manager" created
```

- Lets bind above created `cluster-manager` Cluster Role to user `nkhare`.
```
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: cluster-manager-binding
subjects:
- kind: User
  name: nkhare # This allow manager to read any secrete present in all the namespaces
  apiGroup: ""
roleRef:
  kind: ClusterRole
  name: cluster-manager
  apiGroup: ""
```

- Deploy this Cluster Role Binding.
```
$ kubectl create -f clusterrole-binding.yaml 
clusterrolebinding "cluster-manager-binding" created
```

- If we run the same command with the `--namespace=default argument`, it will get output as we have configured the permissions for user `nkhare` for all the namespaces available in the cluster. 
```
$ kubectl run nginx --image=nginx:1.9.1
deployment "nginx" created

$ kubectl --context=nkhare-context get pods --namespace=default
NAME                     READY     STATUS    RESTARTS   AGE
nginx-1530578888-948kp   1/1       Running   0          3s

```



# Minikube

- Download the required `minikube` binary from this [link](https://github.com/kubernetes/minikube/releases/tag/v0.24.0).

- Start the Minikube with following option.
```
$ minikube start --extra-config=apiserver.Authorization.Mode=RBAC --extra-config=controller-manager.ClusterSigningCertFile="/root/.minikube/ca.crt" --extra-config=controller-manager.ClusterSigningKeyFile="/root/.minikube/ca.key"
```

Create a new directory.
```
$ mkdir -p ~/rbac
$ cd ~/rbac
```

Crete new Namespace `cloudyuga`.
```
$ kubectl create namespace cloudyuga
namespace "cloudyuga" created
```

Create Private Key for user named `nkhare`.
```
$ openssl genrsa -out nkhare.key 2048
Generating RSA private key, 2048 bit long modulus
............................................+++
............................+++
e is 65537 (0x10001)
```

Create a certificate sign request `nkhare.csr` using the private key you just have created.In following command CN is for the username and O for the group.
```
$ openssl req -new -key nkhare.key -out nkhare.csr -subj "/CN=nkhare/O=cloudyuga"

```

Generate the final certificate nkhare.crt by approving the certificate sign request, nkhare.csr.
```
$ openssl x509 -req -in nkhare.csr -CA /root/.minikube/ca.crt \
-CAkey /root/.minikube/ca.key \
-CAcreateserial -out nkhare.crt -days 500

```

Add a new context with the new credentials for your Kubernetes cluster.
```
$ kubectl config set-credentials nkhare --client-certificate=/root/rbac/nkhare.crt \
--client-key=/root/rbac/nkhare.key

$ kubectl config set-context nkhare-context --cluster=minikube \
--namespace=cloudyuga --user=nkhare
```

Try to get pod list with this above created context. You should get an access denied error when using the kubectl CLI with this configuration file. Because we have not described any roles or clusterrole for this user.
```
$ kubectl --context=nkhare-context get pods
Error from server (Forbidden): User "nkhare" cannot list pods in the namespace "cloudyuga". (get pods)
```
## Role.

Lets define some Roles within the `cloudyuga` namespace.
```
  kind: Role
  apiVersion: rbac.authorization.k8s.io/v1beta1
  metadata:
    namespace: cloudyuga
    name: deployment-manager
  rules:
  - apiGroups: ["", "extensions", "apps"]
    resources: ["deployments", "replicasets", "pods"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
```
In this yaml file we are creating the rule that allows a user to execute several operations on Deployments, Pods and ReplicaSets, which belong to the core (expressed by "" in the yaml file), apps, and extensions API Group.

Lets deploy the Role which are defined in above configuration file.
```
$ kubectl create -f role.yaml 
role "deployment-manager" created
```
## Role Bindings 

Lets Bind this roles to the user `nkhare`.
```
  kind: RoleBinding
  apiVersion: rbac.authorization.k8s.io/v1beta1
  metadata:
    name: deployment-manager-binding
    namespace: cloudyuga
  subjects:
  - kind: User
    name: nkhare
    apiGroup: ""
  roleRef:
    kind: Role
    name: deployment-manager
    apiGroup: ""
```
In this file, we are binding the deployment-manager Role to the User Account `nkhare` inside the `cloudyuga` namespace

Deploy the Role binding from above file.
```
$  kubectl create -f rolebinding.yaml 
rolebinding "deployment-manager-binding" created
```
When we have successfuly deployed the Role and Role-binding then execute the following commands.
```
$ kubectl --context=nkhare-context run nginx --image=nginx:alpine
deployment "nginx" created

$ kubectl --context=nkhare-context get pods
NAME                    READY     STATUS    RESTARTS   AGE
nginx-5bd976694-ln6ps   1/1       Running   0          17s
```
Now, we can access the pods deployed within namespace `cloudyuga`.

If we run the same command with the `--namespace=default` argument, it will fail, as the `nkhare` user does not have access to this namespace.

```
$ kubectl --context=nkhare-context get pods --namespace=default
Error from server (Forbidden): User "nkhare" cannot list pods in the namespace "default". (get pods)
```
## Cluster Role

Lets define the Cluster Role as shown in following configuration file.
```
  kind: ClusterRole
  apiVersion: rbac.authorization.k8s.io/v1beta1
  metadata:
    name: cluster-manager
  rules:
  - apiGroups: ["", "extensions", "apps"]
    resources: ["deployments", "replicasets", "pods"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
```
Deploy this Cluster Role.
```
$ kubectl create -f cluster-role.yaml
clusterrole "cluster-manager" created
```
## Cluster Role Bindings.

Lets bind above created `cluster-manager` Cluster Role to user `nkhare`.
```
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: cluster-manager-binding
subjects:
- kind: User
  name: nkhare # This allow manager to read any secrete present in all the namespaces
  apiGroup: ""
roleRef:
  kind: ClusterRole
  name: cluster-manager
  apiGroup: ""
```

Deploy this Cluster Role Binding.
```
$ kubectl create -f clusterrole-binding.yaml 
clusterrolebinding "cluster-manager-binding" created
```

If we run the same command with the `--namespace=default argument`, it will get output as we have configured the permissions for user `nkhare` for all the namespaces available in the cluster. 
```
$ kubectl run nginx --image=nginx:1.9.1
deployment "nginx" created

$ kubectl --context=nkhare-context get pods --namespace=default
NAME                    READY     STATUS              RESTARTS   AGE
nginx-cfc4fd5c6-bmtkj   0/1       ContainerCreating   0          8s
```

## Kubernetes Authentication using CSR.

### Minikube [Only for Minikube]

- Now start the `minikube` with following options.
```
$ minikube start --extra-config=apiserver.Authorization.Mode=RBAC --extra-config=controller-manager.ClusterSigningCertFile="/var/lib/localkube/certs/ca.crt" --extra-config=controller-manager.ClusterSigningKeyFile="/var/lib/localkube/certs/ca.key"
```

### Generate the CSR and Key.
```
$ openssl genrsa -out cloudyuga.key 2048

$ openssl req -new -key cloudyuga.key -out cloudyuga.csr -subj "/CN=cloudyuga/O=cloudyuga"
```

- Encode the `cloudyuga.csr`.
```
$ cat cloudyuga.csr | base64 | tr -d '\n'

LS0tLS1CRUdJTiBDRVJUSUZJQ0FURSBSRVFVRVNULS0tLS0KTUlJQ2R6Q0NBVjhDQVFBd0ZERVNNQkFHQTFVRUF4TUpZMnh2ZFdSNWRXZGhNSUlCSWpBTkJna3Foa2lHOXcwQgpBUUVGQUFPQ0FROEFNSUlCQ2dLQ0FRRUFtN2N5allaRHlhR1ZZcUs4R2g1T0xYTkNCS0Q3RFgvaE1WL3hMWVF6CnpwREtHK0JUdlJYNU9GRzB0aThEOXgybG4zRTNRamFJUlR4VktZZ1hyb2xnU2VzTWtVQk8vMlB4a0oxWkNSbzUKNHdUenlTU3B1N253OStPdzRZS0lBS3pLRk9XSzR6UTVUYU4rWjJnOHNvVDNVdEJyZmhGRzQyMWpWN2hMcitraApaVGVUMFVEbzlzMFJSZlNpckhQYXRNaG4zNkEzc1djNUNhWDRQYjdPTzNSd3B6aGo5eFN0U2h0QTd3TlRqdFZvCmMrZTlkQnpOY25NU3V2MVRaOGE0d3lBbm55UWNhaUREMytNQUJpV21rTUd4WmJVdUxJS1o0OFhteEFWOTkwMDAKR1dEWWorTDBSTDdNRDVNL2hFdEVBM1BLTkE1bThRbGRzR2Nod1kvOEE3N29wd0lEQVFBQm9CNHdIQVlKS29aSQpodmNOQVFrT01ROHdEVEFMQmdOVkhSRUVCREFDZ2dBd0RRWUpLb1pJaHZjTkFRRUxCUUFEZ2dFQkFEZzY5dGppCk9Jb1VxaUhVZS9tbFBSZmtpWUtQamY2UDJqTmpGZlFmVmgvamRZeGFuMEh0Vy93eVBsN2U0U0FOZzMwS3o0VDEKdm4xTmZhSGNneTBXaWpnOVE1UExnc0R0azlRUCtRRmpPRWhFOHBDTXFpMjZGajNVeU81QUlsNXd6elhWV2FMdAppVzduMnplUXhoS3dMSVA4T3hXWmxWWE5tQnNMWStjNGxFRTJkd0VQVDg2Rkl3OHFtdFU5MFN6VkFORW90ZUVVCkorU0orVlRrMmlYTGZkT3dpSWMweTlLcnkraHMzSUtlQlN2cjBTamg1UWF0RHJ0bnM0cHJrd0UrdGJjZ2MxbnAKUWZBZ1dLb3dFbHVwWDFIZThLRjRhbzEzc0h0ZStvV3pxNC82ZHo1R2FQVkFTcG55b0xBVlJOZW44cHU0T3RUdAovUGhTcnJXRExiTGVXclU9Ci0tLS0tRU5EIENFUlRJRklDQVRFIFJFUVVFU1QtLS0tLQo=
```

### Generate the kubernetes Certificate Signing Request.

```
$ vim signingrequest.yaml

apiVersion: certificates.k8s.io/v1beta1
kind: CertificateSigningRequest
metadata:
  name: cloudyuga-csr
spec:
  groups:
  - system:authenticated
  request: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURSBSRVFVRVNULS0tLS0KTUlJQ2R6Q0NBVjhDQVFBd0ZERVNNQkFHQTFVRUF4TUpZMnh2ZFdSNWRXZGhNSUlCSWpBTkJna3Foa2lHOXcwQgpBUUVGQUFPQ0FROEFNSUlCQ2dLQ0FRRUFtN2N5allaRHlhR1ZZcUs4R2g1T0xYTkNCS0Q3RFgvaE1WL3hMWVF6CnpwREtHK0JUdlJYNU9GRzB0aThEOXgybG4zRTNRamFJUlR4VktZZ1hyb2xnU2VzTWtVQk8vMlB4a0oxWkNSbzUKNHdUenlTU3B1N253OStPdzRZS0lBS3pLRk9XSzR6UTVUYU4rWjJnOHNvVDNVdEJyZmhGRzQyMWpWN2hMcitraApaVGVUMFVEbzlzMFJSZlNpckhQYXRNaG4zNkEzc1djNUNhWDRQYjdPTzNSd3B6aGo5eFN0U2h0QTd3TlRqdFZvCmMrZTlkQnpOY25NU3V2MVRaOGE0d3lBbm55UWNhaUREMytNQUJpV21rTUd4WmJVdUxJS1o0OFhteEFWOTkwMDAKR1dEWWorTDBSTDdNRDVNL2hFdEVBM1BLTkE1bThRbGRzR2Nod1kvOEE3N29wd0lEQVFBQm9CNHdIQVlKS29aSQpodmNOQVFrT01ROHdEVEFMQmdOVkhSRUVCREFDZ2dBd0RRWUpLb1pJaHZjTkFRRUxCUUFEZ2dFQkFEZzY5dGppCk9Jb1VxaUhVZS9tbFBSZmtpWUtQamY2UDJqTmpGZlFmVmgvamRZeGFuMEh0Vy93eVBsN2U0U0FOZzMwS3o0VDEKdm4xTmZhSGNneTBXaWpnOVE1UExnc0R0azlRUCtRRmpPRWhFOHBDTXFpMjZGajNVeU81QUlsNXd6elhWV2FMdAppVzduMnplUXhoS3dMSVA4T3hXWmxWWE5tQnNMWStjNGxFRTJkd0VQVDg2Rkl3OHFtdFU5MFN6VkFORW90ZUVVCkorU0orVlRrMmlYTGZkT3dpSWMweTlLcnkraHMzSUtlQlN2cjBTamg1UWF0RHJ0bnM0cHJrd0UrdGJjZ2MxbnAKUWZBZ1dLb3dFbHVwWDFIZThLRjRhbzEzc0h0ZStvV3pxNC82ZHo1R2FQVkFTcG55b0xBVlJOZW44cHU0T3RUdAovUGhTcnJXRExiTGVXclU9Ci0tLS0tRU5EIENFUlRJRklDQVRFIFJFUVVFU1QtLS0tLQo=
  usages:
  - digital signature
  - key encipherment
  - client auth
```

- Create the CSR.
```
$ kubectl create -f signingrequest.yaml 
certificatesigningrequest "cloudyuga-csr" created
```

- List the CSR.
```
$ kubectl get csr
NAME                                                   AGE       REQUESTOR                                        CONDITION
cloudyuga-csr                                          44s       kubernetes-admin                                 Pending
node-csr-abvQ8DWMb_hi1HEJ3ADMKT2unLzErLaSQ9iRrDA3oVM   2h        system:bootstrap:842694                          Approved,Issued
```

- Approve the CSR.
```
$ kubectl certificate approve cloudyuga-csr
certificatesigningrequest "cloudyuga-csr" approved
```
### Create ClusterRole and ClusterRolebindings for user `cloudyuga`.

```
$ vi cloudyuga-rbac.yaml

kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: cloudyuga-crb
subjects:
- kind: User
  name: cloudyuga
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: cloudyuga-cr
  apiGroup: rbac.authorization.k8s.io
---
  kind: ClusterRole
  apiVersion: rbac.authorization.k8s.io/v1beta1
  metadata:
    name: cloudyuga-cr
  rules:
  - apiGroups: ["", "extensions", "apps"]
    resources: ["deployments", "replicasets", "pods"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]

```

- Deploy the cluster-role and cluster-role binding.
```
$ kubectl apply -f cloudyuga-rbac.yaml 
clusterrolebinding "cloudyuga-crb" created
clusterrole "cloudyuga-cr" created
```

- Lets download the certificate from the CSR.
```
$ kubectl get csr cloudyuga-csr -o jsonpath='{.status.certificate}' \
    | base64 -d > cloudyuga.crt

```

### Create new context for the user cloudyuga.
- Set the credentials for the user.
```
$ kubectl config set-credentials cloudyuga --client-certificate=cloudyuga.crt --client-key=cloudyuga.key 
User "cloudyuga" set.
```

- Set the context for user [For Kubernets cluster].
```
$ kubectl config set-context cloudyuga-context --cluster=kubernetes --namespace=cloudyuga --user=cloudyuga
User "cloudyuga" set.
```

- Set the context for user [MINIKUBE].
```
$ kubectl config set-context cloudyuga-context --cluster=minikube --namespace=cloudyuga --user=cloudyuga
User "cloudyuga" set.
```

### Test the user `cloudyuga`.

- List the pods running in the `cloudyuga` namespace.
```
$  kubectl --context=cloudyuga-context get po
NAME                     READY     STATUS    RESTARTS   AGE
nginx-56b8c64cb4-c7hvx   1/1       Running   0          2h
```

- List the pods running in the `default` namespace.
```
$ kubectl --context=cloudyuga-context get pod -n default
NAME                    READY     STATUS    RESTARTS   AGE
nginx-5bd976694-mpjvr   1/1       Running   0          54s
```
