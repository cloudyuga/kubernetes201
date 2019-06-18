

# Simple Volumes.
A volume is a directory, usually with some data in it. Volumes are accessible to a container as part of its filesystem. Volumes can be used to store stateful app data or volumes are used to mount some data or storage within the container. When the multiple container in the pod want to share the data across each other then simplest way to mount the volume and share the data.

## Mounting volumes in different containers
To demontrate this lets create Application which consist of a Frontend and Backend. Backend is database and we are going to mount the data in that Backend Pod.

#### Frontend

- Create Deployment configuration for Frontent as shown below.

```yaml

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
        livenessProbe:
          httpGet:
            path: /
            port: 5000
          periodSeconds: 30
          timeoutSeconds: 1
          initialDelaySeconds: 50
        env:
        - name: MONGODB_HOST
          value: mongodb
        ports:
        - containerPort: 5000
          name: web-port
```

- Create deployment from configuration.

```command
kubectl create -f configs/1-Volumes/frontend.yaml 
```
```output
deployment.extensions "rsvp" created
```
- Create a Frontend service
-  we are going to use service type `Nodeport`  as our front end may be accessed from outside the cluster. Create following  configuration file.

```yaml

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

- Deploy the Frontend service.

```command
kubectl create -f configs/1-Volumes/frontendservice.yaml
```
```
service "rsvp" created
```
#### Backend.

Create following like Deployment configuration file. In which have mounted the `voldb` volume in the container.

```yaml

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
      volumes:
        - name: voldb
          hostPath:
            path: /tmp
      containers:
      - name: rsvpd-db
        image: mongo:3.3
        volumeMounts:
        - name: voldb
          mountPath: /data/db
        env:
        - name: MONGODB_DATABASE
          value: rsvpdata
        ports:
        - containerPort: 27017

```

**In the above config file we have used the `voldb` volume of type `hostPath` . The `/data/db` of the mongodb container is mounted within that volume. This volume is stored at `/tmp` location of host. A hostPath volume mounts a file or directory from the host node's filesystem into your pod.**

- Create deployment from above configuration.

```command
kubectl create -f configs/1-Volumes/backendvol.yaml
```
```
deployment.extensions "rsvp-db" created
```

- Create Service configuration file for Backend application. 

```yaml

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

- Deploy the Backend service.

```command
kubectl create -f configs/1-Volumes/backendservice.yaml
```
```
service "mongodb" created
```
- Get the list of deployments.

```command
kubectl get deploy
```
```
NAME      DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
rsvp      1         1         1            1           1m
rsvp-db   1         1         1            1           6s
```

- Now access the front-end via browser and make some entries in it. Now go to the terminal and delete the deployment `rsvp-db`.

```command
kubectl delete deploy rsvp-db
```
```
deployment.extensions "rsvp-db" deleted
```
- Deploy the Backend again.

```command
kubectl create -f configs/1-Volumes/backendvol.yaml
```
```
deployment.extensions "rsvp-db" created
```

List the deployments.

```command
kubectl get deploy

```
NAME      DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
rsvp      1         1         1            1           11m
rsvp-db   1         1         1            1           1m
```
Now Go to browser and try to access the Frontend and you will see the entries you made earlier are still there. We have mounted the DB in volumes. Though container is deleted, data is stored at volume and when new container of mongodb comes up then data from volume is mounted.

- Hostpath is very useful when we use the single node cluster like `minikube` but what if we are using the multinode cluster?

Consider a pod scheduled to a particular node is using the `hostPath` volume and store data to host node,  if that node got failed and pod is rescheduled to the different node then the pod wont be able to retrieve its earlier state. 

## Delete Services and deployments.

```command
kubectl delete svc mongodb rsvp 
kubectl delete deploy rsvp rsvp-db
```



# Persistent Volumes.

## Create a Persistent Volumes.

A PersistentVolume (PV) is a piece of storage in the cluster. PVs are provisoned by the administrator of cluster. PV is a resource in the cluster just like the other cluster resource. PVs are volume plugins like simple Volumes, but PVS have a lifecycle independent of any individual pod that uses the PV. Generally when pod is deleted then volume associated with get deleted. When the Pod using the PVs get deleted or removed then PV is not removed like other volumes.


- Make configuration file for Persistent volume (PV) as show below. This will create PV of 1GB.

```yaml

