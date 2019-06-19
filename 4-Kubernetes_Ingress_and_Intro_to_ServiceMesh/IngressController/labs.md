# Ingress
Typically, services and pods have IPs only routable by the cluster network. All traffic that ends up at an edge router is either dropped or forwarded elsewhere. `An Ingress is a collection of rules that allow inbound connections to reach the cluster services.` It can be configured to give services externally-reachable URLs, load balance traffic, terminate SSL, offer name based virtual hosting, and more. Users request ingress by POSTing the Ingress resource to the API server. In order for the Ingress resource to work, the cluster must have an Ingress controller running. This is unlike other types of controllers, which typically run as part of the kube-controller-manager binary, and which are typically started automatically as part of cluster creation. Choose the ingress controller implementation that best fits your cluster, or implement a new ingress controller


## Setting up Ingress Controller and it's component.

- Deploy the Nginx Ingress controller.

```command
kubectl apply -f configs/mandatory.yaml
kubectl apply -f configs/cloud-generic.yaml
```

### Blue and Green application

Create and deploy the Blue application from following configuration file.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: blue
spec:
  replicas: 1
  selector:
    matchLabels:
      app: blue
  template:
    metadata:
      labels:
        app: blue
    spec:
      containers:
      - name: blue
        image: teamcloudyuga/blue
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: blue
  labels:
    app: blue
spec:
  ports:
  - port: 80
    protocol: TCP
  selector:
    app: blue
```

- Deploy the application

```command
kubectl apply -f configs/2-blue.yaml
```

- Create and deploy the Green application from following configuration file.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: green
spec:
  replicas: 1
  selector:
    matchLabels:
      app: green
  template:
    metadata:
      labels:
        app: green
    spec:
      containers:
      - name: green
        image: teamcloudyuga/green
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: green
  labels:
    app: green
spec:
  ports:
  - port: 80
    protocol: TCP
  selector:
    app: green
```

- Deploy the Green application.
```command
kubectl apply -f configs/3-green.yaml
```

- Create a Vhost based ingress object.

```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: test
spec:
  rules:
  - host: blue.cy.guru
    http:
      paths:
      - backend:
          serviceName: blue
          servicePort: 80
  - host: green.cy.guru
    http:
      paths:
      - backend:
          serviceName: green
          servicePort: 80
```

- Deploy this ingress object.
```command
kubectl apply -f configs/4-ingress_vhost.yaml
```

- Get the status of ingress.

```command
kubectl get ing
```

```output
NAME      HOSTS                        ADDRESS                                                                   PORTS     AGE
test      blue.cy.guru,green.cy.guru   157.230.73.72                                                              80        6m
```
 
- Curl to the `blue.cy.guru` and see the output of curl.

```command
curl -H "Host: blue.cy.guru" 157.230.73.72
```
```output
<!DOCTYPE html>
<html>
<body bgcolor="Blue">
<h1> This is Blue Application <h1>
<h1>Hello From Cloudyuga!</h1>
<p><a href="https://cloudyuga.guru/"> Visit cloudyuga.guru!</a></p>
.
.
.
.
</body>
</html>
```
You can aslo check the in the browser `green.cy.guru` will show you nginx running.

- Curl to the `green.cy.guru` and see the output of curl.
```command
curl -H "Host: green.cy.guru" LoadBalancer-CNAME
```

```output
<!DOCTYPE html>
<html>
<body bgcolor="Green">
<h1> This is Green Application <h1>
<h1>Hello From Cloudyuga!</h1>
<p><a href="https://cloudyuga.guru/"> Visit cloudyuga.guru!</a></p>
.
.
.
</body>
</html>
```
You can also see the application in browser by using hostname `green.cy.guru` and `blue.cy.guru`


## Delete Services, Deployments and Ingress.
```command
kubectl delete deploy blue green
kubectl delete svc blue green
kubectl delete ing path
```


### ALB and ELB ingress controller.

ELB loadbalancer is level 4 base loadbalancer, it takes TCP/HTTP request and forward the request to all the instances attached to it, on least used server basis.

Alb is for application loadbalancer. It basically suited for micro-service based architecture. It is level 7 based loadbalancer, it supports various various to route traffic to instance, based on host-header or path-based routing or host based.


Advantages of ALB over ELB

* Support for path-based routing like different route `cloudyuga.guru/foo` and `cloudyuga.guru/bar`. We can configure rules that forward requests based on the URL in the request. 

* It enables us to structure our application as smaller services, and route requests to the correct service based on the content of the URL.

* Along with path-base routing like we can do host-based routing like `foo.cloudyuga.guru` and `bar.cloudyuga.guru`. We can configure rules that forward requests based on the host field in the HTTP header. 

* It enables us to route requests to multiple domains using a single load balancer.

* It supports for routing requests to multiple applications on a single EC2 instance. We can register each instance or IP address with the same target group using multiple ports.

* Support for monitoring the health of each service independently, as health checks are defined at the target group level and many CloudWatch metrics are reported at the target group level. 

* Attaching a target group to an Auto Scaling group enables us to scale each service dynamically based on demand.



![ALB](https://raw.githubusercontent.com/kubernetes-sigs/aws-alb-ingress-controller/master/docs/imgs/controller-design.png)

#### Ingress Creation

This section describes each step (circle) above. This example demonstrates satisfying 1 ingress resource.

[1]: The controller watches for ingress events from the API server. When it finds ingress resources that satisfy its requirements, it begins the creation of AWS resources.

[2]: An ALB (ELBv2) is created in AWS for the new ingress resource. This ALB can be internet-facing or internal. You can also specify the subnets it's created in using annotations.

[3]: Target Groups are created in AWS for each unique Kubernetes service described in the ingress resource.

[4]: Listeners are created for every port detailed in your ingress resource annotations. When no port is specified, sensible defaults (80 or 443) are used. Certificates may also be attached via annotations.

[5]: Rules are created for each path specified in your ingress resource. This ensures traffic to a specific path is routed to the correct Kubernetes Service.


#### Example for ingress resource.

```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: echoserver
  namespace: echoserver
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/tags: Environment=dev,Team=test
spec:
  rules:
    - host: echoserver.cloudyuga.guru
      http:
        paths:
          - path: /
            backend:
              serviceName: echoserver
	      servicePort: 80
```

Here `echoserver.cloudyuga.guru` will be routed to k8s service named `echoserver`. We are using various annotation to configure the alb created by ingress rules.


Reference:

* https://github.com/kubernetes-sigs/aws-alb-ingress-controller
* https://docs.aws.amazon.com/elasticloadbalancing/latest/application/introduction.html
