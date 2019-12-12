# Cluster creation

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

- SSH to Master Droplet

```command
ssh root@$MASTER_PUBLIC_IP
```

- SSH to Worker Droplet

```command
ssh root@$WORKER_PUBLIC_IP
```