kind: PersistentVolume
apiVersion: v1
metadata:
  name: pv0001
  labels:
    type: local
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/tmp/data01"
```

- Deploy a PV with above configuration.

```command
kubectl create -f configs/2-Persistent-Volumes/pv.yaml
```
```
persistentvolume "pv0001" created
```

## Create Persistent Volume Claims.
A PersistentVolumeClaim (PVC) is the request for PV storage by a user. This PVC is similar to a pod. Just like the Pods consume node resources, The PVCs consume PV resources. PVClaims can request specific size of PV storage and access modes for PV (e.g., can be mounted once read/write or many times read-only).

- Create a configuration file for creating the Persistent Volume Claims (PVC). 

```yaml
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: myclaim-1
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 0.5Gi
```

- Deploy a PV with above configuration.

```command
kubectl create -f configs/2-Persistent-Volumes/pvclaim.yaml
```
```
persistentvolumeclaim "myclaim-1" created
```

- Check the list of PV.

```command
kubectl get pv
```
```
NAME      CAPACITY   ACCESSMODES   RECLAIMPOLICY   STATUS    CLAIM               STORAGECLASS   REASON  AGE
pv0001    1Gi        RWO           Retain          Bound     default/myclaim-1                          5m
```

- Get list of PVC.

```command
kubectl get pvc
```
```
NAME        STATUS    VOLUME    CAPACITY   ACCESSMODES   STORAGECLASS   AGE
myclaim-1   Bound     pv0001    1Gi        RWO                          4s
```

#### Frontend

- Create Deployment configuration for Frontent as shown below.

```yaml

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
        livenessProbe:
          httpGet:
            path: /
            port: 5000
          periodSeconds: 30
          timeoutSeconds: 1
          initialDelaySeconds: 50
        env:
        - name: MONGODB_HOST
          value: mongodb
        ports:
        - containerPort: 5000
          name: web-port
```

- Create deployment from configuration.

```command
kubectl create -f configs/2-Persistent-Volumes/frontend.yaml 
```
```
deployment.extensions "rsvp" created
```

- Create a Frontend service. 
We are going to use the service type ` Nodeport`,  as our front-end may be accessed from outside the cluster. Create following like configuration file.

```yaml

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

- Deploy the Frontend service.

```command
kubectl create -f configs/2-Persistent-Volumes/frontendservice.yaml
```
```
service "rsvp" created
```

#### Backend

Lets Modify above Backend configuration file to demonstrate use of PVC.

```yaml
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
      volumes:
        - name: voldb
          persistentVolumeClaim:
           claimName: myclaim-1
      containers:
      - name: rsvpd-db
        image: mongo:3.3
        volumeMounts:
        - name: voldb
          mountPath: /data/db
        env:
        - name: MONGODB_DATABASE
          value: rsvpdata
        ports:
        - containerPort: 27017
```

- Deploy the backend configured with PVC.

```command
kubectl create -f configs/2-Persistent-Volumes/backendpvc.yaml
```
```
deployment.extensions "rsvp-db" created
```

- Create Service configuration file for Backend application. 

