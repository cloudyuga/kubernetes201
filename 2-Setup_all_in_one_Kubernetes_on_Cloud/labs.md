# Kubernetes Setup In UpCloud

# Cluster creation

## Prerequisites.


- You Must have an UpCloud account or create a new one.


### Create SSH Keys.


```command
ssh-keygen -t rsa
```
```
Generating public/private rsa key pair.
Enter file in which to save the key (~/.ssh/id_rsa): 
Created directory '~/.ssh/'.
Enter passphrase (empty for no passphrase): 
Enter same passphrase again: 
Your identification has been saved in ~/.ssh/id_rsa.
Your public key has been saved in ~/.ssh/id_rsa.pub.
The key fingerprint is:
SHA256:lCVaexVBIwHo++NlIxccMW5b6QAJa+ZEr9ogAElUFyY root@3b9a273f18b5
The key's randomart image is:
+---[RSA 2048]----+
|++.E ++o=o*o*o   |
|o   +..=.B = o   |
|.    .* = * o    |
| .   =.o + *     |
|  . . o.S + .    |
|   . +.    .     |
|    . ... =      |
|        o= .     |
|       ...       |
+----[SHA256]-----+

```

- You must link above created SSH key to [UpCloud](https://hub.upcloud.com/account/ssh)

- We are asuming your public keys and private keys are located at `~/.ssh/id_rsa.pub` and `~/.ssh/id_rsa`


## Create VMs on UpCloud.

- Login to your [UpCloud](https://hub.upcloud.com/deploy) account and deploy two servers.

```
details:
 Name:
 Server1:  Master
 Server2:  Worker
 Template: Ubuntu Server 18.04 LTS (Bionic Beaver
 Core     : 2
 RAM       : 4
```

Once creation of the VM completes, you will get the IP address of VM. SSH into VM to perform further labs.



- Start `tmux` on container terminal.

```command
tmux
```

-  SSH to Master Droplet

```command
ssh root@$MASTER_PUBLIC_IP
```

-  SSH to Worker Droplet

```command
ssh root@$WORKER_PUBLIC_IP
```

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
#### Deploy the `Calico pod network` on master node using following command.

```command
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/62e44c867a2846fefb68bd5f178daf4da3095ccb/Documentation/kube-flannel.yml

```
####  Join the worker node to cluster. In the terminal of both `Node1` and `Node2` execute the command that was output by `kubeadm init` command.

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

