#### Install `kubelet` and `kubeadm` on all the instances i.e. Manager, Node1 and Node2 using following commands.
```
apt-get update && apt-get install -y apt-transport-https
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
apt-get update
apt-get install -y kubelet kubeadm kubectl
```
#### Install `Docker` on all the instances i.e. Manager, Node1 and Node2 using following commands.
```
sudo apt-get update
sudo apt-get install docker.io
```
#### Initializing `Master` instance by using following command. (execute only on Master node).
```
$ kubeadm init --pod-network-cidr=192.168.0.0/16
```
Please note down the `kubeadm join` command that will be shown as output of `kubeadm init` command.

#### Configure the `Master` node
```
$ mkdir -p $HOME/.kube
$ sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
$ sudo chown $(id -u):$(id -g) $HOME/.kube/config
```
#### Deploy the `Calico pod network` using following command.
```
$ kubectl apply -f https://docs.projectcalico.org/v3.0/getting-started/kubernetes/installation/hosted/kubeadm/1.7/calico.yaml
```
####  Join the worker node to cluster. In the terminal of both `Node1` and `Node2` execute the command that was output by `kubeadm init` command.

```
$ sudo su
$ kubeadm join --token <token> <master-ip>:<master-port> --discovery-token-ca-cert-hash sha256:<hash>
```

#### Check available nodes in the cluster.
```
$ kubectl get nodes
```
#### Check the cluster information.
```
$ kubectl cluster-info
```
#### Check the status of cluster components.
```
$ kubectl get componentstatuses
```
