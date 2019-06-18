# Kubernetes Setup In Digital Ocean

# Cluster creation

## Prerequisites.


- You Must have a DigitalOcean account and `Personal Access Token` must be generated on [DigitalOcean](https://www.digitalocean.com/docs/api/create-personal-access-token/).


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

- You must link above created SSH key to [DigitalOcean] For that follow these [guidelines](https://www.digitalocean.com/docs/droplets/how-to/add-ssh-keys/create-with-openssh/)

- We are asuming your public keys and private keys are located at `~/.ssh/id_rsa.pub` and `~/.ssh/id_rsa`


## Create VMs for creating K8s on DigitalOcean.

- Start `tmux`. 

```command
tmux
```

- Create a new directory for Terraform backup.

```command
mkdir ~/terra-labs
```

- Copy all files from `0-Setup` to `~/terra-labs` directory.

```command
cp -r * ~/terra-labs/.
```

- Get into Directory.

```command
cd ~/terra-labs
```

- Get a Fingerprint of Your SSH public key.


```command
ssh-keygen -lf ~/.ssh/id_rsa.pub
```
```
2048 00:11:22:33:44:55:66:77:88:99:aa:bb:cc:dd:ee:ff /Users/username/.ssh/id_rsa.pub (RSA)
```


- Export a Fingerprint shown in above output.

```command
export FINGERPRINT=
```

- Export your DO Personal Access Token.


```command
export TOKEN=
```


- Export a Terraform Worskspace Name. Provide Your name in small letter.


```command
export WORKSPACE=
```

- Now take a look at the directory.


```command
ls
```
```
labs.md   creation.sh  destroy.sh  key.tf   nodes.tf  outputs.tf  provider.tf

```


- Run the script.

```command
./creation.sh
```

- Reload shell.


```command
source ~/.bashrc
```

Once creation of the VM completes, you will get the IP address of VM. SSH into VM to perform further labs.


-  SSH to Master Droplet

```command
ssh root@$MASTER_PUBLIC_IP
```

-  SSH to Worker Droplet

```command
ssh root@$WORKER_PUBLIC_IP
```

### Creating a K8s Cluster Using kubeadm.

#### Install `kubelet` and `kubeadm` on all the instances i.e. Manager, Node1 and Node2 using following commands.

```command
apt-get update && apt-get install -y apt-transport-https
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
apt-get update
apt-get install -y kubelet kubeadm kubectl
```
#### Install `Docker` on all the instances i.e. Manager, Node1 and Node2 using following commands.

```command
sudo apt-get update
sudo apt-get install docker.io
```
#### Initializing `Master` instance by using following command. (execute only on Master node).

```command
kubeadm init --pod-network-cidr=192.168.0.0/16
```
Please note down the `kubeadm join` command that will be shown as output of `kubeadm init` command.

#### Configure the `Master` node

```command
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```
#### Deploy the `Calico pod network` using following command.

```command
kubectl apply -f https://docs.projectcalico.org/v3.0/getting-started/kubernetes/installation/hosted/kubeadm/1.7/calico.yaml
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

### To Delete the Cluster. 

- Get into Directory.

```command
cd ~/terra-labs
```

- Run script

```command
./destroy.sh
```
