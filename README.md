# sshhole-lab

An SSH hole lab for learning and experimentation. Read the [original publication](https://sshhole.com/).

![sshole](./images/sshhole.png)

## Run the lab

Start the vulnerable SSH server in a local container:

```bash
docker run --rm -it -p 2222:22 ghcr.io/leonjza/sshhole-lab:latest
```

In another terminal, connect to the container:

```bash
ssh -o StrictHostKeyChecking=no -o PreferredAuthentications=password -o PubkeyAuthentication=no -p 2222 alpine@localhost
```

When prompted, enter a password longer than 256 characters twice.

