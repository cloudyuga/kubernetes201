#!/bin/bash
terraform destroy --force -var "pub_key=~/.ssh/id_rsa.pub" -var "pvt_key=~/.ssh/id_rsa"  -var "region=blr1" -var "ssh_fingerprint=$FINGERPRINT" -var "do_token=$TOKEN" -var "size=1gb" -var "tag=k8s"
rm -r terraform.tfstate* 

exit 0
