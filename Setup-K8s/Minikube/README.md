### Requirements to run `Minikube`
* [kubectl](https://kubernetes.io/docs/tasks/kubectl/install/)
    * It is binary to access any Kubernetes cluster. Generally it is installed before starting the `Minikube` but we can install it later as well. If `kubectl` is not found while installing the `Minikube`, we would get a warning message; which can be ignored safely but we would have to install it later. We would explore about `kubectl` in future chapters. 
* macOS
    * [xhyve driver](https://github.com/kubernetes/minikube/blob/master/docs/drivers.md#xhyve-driver), [VirtualBox](https://www.virtualbox.org/wiki/Downloads) or [VMware Fusion](https://www.vmware.com/products/fusion)
* Linux
    * [VirtualBox](https://www.virtualbox.org/wiki/Downloads) or [KVM](https://github.com/kubernetes/minikube/blob/master/docs/drivers.md#kvm-driver)
* Windows
    * [VirtualBox](https://www.virtualbox.org/wiki/Downloads) or [Hyper-V](https://github.com/kubernetes/minikube/blob/master/docs/drivers.md#hyperV-driver)
* VT-x/AMD-v virtualization must be enabled in BIOS
* Internet connection on first run

## 5.1 Minikube Installation

### Linux (Ubuntu 16.04)

#### Installing the Hypervisor (VirtualBox)
```
$ sudo apt-get install virtualbox
```

#### Installing Minikube 
We can download the latest release from [Minikube Release page](https://github.com/kubernetes/minikube/releases). Once downloaded we need to make it executable and copy it in the PATH. 
```
$ curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && chmod +x minikube && sudo mv minikube /usr/local/bin/

```

#### Start Minikube
With `minikube start` command, we can start `Minikube`. 

```
$ minikube start
```

#### Check the status
With `minikube status` command, we can see the status of `Minikube`. 

```
$ minikube status
```

#### Stop the Minikube.
With `minikube stop` command, we can stop `Minikube`. 

```
$ minikube stop

Stopping local Kubernetes cluster...
Machine stopped.
```

### Mac

#### Installing Minikube 

```
$ brew cask install minikube
```

#### Start Minikube
With `minikube start` command, we can start `Minikube`. 

```
❯ minikube start
Starting local Kubernetes cluster...
Starting VM...
SSH-ing files into VM...
Setting up certs...
Starting cluster components...
Connecting to cluster...
Setting up kubeconfig...
Kubectl is now configured to use the cluster.
```

#### Check the status  
With `minikube status` command, we can see the status of `Minikube`. 

```
$ minikube status
minikubeVM: Running
localkube: Running
```

#### Stop the Minikube
With `minikube stop` command, we can stop `Minikube`. 

```
$ minikube stop
Stopping local Kubernetes cluster...
Machine stopped.
```

### Windows 

Pleae note that `Window` support is currently in the experimental and might have some issues. 

#### Go to [`Minikube's` release page](https://github.com/kubernetes/minikube/releases)

#### Download the `Minikube's` binary from `Distribution` section.

#### Add the downloaded `Minikube's` binary to your `PATH`.

#### Execute the  `minikube start` command, to start `Minikube`.
