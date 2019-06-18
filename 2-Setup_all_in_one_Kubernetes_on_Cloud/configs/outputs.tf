output "Your Master_Droplet_Addresses" { 
 value = "${digitalocean_droplet.master.ipv4_address}"
}
output "Your Worker_Droplet_Addresses" {
 value = "${digitalocean_droplet.worker.ipv4_address}"
}

 

















