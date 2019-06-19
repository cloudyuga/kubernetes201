
# Kubernetes Authentication process and Role Based Access Control 

## RBAC
Role-Based Access Control (`RBAC`),  policies are important for the proper management of your cluster, RBAC policies allow you to specify which types of actions are permitted depending on the user and their role in your organization.
For e.g.
- Secure your cluster by granting privileged operations (accessing secrets, for example) only to admin users.
- Force user authentication in your cluster.

Lets get familiar with following terms.
- Rules: A rule is a set of operations (verbs) that can be carried out on a group of resources which belong to different API Groups.
- Roles :  In a Role, the rules are applicable to a single namespace.
- ClusterRoles: In a ClusterRole is cluster-wide, so the rules are applicable to more than one namespace. 



### Generate the CSR and Key.

```command
openssl genrsa -out cloudyuga.key 2048
openssl req -new -key cloudyuga.key -out cloudyuga.csr -subj "/CN=cloudyuga/O=cloudyuga"
```

- Encode the `cloudyuga.csr`.

```command
cat cloudyuga.csr | base64 | tr -d '\n'
```
```

LS0tLS1CRUdJTiBDRVJUSUZJQ0FURSBSRVFVRVNULS0tLS0KTUlJQ2R6Q0NBVjhDQVFBd0ZERVNNQkFHQTFVRUF4TUpZMnh2ZFdSNWRXZGhNSUlCSWpBTkJna3Foa2lHOXcwQgpBUUVGQUFPQ0FROEFNSUlCQ2dLQ0FRRUFtN2N5allaRHlhR1ZZcUs4R2g1T0xYTkNCS0Q3RFgvaE1WL3hMWVF6CnpwREtHK0JUdlJYNU9GRzB0aThEOXgybG4zRTNRamFJUlR4VktZZ1hyb2xnU2VzTWtVQk8vMlB4a0oxWkNSbzUKNHdUenlTU3B1N253OStPdzRZS0lBS3pLRk9XSzR6UTVUYU4rWjJnOHNvVDNVdEJyZmhGRzQyMWpWN2hMcitraApaVGVUMFVEbzlzMFJSZlNpckhQYXRNaG4zNkEzc1djNUNhWDRQYjdPTzNSd3B6aGo5eFN0U2h0QTd3TlRqdFZvCmMrZTlkQnpOY25NU3V2MVRaOGE0d3lBbm55UWNhaUREMytNQUJpV21rTUd4WmJVdUxJS1o0OFhteEFWOTkwMDAKR1dEWWorTDBSTDdNRDVNL2hFdEVBM1BLTkE1bThRbGRzR2Nod1kvOEE3N29wd0lEQVFBQm9CNHdIQVlKS29aSQpodmNOQVFrT01ROHdEVEFMQmdOVkhSRUVCREFDZ2dBd0RRWUpLb1pJaHZjTkFRRUxCUUFEZ2dFQkFEZzY5dGppCk9Jb1VxaUhVZS9tbFBSZmtpWUtQamY2UDJqTmpGZlFmVmgvamRZeGFuMEh0Vy93eVBsN2U0U0FOZzMwS3o0VDEKdm4xTmZhSGNneTBXaWpnOVE1UExnc0R0azlRUCtRRmpPRWhFOHBDTXFpMjZGajNVeU81QUlsNXd6elhWV2FMdAppVzduMnplUXhoS3dMSVA4T3hXWmxWWE5tQnNMWStjNGxFRTJkd0VQVDg2Rkl3OHFtdFU5MFN6VkFORW90ZUVVCkorU0orVlRrMmlYTGZkT3dpSWMweTlLcnkraHMzSUtlQlN2cjBTamg1UWF0RHJ0bnM0cHJrd0UrdGJjZ2MxbnAKUWZBZ1dLb3dFbHVwWDFIZThLRjRhbzEzc0h0ZStvV3pxNC82ZHo1R2FQVkFTcG55b0xBVlJOZW44cHU0T3RUdAovUGhTcnJXRExiTGVXclU9Ci0tLS0tRU5EIENFUlRJRklDQVRFIFJFUVVFU1QtLS0tLQo=
```

### Generate the kubernetes Certificate Signing Request.

```command
vim configs/signingrequest.yaml
```

```yaml
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

```command
kubectl create -f configs/signingrequest.yaml 
```
```
certificatesigningrequest "cloudyuga-csr" created
```

- List the CSR.

```command
kubectl get csr
```
```
NAME                                                   AGE       REQUESTOR                                        CONDITION
cloudyuga-csr                                          44s       kubernetes-admin                                 Pending
node-csr-abvQ8DWMb_hi1HEJ3ADMKT2unLzErLaSQ9iRrDA3oVM   2h        system:bootstrap:842694                          Approved,Issued
```

- Approve the CSR.

```command
kubectl certificate approve cloudyuga-csr
```
```
certificatesigningrequest "cloudyuga-csr" approved
```

### Lets download the certificate from the CSR.

```command
kubectl get csr cloudyuga-csr -o jsonpath='{.status.certificate}'     | base64 -d > cloudyuga.crt
```

### Create new context for the user cloudyuga.

- Set the credentials for the user.

```command
sudo kubectl config set-credentials cloudyuga --client-certificate=cloudyuga.crt --client-key=cloudyuga.key 
```

- Set the context for user.

```command
sudo kubectl config set-context cloudyuga-context --cluster=kubernetes --namespace=cloudyuga --user=cloudyuga
```

### Test the user `cloudyuga`.

- Run some pods in `default` and `cloudyuga` namespace.

```command
kubectl run nginx --image=nginx:alpine
```
```
deployment "nginx" created
```
- Create a namespace `cloudyuga`

```command
kubectl create ns cloudyuga

```

```command
kubectl run nginx --image=nginx:alpine -n cloudyuga
```

- List the pods running in the `cloudyuga` namespace.

```command
kubectl --context=cloudyuga-context get po
```
```
NAME                    READY     STATUS    RESTARTS   AGE
nginx-5bd976694-s6hkv   1/1       Running   0          39s
```

- List the pods running in the `default` namespace.

```command
kubectl --context=cloudyuga-context get pod -n default
```
```
NAME                    READY     STATUS    RESTARTS   AGE
nginx-5bd976694-mpjvr   1/1       Running   0          54s
```


