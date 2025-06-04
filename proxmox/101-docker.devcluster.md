# docker.devcluster LXC

## Installation
```sh
apk add openssh
rc-update add sshd
rc-service sshd start

apk add shadow
adduser johnpaul
apk add bash
chsh -s /bin/bash johnpaul

apk add bash
apk add vim

cp -v /root/.ssh/authorized_keys /home/johnpaul/.ssh/
chown johnpaul:johnpaul /home/johnpaul/.ssh/authorized_keys

apk add docker
rc-update add docker default
service docker start
addgroup johnpaul docker
apk add docker-cli-compose
docker info
```
