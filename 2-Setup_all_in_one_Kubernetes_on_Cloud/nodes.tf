resource "digitalocean_droplet" "master" {
    name = "master-${terraform.workspace}"
    image = "ubuntu-16-04-x64"
    size = "${var.size}"
    tags = ["${var.tag}"]
    region = "${var.region}"
    ssh_keys = [
      "${var.ssh_fingerprint}"
    ]
    connection {
      user = "root"
      type = "ssh"
      private_key = "${file(var.pvt_key)}"
      timeout = "2m"
      }

   provisioner "local-exec" {
    command = "echo 'export MASTER_PUBLIC_IP=${digitalocean_droplet.master.ipv4_address}' >> address.txt"
   }
}

resource "digitalocean_droplet" "worker" {
    name = "worker-${terraform.workspace}"
    image = "ubuntu-16-04-x64"
    size = "${var.size}"
    tags = ["${var.tag}"]
    region = "${var.region}"
    ssh_keys = [
      "${var.ssh_fingerprint}"
    ]
    connection {
      user = "root"
      type = "ssh"
      private_key = "${file(var.pvt_key)}"
      timeout = "2m"
      }

   provisioner "local-exec" {
    command = "echo 'export WORKER_PUBLIC_IP=${digitalocean_droplet.worker.ipv4_address}' >> address.txt"
   }
}

