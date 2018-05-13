# Secret
Secrets kubernetes object designed to store and manage sensitive information that can be required for internal or external resources. The sensitive information like instance credentials, passwords, tokens, keys, ssh certificates etc. used by APIs, endpoints, servers, databases etc. Secrets provide not only a flexible way for managing sensitive data but also Secrets manage such sensitive information in a safer manner than storing it in plain text inside containers or pods.

## Create Secret.

Suppose we want to share the secret value `cloudyuga` as `username` and `cloudyuga123` as `password` in Kubernetes Secret specification file. Then lets encode these values.
```
$ echo cloudyuga|base64
Y2xvdWR5dWdhCg==

$ echo cloudyuga123|base64
Y2xvdWR5dWdhMTIzCg==
```

From above encoded data create configuration file for creating secret.
```
apiVersion: v1
kind: Secret
metadata:
  name: mysecret
type: Opaque
data:
  username: Y2xvdWR5dWdhCg==
  password: Y2xvdWR5dWdhMTIzCg==
```
Here in data section we have used encoded values of the `username` and `password`

Create secrete from above file.
```
$ kubectl create -f secret.yaml
secret "mysecret" created
```

## Secret as Environment variables.

Create a configuration file of pod as shown below. In which we have given the Environment variable via secret. 
```
apiVersion: v1
kind: Pod
metadata:
  name: secret-env
spec:
  containers:
    - name: nginx
      image: nginx:1.9.1
      env:
        - name: SECRET_USERNAME
          valueFrom:
            secretKeyRef:
              name: mysecret
              key: username
        - name: SECRET_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysecret
              key: password
  restartPolicy: Never
```

Create a pod from above configuration.
```
$ kubectl create -f secret-env.yaml
pod "secret-env" created
```
Get list of Running pods.
```
$ kubectl get po
NAME                       READY     STATUS    RESTARTS   AGE
secret-env                 1/1       Running   0          6s
```
Exec into the pod `secret-env` and get the environment varables
```
$ kubectl exec -it secret-env printenv
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
HOSTNAME=secret-env
TERM=xterm
SECRET_PASSWORD=cloudyuga123

SECRET_USERNAME=cloudyuga

KUBERNETES_SERVICE_PORT=443
NGINXSVC_PORT=tcp://10.102.195.16:80
KUBERNETES_SERVICE_PORT_HTTPS=443
KUBERNETES_PORT_443_TCP=tcp://10.96.0.1:443
KUBERNETES_PORT_443_TCP_PORT=443
NGINXSVC_PORT_80_TCP=tcp://10.102.195.16:80
NGINXSVC_SERVICE_PORT_HTTPS=443
NGINXSVC_PORT_80_TCP_PROTO=tcp
NGINXSVC_PORT_443_TCP_ADDR=10.102.195.16
KUBERNETES_SERVICE_HOST=10.96.0.1
KUBERNETES_PORT=tcp://10.96.0.1:443
KUBERNETES_PORT_443_TCP_ADDR=10.96.0.1
NGINXSVC_SERVICE_HOST=10.102.195.16
NGINXSVC_PORT_80_TCP_ADDR=10.102.195.16
NGINXSVC_PORT_443_TCP=tcp://10.102.195.16:443
NGINXSVC_PORT_443_TCP_PROTO=tcp
NGINXSVC_PORT_443_TCP_PORT=443
KUBERNETES_PORT_443_TCP_PROTO=tcp
NGINXSVC_SERVICE_PORT=80
NGINXSVC_SERVICE_PORT_HTTP=80
NGINXSVC_PORT_80_TCP_PORT=80
NGINX_VERSION=1.9.1-1~jessie
HOME=/root

```

## Using secrets as volumes 

Create a configuration file for pod. In which we have used secret as volume.
```
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  containers:
  - name: nginx
    image: nginx:1.9.1
    ports:
    - containerPort: 80
    volumeMounts:
    - name: secret
      readOnly: true
      mountPath: /data/db
  volumes:
  - name: secret
    secret:
      secretName: mysecret

```

Create a pod from above configuration
```
$ kubectl create -f secret-vol.yaml
pod "nginx" created
```

Get the list of running pods.
```
$ kubectl get pod
NAME                       READY     STATUS    RESTARTS   AGE
nginx                      1/1       Running   0          1m
secret-env                 1/1       Running   0          8m
```

Exec into the pod `nginx` and check the mount path. Here we can find the Secret.
```
kubectl exec -it nginx sh
# cd /data/db
# ls
password  username
# cat password
cloudyuga123
# cat username
cloudyuga
#
```
## Delete Pods and Secret.
```
$ kubectl delete po secret-env nginx
$ kubectl delete secret mysecret
```

# Secret Usage Demo.

Pull the `secret.json` file which create the secret using the `nginx.key` and `nginx.crt`. Download this file and deploy this secret.
``` 
$ wget https://raw.githubusercontent.com/cloudyuga/k8slab/master/https-nginx/secret.json 
$ kubectl apply -f secret.json 
secret "nginxsecret" created
```
- Create a Nginx deployment to consume this secret.
```
$ vim secret-demo.yaml


apiVersion: v1
kind: Service
metadata:
  name: nginxsvc
  labels:
    app: nginx
spec:
  type: NodePort
  ports:
  - port: 80
    nodePort: 30080
    protocol: TCP
    name: http
  - port: 443
    nodePort: 30443
    protocol: TCP
    name: https
  selector:
    app: nginx
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: my-nginx
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: nginx
    spec:
      volumes:
      - name: secret-volume
        secret:
          secretName: nginxsecret
      containers:
      - name: nginxhttps
        image: nkhare/nginx 
        ports:
        - containerPort: 443
        - containerPort: 80
        volumeMounts:
        - mountPath: /etc/nginx/ssl
          name: secret-volume
```

- Deploy the above application.
```
$ kubectl apply -f secret-demo.yaml 
service "nginxsvc" created
deployment.extensions "my-nginx" created
```

We have created the deployment and the service. Deployment is exposed using the NodePort. Unsecure service is running at the `http//<master-ip>:30080` while the secured service is running at the `https://<master-ip:30443`.
