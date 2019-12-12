# Cluster creation

### Creating a K8s Cluster Using kubeadm.

#### Install `kubelet` and `kubeadm` on both nodes using following commands.

```command
apt-get update && apt-get install -y apt-transport-https
```

```command
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
```

```command
apt-get update
apt-get install -y kubelet kubeadm kubectl
```

#### Install `Docker` on both nodes using following commands.

```command
sudo apt-get update
sudo apt-get install docker.io
```

#### Initializing `Master` instance by using following command. (execute only on Master node).

```command
kubeadm init --pod-network-cidr=10.244.0.0/16
```

Please note down the `kubeadm join` command that will be shown as output of `kubeadm init` command.

#### Configure the `Master` node

```command
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

#### Deploy the `Flannel pod network` on master node using following command.

```command
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/62e44c867a2846fefb68bd5f178daf4da3095ccb/Documentation/kube-flannel.yml

```

#### Join the worker node to cluster. In the terminal of both `Node1` and `Node2` execute the command that was output by `kubeadm init` command.

```command
sudo su
kubeadm join --token <token> <master-ip>:<master-port> --discovery-token-ca-cert-hash sha256:<hash>
```

#### Check available nodes in the cluster.

```command
kubectl get nodes
```

#### Check the cluster information.

```command
kubectl cluster-info
```

#### Check the status of cluster components.

```command
kubectl get componentstatuses
```
