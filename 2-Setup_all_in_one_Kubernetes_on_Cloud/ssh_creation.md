# Cluster creation

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
