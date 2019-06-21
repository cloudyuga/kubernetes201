

# Simple Volumes.
A volume is a directory, usually with some data in it. Volumes are accessible to a container as part of its filesystem. Volumes can be used to store stateful app data or volumes are used to mount some data or storage within the container. When the multiple container in the pod want to share the data across each other then simplest way to mount the volume and share the data.

## Mounting volumes in different containers
To demontrate this lets create Application which consist of a Frontend and Backend. Backend is database and we are going to mount the data in that Backend Pod.

### Frontend

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
### Backend.

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

### Frontend

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

### Backend

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


# Dynamic Volume Provisioning.


## Storage Classes and How to Use them

StorageClasses are the foundation of dynamic provisioning, allowing cluster administrators to define abstractions for the underlying storage platform. Users simply refer to a StorageClass by name in the PersistentVolumeClaim (PVC) using the “storageClassName” parameter.


# Dynamic Volume Provisioning StorageClass

## Slides
<iframe src="https://docs.google.com/presentation/d/e/2PACX-1vTTtncKS5lSGb6kOChwz3n5MU9BplR8tCwOXdfhL-K3WU3TvRnGglrBM_ZAX67YBZpdnlwEgtPR5ZyC/embed?start=false&loop=false&delayms=3000" frameborder="0" width="960" height="569" allowfullscreen="true" mozallowfullscreen="true" webkitallowfullscreen="true"></iframe>


## Labs

### List the StorageClasses

```command
kubectl get storageclass
```
```output
No resources found.
```

If there is no StorageClass then, we would need to create one. If there is one,then we set it as **default StorageClass**. Please look at the instruction below to set up. 

### Install Ceph on nodes
 
