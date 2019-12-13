# User Authentication

## Slides

<iframe src="https://docs.google.com/presentation/d/e/2PACX-1vQ7Vx9ZNTZxM-_K1HXhnpR78CEwsBSltMObYNjaRdQ1N56XZzaN7G4OPHAi02ZM65f9cMCEd3eQLg51/embed?start=false&loop=false&delayms=3000" frameborder="0" width="960" height="569" allowfullscreen="true" mozallowfullscreen="true" webkitallowfullscreen="true"></iframe>

## Labs

### Create new Namespace cloudyuga.

```command
kubectl create ns cloudyuga
```

### Generate the Private Key and CSR

```command
openssl genrsa -out cloudyuga.key 2048
```

```command
openssl req -new -key cloudyuga.key -out cloudyuga.csr -subj "/CN=cloudyuga/O=cloudyuga"
```

### Encode the `cloudyuga.csr`.

```command
cat cloudyuga.csr | base64 | tr -d '\n'
```

```
LS0tLS1CRUdJTiBDRVJUSUZJQ0FURSBSRVFVRVNULS0tLS0KTUlJQ2R6Q0NBVjhDQVFBd0ZERVNNQkFHQTFVRUF4TUpZMnh
2ZFdSNWRXZGhNSUlCSWpBTkJna3Foa2lHOXcwQgpBUUVGQUFPQ0FROEFNSUlCQ2dLQ0FRRUFtN2N5allaRHlhR1ZZcUs4R2
g1T0xYTkNCS0Q3RFgvaE1WL3hMWVF6CnpwREtHK0JUdlJYNU9GRzB0aThEOXgybG4zRTNRamFJUlR4VktZZ1hyb2xnU2VzT
WtVQk8vMlB4a0oxWkNSbzUKNHdUenlTU3B1N253OStPdzRZS0lBS3pLRk9XSzR6UTVUYU4rWjJnOHNvVDNVdEJyZmhGRzQy
MWpWN2hMcitraApaVGVUMFVEbzlzMFJSZlNpckhQYXRNaG4zNkEzc1djNUNhWDRQYjdPTzNSd3B6aGo5eFN0U2h0QTd3TlR
qdFZvCmMrZTlkQnpOY25NU3V2MVRaOGE0d3lBbm55UWNhaUREMytNQUJpV21rTUd4WmJVdUxJS1o0OFhteEFWOTkwMDAKR1
dEWWorTDBSTDdNRDVNL2hFdEVBM1BLTkE1bThRbGRzR2Nod1kvOEE3N29wd0lEQVFBQm9CNHdIQVlKS29aSQpodmNOQVFrT
01ROHdEVEFMQmdOVkhSRUVCREFDZ2dBd0RRWUpLb1pJaHZjTkFRRUxCUUFEZ2dFQkFEZzY5dGppCk9Jb1VxaUhVZS9tbFBS
ZmtpWUtQamY2UDJqTmpGZlFmVmgvamRZeGFuMEh0Vy93eVBsN2U0U0FOZzMwS3o0VDEKdm4xTmZhSGNneTBXaWpnOVE1UEx
nc0R0azlRUCtRRmpPRWhFOHBDTXFpMjZGajNVeU81QUlsNXd6elhWV2FMdAppVzduMnplUXhoS3dMSVA4T3hXWmxWWE5tQn
NMWStjNGxFRTJkd0VQVDg2Rkl3OHFtdFU5MFN6VkFORW90ZUVVCkorU0orVlRrMmlYTGZkT3dpSWMweTlLcnkraHMzSUtlQ
lN2cjBTamg1UWF0RHJ0bnM0cHJrd0UrdGJjZ2MxbnAKUWZBZ1dLb3dFbHVwWDFIZThLRjRhbzEzc0h0ZStvV3pxNC82ZHo1
R2FQVkFTcG55b0xBVlJOZW44cHU0T3RUdAovUGhTcnJXRExiTGVXclU9Ci0tLS0tRU5EIENFUlRJRklDQVRFIFJFUVVFU1Q
tLS0tLQo=
```

### Generate the kubernetes Certificate Signing Request with above output.

```command
vim signingrequest.yaml
```

```yaml
apiVersion: certificates.k8s.io/v1beta1
kind: CertificateSigningRequest
metadata:
  name: cloudyuga-csr
spec:
  groups:
    - system:authenticated
  request:
  usages:
    - digital signature
    - key encipherment
    - client auth
```

### Create the CSR.

```command
kubectl apply -f signingrequest.yaml
```

- List the CSR.

```command
kubectl get csr
```

```
NAME                                                   AGE       REQUESTOR                                        CONDITION
cloudyuga-csr                                             44s       kubernetes-admin                                 Pending
node-csr-abvQ8DWMb_hi1HEJ3ADMKT2unLzErLaSQ9iRrDA3oVM   2h        system:bootstrap:842694                          Approved,Issued
```

### Approve the CSR.

```command
kubectl certificate approve cloudyuga-csr
```

```
certificatesigningrequest "cloudyuga-csr" approved
```

### Lets download the certificate from the CSR.

```command
kubectl get csr cloudyuga-csr -o jsonpath='{.status.certificate}' \
    | base64 -d > cloudyuga.crt
```

### Add a new context with the new credentials for your Kubernetes cluster.

```command
kubectl config set-credentials cloudyuga --client-certificate=`pwd`/cloudyuga.crt \
--client-key=`pwd`/cloudyuga.key
```

```command
kubectl config set-context cloudyuga-context --cluster=kubernetes \
--namespace=cloudyuga --user=cloudyuga
```

### Try to get pod list with this above created context.

```command
kubectl --context=cloudyuga-context get pods
```

```
Error from server (Forbidden): User "cloudyuga" cannot list pods in the namespace "cloudyuga". (get pods)
```

You should get an access denied error when using the kubectl CLI with this configuration file because we have not described any roles or clusterrole for this user.
