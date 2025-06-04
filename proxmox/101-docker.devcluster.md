# docker.devcluster LXC

## Installation
```sh
apk add openssh
rc-update add sshd
rc-service sshd start

apk add shadow
adduser johnpaul
apk add bash
apk add vim
chsh -s /bin/bash johnpaul

mkdir -p /home/johnpaul/.ssh
chmod 700 /home/johnpaul/.ssh
cp -v /root/.ssh/authorized_keys /home/johnpaul/.ssh/
chown johnpaul:johnpaul /home/johnpaul/.ssh/authorized_keys

apk add docker
rc-update add docker default
service docker start
addgroup johnpaul docker
apk add docker-cli-compose
docker info
```

### Test docker setup as a non-root user
> [https://docs.docker.com/engine/install/linux-postinstall/](https://docs.docker.com/engine/install/linux-postinstall/)
```bash
docker run --rm hello-world
```
