

# istio

Istio installation.


```command
curl -L https://git.io/getLatestIstio | ISTIO_VERSION=1.0.5 sh -
cd istio-1.*
cp bin/istioctl /usr/bin/.
```

- Install required CRD.

```command
kubectl apply -f install/kubernetes/helm/istio/templates/crds.yaml
```
- Update `install/kubernetes/istio-demo.yaml`. find `istio-ingressgateway` service,  `grafana` service, `prometheus` service, `servicegraph` service and update `type: NodePort` in it.


- Deploy the Istio Service Mesh.

```command
kubectl apply -f install/kubernetes/istio-demo.yaml

- Confirm the Pods running.

```command
kubectl get pods -n istio-system
```
```command
kubectl get svc -n istio-system
```
- Label the Default namespace to enable `sidecar injection`.The Istio-Sidecar-injector will automatically inject Envoy containers into your application pods. The injector assumes the application pods are running in namespaces labeled with `istio-injection=enabled`

```command
kubectl label namespace default istio-injection=enabled
```

- Set the GATEWAY_URL.

```
export INGRESS_HOST=<node IP>
```
```command

export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')

export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}')

export GATEWAY_URL=$INGRESS_HOST:$INGRESS_PORT
```

- Deploy Bookinfo application:

```
https://istio.io/docs/examples/bookinfo/
```
```yaml
# Copyright 2017 Istio Authors
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

##################################################################################################
# Details service
##################################################################################################
apiVersion: v1
kind: Service
metadata:
  name: details
  labels:
    app: details
    service: details
spec:
  ports:
  - port: 9080
    name: http
  selector:
    app: details
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: details-v1
  labels:
    app: details
    version: v1
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: details
        version: v1
    spec:
      containers:
      - name: details
        image: istio/examples-bookinfo-details-v1:1.13.0
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 9080
---
##################################################################################################
# Ratings service
##################################################################################################
apiVersion: v1
kind: Service
metadata:
  name: ratings
  labels:
    app: ratings
    service: ratings
spec:
  ports:
  - port: 9080
    name: http
  selector:
    app: ratings
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: ratings-v1
  labels:
    app: ratings
    version: v1
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: ratings
        version: v1
    spec:
      containers:
      - name: ratings
        image: istio/examples-bookinfo-ratings-v1:1.13.0
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 9080
---
##################################################################################################
# Reviews service
##################################################################################################
apiVersion: v1
kind: Service
metadata:
  name: reviews
  labels:
    app: reviews
    service: reviews
spec:
  ports:
  - port: 9080
    name: http
  selector:
    app: reviews
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: reviews-v1
  labels:
    app: reviews
    version: v1
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: reviews
        version: v1
    spec:
      containers:
      - name: reviews
        image: istio/examples-bookinfo-reviews-v1:1.13.0
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 9080
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: reviews-v2
  labels:
    app: reviews
    version: v2
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: reviews
        version: v2
    spec:
      containers:
      - name: reviews
        image: istio/examples-bookinfo-reviews-v2:1.13.0
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 9080
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: reviews-v3
  labels:
    app: reviews
    version: v3
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: reviews
        version: v3
    spec:
      containers:
      - name: reviews
        image: istio/examples-bookinfo-reviews-v3:1.13.0
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 9080
---
##################################################################################################
# Productpage services
##################################################################################################
apiVersion: v1
kind: Service
metadata:
  name: productpage
  labels:
    app: productpage
    service: productpage
spec:
  ports:
  - port: 9080
    name: http
  selector:
    app: productpage
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: productpage-v1
  labels:
    app: productpage
    version: v1
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: productpage
        version: v1
    spec:
      containers:
      - name: productpage
        image: istio/examples-bookinfo-productpage-v1:1.13.0
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 9080
---

```

```command
kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml
```
- Create an ingress gateway for this application:

```yaml

apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: bookinfo-gateway
spec:
  selector:
    istio: ingressgateway # use istio default controller
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "*"
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: bookinfo
spec:
  hosts:
  - "*"
  gateways:
  - bookinfo-gateway
  http:
  - match:
    - uri:
        exact: /productpage
    - uri:
        exact: /login
    - uri:
        exact: /logout
    - uri:
        prefix: /api/v1/products
    route:
    - destination:
        host: productpage
        port:
          number: 9080

```


```command
kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml
```

To confirm that the Bookinfo application is accessible from outside the cluster, run the following curl command:
```command
curl -s http://${GATEWAY_URL}/productpage | grep -o "<title>.*</title>"
```
```output
<title>Simple Bookstore App</title>
```
To access through browser:

```command
http://68.183.83.147:31380/productpage 
```

### Apply default destination rules.

```command
kubectl apply -f samples/bookinfo/networking/destination-rule-all.yaml
```
```yaml
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: productpage
spec:
  host: productpage
  subsets:
  - name: v1
    labels:
      version: v1
