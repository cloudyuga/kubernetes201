# ConfigMaps
ConfigMaps are quite similar to Secrets, ConfigMaps are designed to work more conveniently with data that doesnot contain sensitive information. ConfigMaps are generally used to store the data in the form of key-value pairs. The configuration data enclosed in the ConfigMaps can be used as

- Environment variables
- Command-line arguments for a container
- Config files in a volume

## Create A ConfigMaps.

Create ConfigMaps from following configuration file. Create following like yaml file.
```
apiVersion: v1
kind: ConfigMap
metadata:
  name: customer1
data:
  TEXT1: Customer1_Company
  TEXT2: Welcomes You
  COMPANY: Customer1 Company Technology Pvt. Ltd.
```

Deploy ConfigMaps from above yaml file.
```
$ kubectl create -f config.yaml
configmap "customer1" created
```

Get the list of ConfigMaps.
```
$ kubectl get configmap
NAME        DATA      AGE
customer1   3         1m
```

## ConfigMaps as Environment variables.
Lets create following alike configuration file in which we have used the environment variables from the ConfigMaps.
```
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: rsvp
spec:
  template:
    metadata:
      labels:
        app: rsvp
    spec:
      containers:
      - name: rsvp-app
        image: teamcloudyuga/rsvpapp
        env:
        - name: MONGODB_HOST
          value: mongodb
        - name: TEXT1
          valueFrom:
            configMapKeyRef:
              name: customer1
              key: TEXT1
        - name: TEXT2
          valueFrom:
            configMapKeyRef:
              name: customer1
              key: TEXT2
        - name: COMPANY
          valueFrom:
            configMapKeyRef:
              name: customer1
              key: COMPANY
        livenessProbe:
          httpGet:
            path: /
            port: 5000
          periodSeconds: 30
          timeoutSeconds: 1
          initialDelaySeconds: 50
        ports:
        - containerPort: 5000
          name: web-port

```
So the data we have enclosed in the `customer1` ConfigMap is now used as Environment Varialbles for `rsvp-app` container.

Deploy the Frontend application with above configuration file.
```
$ kubectl create -f rsvpconfig.yaml
deployment "rsvp" created
```

Lets create Backend for this Frontend and deploy it. Create follwoing like configuration yaml file.
```
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: rsvp-db
spec:
  replicas: 1
  template:
    metadata:
      labels:
        appdb: rsvpdb
    spec:
      containers:
      - name: rsvpd-db
        image: mongo:3.3
        env:
        - name: MONGODB_DATABASE
          value: rsvpdata
        ports:
        - containerPort: 27017
```

Deploy this Backend application.
```
$ kubectl create -f backend.yaml
deployment "rsvp-db" created
```

Get the list of Deployments.

```
$ kubectl get deploy
NAME      DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
rsvp      1         1         1            1           4m
rsvp-db   1         1         1            1           2m
```

Lets create A services for Frontend and backend.

Create the service for Frontend from following configuration file.
```
apiVersion: v1
kind: Service
metadata:
  name: rsvp
  labels:
    app: rsvp
spec:
  type: NodePort
  ports:
  - port: 80
    targetPort: web-port
    protocol: TCP
  selector:
    app: rsvp

```
Deploy Frontend Service.
```
$ kubectl create -f frontendservice.yaml
service "rsvp" created
```

Create Service configuration file for Backend application.
```
apiVersion: v1
kind: Service
metadata:
  name: mongodb
  labels:
    app: rsvpdb
spec:
  ports:
  - port: 27017
    protocol: TCP
  selector:
    appdb: rsvpdb
```

Deploy the Backend service.
```
$ kubectl create -f backendservice.yaml
service "mongodb" created
```

Get list of Services.
```
$ kubectl get svc

NAME         CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
kubernetes   10.96.0.1       <none>        443/TCP        27m
mongodb      10.107.242.62   <none>        27017/TCP      48s
rsvp         10.103.96.230   <nodes>       80:30921/TCP   48s
```
Now you can access your Frontend application at given port of master-IP and you can see there environment variable you have provided in ConfigMaps.

## ConfigMaps as Volumes 

Create Following like Pod configuration file to demonstrate ConfigMaps as volume.
```
apiVersion: v1
kind: Pod
metadata:
  name: con-demo
spec:
  containers:
    - name: test-container
      image: nginx:1.9.1
      command: [ "/bin/sh", "-c", "ls /tmp/config/" ]
      volumeMounts:
      - name: config-volume
        mountPath: /tmp/config
  volumes:
    - name: config-volume
      configMap:
        name: customer1
  restartPolicy: Never
```
In this configuration file, the configuration data enclosed in the ConfigMap `customer1` is mounted as volume. So the container mounting this ConfigMap volume will get the configuration data.

Deploy the pod with above configuration file.
```
$ kubectl create -f configvolume.yaml
pod "con-demo" created
```
Get the list of Pods.
```
kubectl get po --show-all
NAME                       READY     STATUS      RESTARTS   AGE
con-demo                   0/1       Completed   0          37s
rsvp-3903261322-ksfxp      1/1       Running     7          22m
rsvp-db-1761629065-bq0x2   1/1       Running     0          20m
```

Get logs of the pod `con-demo`.
```
$ kubectl logs con-demo
COMPANY
TEXT1
TEXT2
```
## Delete Services Deployments and Configmaps.
```
$ kubectl delete svc mongodb rsvp 
$ kubectl delete deploy rsvp rsvp-db
$ kubectl delete configmap customer1
```
