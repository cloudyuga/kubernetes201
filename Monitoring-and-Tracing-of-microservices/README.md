**Prerequisites**: Ingress controller must enabled in cluster.

## Monitoring microservice.

## Monolith Application Architecture:
![Monolith Application](./Monolith.jpeg?raw=true)

### Steps to run the application.
```
$ git clone https://github.com/cloudyuga/e-cart.git
$ cd e-cart
$ git checkout ninth-prometheus
$ kubectl apply -f k8s/.
```
### Verify that following services are up and running.
```
$ kubectl get svc

NAME          TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)             AGE
cart          ClusterIP   10.100.172.16    <none>        5003/TCP            1m
cartdb        ClusterIP   10.107.160.190   <none>        27017/TCP           1m
catalogue     ClusterIP   10.106.167.21    <none>        5001/TCP            1m
cataloguedb   ClusterIP   10.107.178.175   <none>        27017/TCP           1m
frontend      NodePort    10.111.48.24     <none>        5000:31500/TCP      1m
kubernetes    ClusterIP   10.96.0.1        <none>        443/TCP             2h
orders        ClusterIP   10.97.161.231    <none>        5004/TCP            1m
ordersdb      ClusterIP   10.107.13.198    <none>        27017/TCP           1m
payment       ClusterIP   10.111.243.71    <none>        5005/TCP,8700/TCP   1m
paymentdb     ClusterIP   10.97.121.233    <none>        27017/TCP           1m
prometheus    NodePort    10.103.128.6     <none>        9090:31900/TCP      1m
user          ClusterIP   10.101.16.111    <none>        5002/TCP            1m
userdb        ClusterIP   10.103.183.216   <none>        27017/TCP           1m
```

### Verify the Pods.
```
$ kubectl get pods
NAME                          READY     STATUS    RESTARTS   AGE
cart-789fdf9f9d-l5954         1/1       Running   0          2m
cartdb-84bcdf5d6c-9qnn5       1/1       Running   0          2m
catalogue-6474cdd6d7-72r5g    1/1       Running   0          2m
cataloguedb-f96bf77c5-7vg89   1/1       Running   0          2m
frontend-658c7f465f-4nqx5     1/1       Running   0          2m
orders-6896b6df44-qmdmc       1/1       Running   0          2m
ordersdb-6c8c59c6f-z9pzp      1/1       Running   0          2m
payment-7d666d5d65-9n4v5      1/1       Running   0          2m
paymentdb-8647454cb9-bd7tt    1/1       Running   0          2m
prometheus-5f6598f497-rn8p7   1/1       Running   0          2m
user-84c59959b4-ttfh5         1/1       Running   0          2m
userdb-7d8d9b77b5-4v26b       1/1       Running   0          2m
```

We created the above microservices from monolith application.

## Microservices Application architecture.
![Microservices](./Catalogue.jpeg?raw=true)


### Access the application.
- Open the `Prometheus` running at the `31900`  and run the query `request_count`. And check the request. Lets open the Ecart application and make some entries.

- The front end application is running at the `31500` port of Node IP. Open the E-Cart application, register user and make some entries, place some orders.

- Now again tak a look at the `Prometheus` application. There is increment in the request count.

### Load the application.
```
$ git checkout tenth-load-test
$ cd load 
$ python3 loadTest.py 138.197.6.250 31500
```
Here the `138.197.6.250` is the IP address of the Application and `31500` port number at which the application is running.

Now go the the `Prometheus` application and check out the `request count`

###  Clean the application.
```
$ cd e-cart
$ git checkout ninth-prometheus
$ kubectl delete -f k8s/.
```

## Traciing Microservices. 

### Steps to run the application.
```
$ git clone https://github.com/cloudyuga/e-cart.git
$ cd e-cart
$ git checkout eleventh-jaeger
$ kubectl apply -f k8s/.
$ kubectl apply -f k8s/ingress/.
```

- Run the Jaeger.
```
$ kubectl apply -f jaeger-all-in-one-template.yml
```

- Access the E-cart application at http://ecart.cloudyuga.io . Open the E-Cart application, register user and make some entries, place some orders.

- Access the Jaeger UI at http://tracing.cloudyuga.io and find out tracing between various microservices.