---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: reviews
spec:
  host: reviews
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
  - name: v3
    labels:
      version: v3
---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: ratings
spec:
  host: ratings
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
  - name: v2-mysql
    labels:
      version: v2-mysql
  - name: v2-mysql-vm
    labels:
      version: v2-mysql-vm
---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: details
spec:
  host: details
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
---

```



### Request Routing:

https://istio.io/docs/tasks/traffic-management/request-routing/

- Apply a virtual service.

Three different versions of one of the microservices, reviews, have been deployed and are running concurrently. To illustrate the problem this causes, access the Bookinfo app’s /productpage in a browser and refresh several times. You’ll notice that sometimes the book review output contains star ratings and other times it does not

To route to one version only, you apply virtual services that set the default version for the microservices. In this case, the virtual services will route all traffic to v1 of each microservice.

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: productpage
spec:
  hosts:
  - productpage
  http:
  - route:
    - destination:
        host: productpage
        subset: v1
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: reviews
spec:
  hosts:
  - reviews
  http:
  - route:
    - destination:
        host: reviews
        subset: v1
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: ratings
spec:
  hosts:
  - ratings
  http:
  - route:
    - destination:
        host: ratings
        subset: v1
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: details
spec:
  hosts:
  - details
  http:
  - route:
    - destination:
        host: details
        subset: v1
---
```

```command
 kubectl apply -f samples/bookinfo/networking/virtual-service-all-v1.yaml
 ```



- Test the new routing configuration
Refresh the page, reviews part of the page displays with no rating stars.


## Lab To Demonstrate Distributed Tracing :

**Jaeger is Distributed Tracing System. Here we will track a single request through our internal systems to see how time is spent.**

Export the jaeger endpoint: 

```command
kubectl port-forward -n istio-system $(kubectl get pod -n istio-system -l app=jaeger -o jsonpath='{.items[0].metadata.name}') 16686:16686
```

Visit : <a href="http://localhost:16686"> localhost:16686 </a> to see jaeger dashboard.

### Generating traces using the Bookinfo sample


- When the Bookinfo application is up and running, access `http://$GATEWAY_URL/productpage` one or more times to generate trace information.
- To send a 100 requests to the productpage service, use the following command:

```command
for i in `seq 1 100`; do curl -s -o /dev/null http://$GATEWAY_URL/productpage; done
```

-From the left-hand pane of the dashboard, select productpage from the Service drop-down list and click Find Traces.

-The trace is comprised of a set of spans, where each span corresponds to a Bookinfo service, invoked during the execution of a /productpage request, or internal Istio component.


 


### Traffic Shifting


**To get started, run this command to route all traffic to the v1 version of each microservice.**

```command
kubectl apply -f samples/bookinfo/networking/virtual-service-all-v1.yaml
```

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: productpage
spec:
  hosts:
  - productpage
  http:
  - route:
    - destination:
        host: productpage
        subset: v1
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: reviews
spec:
  hosts:
  - reviews
  http:
  - route:
    - destination:
        host: reviews
        subset: v1
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: ratings
spec:
  hosts:
  - ratings
  http:
  - route:
    - destination:
        host: ratings
        subset: v1
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: details
spec:
  hosts:
  - details
  http:
  - route:
    - destination:
        host: details
        subset: v1
---

```

- Open the Bookinfo site in your browser.

*Notice that the reviews part of the page displays with no rating stars.This is because you configured Istio to route all traffic for the reviews service to the version reviews:v1 and this version of the service does not access the star ratings service.*

```
http://68.183.83.147:31380/productpage
```

**Transfer 50% of the traffic from reviews:v1 to reviews:v3 with the following configuration:**

```command
kubectl apply -f samples/bookinfo/networking/virtual-service-reviews-50-v3.yaml
```

```yaml

apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: reviews
spec:
  hosts:
    - reviews
  http:
  - route:
    - destination:
        host: reviews
        subset: v1
      weight: 50
    - destination:
        host: reviews
        subset: v3
      weight: 50
      
  ```
 
  - Confirm the rule was replaced:
  
  ```command
  kubectl get virtualservice reviews -o yaml
  ```
  

***Refresh the /productpage in your browser and you now see red colored star ratings approximately 50% of the time. This is because the v3 version of reviews accesses the star ratings service, but the v1 version does not.***

**Assuming you decide that the reviews:v3 microservice is stable, you can route 100% of the traffic to reviews:v3 by applying this virtual service:**

```command
kubectl apply -f samples/bookinfo/networking/virtual-service-reviews-v3.yaml
```

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: reviews
spec:
  hosts:
    - reviews
  http:
  - route:
    - destination:
        host: reviews
        subset: v3
 ```
 
 ***Now when you refresh the /productpage you will always see book reviews with red colored star ratings for each review.***