```yaml

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

- Deploy the Backend service.

```command
kubectl create -f configs/2-Persistent-Volumes/backendservice.yaml
```
```
service "mongodb" created
```

### Check pvc is properly configured.


- Now access the front end via browser and make some entries in it. Now go to the terminal and delete the deployment `rsvp-db`.

```command
kubectl delete deploy rsvp-db
```
```
deployment.extensions "rsvp-db" deleted
```
- Again deploy the Backend.

```command
kubectl create -f configs/2-Persistent-Volumes/backendpvc.yaml
```
```
deployment.extensions "rsvp-db" created
```
Now Go to browser and try to access the Frontend and you will see the entries you made earlier are still there. 

- Get the list of deployments.

```command
kubectl get deploy
```
```
NAME      DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
rsvp      1         1         1            1           1m
rsvp-db   1         1         1            1           6s
```

 Now access the front end via browser and make some entries in it. Now go to the terminal and delete the deployment `rsvp-db`.

```command
kubectl delete deploy rsvp-db
```
```
deployment.extensions "rsvp-db" deleted
```
Again deploy the Backend.

```command
kubectl create -f configs/2-Persistent-Volumes/backendpvc.yaml
```
```
deployment.extensions "rsvp-db" created
```

List the deployments.

```command
kubectl get deploy
```
```
NAME      DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
rsvp      1         1         1            1           11m
rsvp-db   1         1         1            1           1m
```
Access the Frontend trhough browser and you can see the entries you made earlier are still there. We have mounted the DB in volumes. Though container is deleted, data is stored at volume and when new container of mongodb comes up then data from volume is mounted.


## Delete Services, deployments, PV and PVC.

```command
kubectl delete svc mongodb rsvp 
kubectl delete deploy rsvp rsvp-db
kubectl delete pvc myclaim-1
kubectl delete pv pv0001
```


# Dynamic Volume Provisioning with ROOK.


## Rook

Rook turns distributed storage software into a self-managing, self-scaling, and self-healing storage services. It does this by automating deployment, bootstrapping, configuration, provisioning, scaling, upgrading, migration, disaster recovery, monitoring, and resource management. Rook uses the facilities provided by the underlying cloud-native container management, scheduling and orchestration platform to perform its duties.

We would be orchestrating the storage using Rook, which is the storage orchestrator for Kubernetes. To orchestrate the block storage, it uses Ceph. Ceph is a Software Defined Storage, which can combine and utilize the storage from different participant nodes and give us a storage pool. We can get the storage pool as Object, Block or file-system.

We would need to install Ceph on all nodes, so you would have to login to each node seperately run following command :-

##### On all the nodes of cluster install `ceph`.

```command
sudo apt-get install ceph-fs-common ceph-common -y
```

### Deploy Rook in the kubernetes cluster.

With your Kubernetes cluster running, Rook can be setup and deployed by simply creating the `rook-operator` deployment and creating a rook cluster. 

- Clone the git repository for the Rook.

```command
git clone https://github.com/rook/rook.git
cd rook
```

- Deploy the Rook operator.

```command
cd cluster/examples/kubernetes
kubectl create -f rook-operator.yaml
```

- Verify the rook-operator and rook-agents pods are in the `Running` state before proceeding.

```command
kubectl -n rook-system get pod
```
```
NAME                            READY     STATUS    RESTARTS   AGE
rook-agent-chf2f                1/1       Running   0          14m
rook-agent-hv4kn                1/1       Running   0          14m
rook-operator-bf85b568f-q4f6s   1/1       Running   0          15m
```

- Deploy rook-cluster

```command
kubectl create -f rook-cluster.yaml 
```

- List the pods in `rook` namespace.

```command
kubectl -n rook get pod
```
```
NAME                              READY     STATUS    RESTARTS   AGE
rook-api-541965964-t5fzd          1/1       Running   0          2h
rook-ceph-mgr0-1951369517-xq2xj   1/1       Running   0          2h
rook-ceph-mon0-4kn3l              1/1       Running   0          2h
rook-ceph-mon1-0vn9k              1/1       Running   0          2h
rook-ceph-mon2-fjb8w              1/1       Running   0          2h
rook-ceph-osd-38jd0               1/1       Running   0          2h
rook-ceph-osd-3j7b8               1/1       Running   0          2h
```

- Create the Storage Class and resource pool.

This file specify new storage class `rook-block` the provisoner of this class is `rook.io/block`. To this storageclass we have specified `pool`parameter which we have created earlier in the same file.

- Deploy this configuration file.

```command
kubectl create -f rook-storageclass.yaml
```
```
pool "replicapool" created
storageclass "rook-block" created
```

- Get the list of `storageclass`.

```command
kubectl get storageclass
```
```
NAME                 TYPE
rook-block           rook.io/block                
```

- Get the list of `pool`.

```command
kubectl get pool -n rook
```
```
NAME          KIND
replicapool   Pool.v1alpha1.rook.io
```

#### Deploy the RSVP application using PVC with `rook-block storageclass`.

- Deploy RSVP frontend using following configuration file.

```yaml
---
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
        ports:
        - containerPort: 5000
          name: web-port
---
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
This file contains Frontend pod and the service for that pod.

- Create the deployment using the deployment.

```command
kubectl create -f configs/3-Dynamic-Volume-Provisioning-with-ROOK/frontend.yaml
```

- Create the backend deployment, Persistent Volume claim, and Backend service from the following configuration.

```yaml
---
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
      volumes:
        - name: voldb
          persistentVolumeClaim:
           claimName: myclaim
      containers:
      - name: rsvpd-db
        image: mongo:3.3
        volumeMounts:
        - name: voldb
          mountPath: /data/db
        env:
        - name: MONGODB_DATABASE
          value: rsvpdata
        ports:
        - containerPort: 27017
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: myclaim
  labels:
    appdb: rsvpdb
spec:
  storageClassName: rook-block
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
--- 

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


- Create the backend deployment.

```command
kubectl create -f configs/3-Dynamic-Volume-Provisioning-with-ROOK/backend.yaml
```

- Check the PVC.

```command
kubectl get pvc
```
```
NAME      STATUS    VOLUME                                     CAPACITY   ACCESSMODES   STORAGECLASS   AGE
myclaim   Bound     pvc-0286d7b1-99f2-11e7-94db-080027a8df8b   1Gi        RWO           rook-block     1h
```

Try to access the application at Nodeport. Make some entries in that RSVP application. Delete the backend and  deploy backend again. You will see our older entries are still present in that page.

### Set `rook-block` as your default storage claas [Optional].

- Set rook as your default storage class.

```command
kubectl patch storageclass rook-block -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```
## Delete Services, Deployments and PVC.

```comman
kubectl delete svc mongodb rsvp 
kubectl delete deploy rsvp rsvp-db
kubectl delete pvc myclaim
```
