# container

LXC container system for docker

## Create
```bash
lxc-create -n container -t download -- \
                          --server ca.images.linuxcontainers.org \
                          --dist devuan \
                          --release excalibur \
                          --arch amd64
```

## Use admin console
```bash
lxc-attach -n container -- su - johnpaul
```

## Install and setup docker
```bash
sudo apt update
sudo apt install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: trixie
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Force the package to finish configuring (ignore the start failure for now):
sudo dpkg --configure -a
sudo apt -f install

# IMPORTANT: remove the ulimit on the file
sudo vim /etc/init.d/docker

# Start Docker manually:
sudo /etc/init.d/docker start

# check
sudo /etc/init.d/docker status
docker version

# delegate user to docker group
sudo usermod -aG docker $USER
newgrp docker

# test
docker run --rm hello-world

# Optional workaround on ulimit issue
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<EOF
{
  "default-ulimits": {
    "nofile": {
      "Name": "nofile",
      "Hard": 65536,
      "Soft": 65536
    }
  }
}
EOF

sudo /etc/init.d/docker restart
```