We would be orchestrating the storage using **[Rook](https://rook.io)**, which is the storage orchestrator for Kubernetes. To orchestrate the **block storage**, it uses **[Ceph](https://ceph.com)**. Ceph is a **Software Defined Storage**, which can combine and utilize the storage from different participant nodes and give us a storage pool. We can get the storage pool as Object, Block or file-system. 


- We would need to install Ceph on all nodes, so you would have to login to each node seperately run following command :-

```preventcopy
apt install ceph ceph-common
``` 

### Install Rook on Kubernetes

**Rook** get installed as **Kuberenets Operator**. To install it we would be fist cloning its Git repository.

```command
git clone https://github.com/rook/rook.git
```
```command
git checkout release-0.8
```
- Install the operator 

```command
kubectl apply  -f rook/cluster/examples/kubernetes/ceph/operator.yaml
kubectl apply -f rook/cluster/examples/kubernetes/ceph/cluster.yaml
```
```output
namespace/rook-ceph-system created
customresourcedefinition.apiextensions.k8s.io/cephclusters.ceph.rook.io created
customresourcedefinition.apiextensions.k8s.io/cephfilesystems.ceph.rook.io created
customresourcedefinition.apiextensions.k8s.io/cephnfses.ceph.rook.io created
customresourcedefinition.apiextensions.k8s.io/cephobjectstores.ceph.rook.io created
customresourcedefinition.apiextensions.k8s.io/cephobjectstoreusers.ceph.rook.io created
customresourcedefinition.apiextensions.k8s.io/cephblockpools.ceph.rook.io created
customresourcedefinition.apiextensions.k8s.io/volumes.rook.io created
clusterrole.rbac.authorization.k8s.io/rook-ceph-cluster-mgmt created
role.rbac.authorization.k8s.io/rook-ceph-system created
clusterrole.rbac.authorization.k8s.io/rook-ceph-global created
clusterrole.rbac.authorization.k8s.io/rook-ceph-mgr-cluster created
serviceaccount/rook-ceph-system created
rolebinding.rbac.authorization.k8s.io/rook-ceph-system created
clusterrolebinding.rbac.authorization.k8s.io/rook-ceph-global created
deployment.apps/rook-ceph-operator created
namespace/rook-ceph created
serviceaccount/rook-ceph-osd created
serviceaccount/rook-ceph-mgr created
role.rbac.authorization.k8s.io/rook-ceph-osd created
clusterrole.rbac.authorization.k8s.io/rook-ceph-mgr-system created
role.rbac.authorization.k8s.io/rook-ceph-mgr created
rolebinding.rbac.authorization.k8s.io/rook-ceph-cluster-mgmt created
rolebinding.rbac.authorization.k8s.io/rook-ceph-osd created
rolebinding.rbac.authorization.k8s.io/rook-ceph-mgr created
rolebinding.rbac.authorization.k8s.io/rook-ceph-mgr-system created
clusterrolebinding.rbac.authorization.k8s.io/rook-ceph-mgr-cluster created
cephcluster.ceph.rook.io/rook-ceph created
```

#### Checkout the Pods in **rook-ceph-system** and **rook-ceph**

```command
kubectl get pods -n rook-ceph-system
```
```output
NAME                                 READY   STATUS    RESTARTS   AGE
rook-ceph-agent-8zp5d                1/1     Running   0          73s
rook-ceph-agent-xkxg4                1/1     Running   0          73s
rook-ceph-operator-b996864dd-wrhmz   1/1     Running   0          92s
rook-discover-6kkgt                  1/1     Running   0          73s
rook-discover-rf9gg                  1/1     Running   0          73s
``` 

```command
kubectl get pods  -n rook-ceph
```
```output
NAME                               READY   STATUS    RESTARTS   AGE
rook-ceph-mgr-a-7469566bdf-fcgqs   1/1     Running   0          24s
rook-ceph-mon-a-5b7f5db8d8-66czm   1/1     Running   0          63s
rook-ceph-mon-b-69bd898747-zmnf6   1/1     Running   0          42s
rook-ceph-mon-c-6b5698894d-xfnr8   1/1     Running   0          33s
``` 

### Create the **rook-ceph-block StorageClass**

Once we the Rook cluster configured using earlier steps, we'll create the **rook-ceph-block StorageClass**, which would help to dynamically provision the storage.


```command
kubectl create -f rook/cluster/examples/kubernetes/ceph/storageclass.yaml
```
```output
cephblockpool.ceph.rook.io/replicapool created
storageclass.storage.k8s.io/rook-ceph-block created
``` 

#### List the StorageClass
```command
kubectl get storageclass
```
```outout
NAME              PROVISIONER          AGE
rook-ceph-block   ceph.rook.io/block   33s
```

### Configuring the Backend application to use **rook-ceph-block StorageClass**  

In the `configs/1-backend.yaml` file, make sure that we the **rook-ceph-block** as **StorageClass**

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: dynamic-claim
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: rook-ceph-block
  resources:
    requests:
      storage: 1Gi
```

### Deploy the Backend and Frontend application

```command
kubectl apply -f configs/1-backend.yaml
kubectl apply -f configs/2-frontend.yaml
```

### List the **PVC** and **PV** 

```command
kubectl get pvc
```
```output
NAME            STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS      AGE
dynamic-claim   Bound    pvc-479d54e0-4254-11e9-9572-923c581de2b9   1Gi        RWO            rook-ceph-block   76s
```


```command
kubectl get pv
```
```output
NAME                               CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                   STORAGECLASS      REASON   AGE
pvc-479d54e0-4254-11e9-9572-923c581de2b9   1Gi        RWO            Delete    Bound    default/dynamic-claim   rook-ceph-block            60s
```

### Set the **rook-ceph-block** as default  **StorageClass**
We can set **rook-ceph-block** as default  **StorageClass**, after which all of the volumes 
would be provisioned using this **rook** only; unless someone mentions a different StorageClass which 
creating the PVC.  

```command
kubectl patch storageclass rook-ceph-block -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```
```output
storageclass.storage.k8s.io/rook-ceph-block patched
```

List the StorageClass

```command
kubectl get storageclass
```
```output
NAME                        PROVISIONER          AGE
rook-ceph-block (default)   ceph.rook.io/block   42m
```

### Clean up

#### Delete the application

```command
kubectl delete -f configs/
```

#### Delete the Rook Operator

```command
kubectl delete -f rook/cluster/examples/kubernetes/ceph/cluster.yaml
```

```command
kubectl delete -f rook/cluster/examples/kubernetes/ceph/operator.yaml
```








