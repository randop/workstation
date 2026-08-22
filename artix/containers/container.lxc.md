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

### Install and setup Docker BuildX
```bash
# verify if build is available
docker buildx version
# github.com/docker/buildx v0.36.1 1d8dde89b8aba914e05e45366770736fea1fd690

# Create and use a new builder
docker buildx create --name container --driver docker-container --use

# Bootstrap it (starts the builder container)
docker buildx inspect --bootstrap

# if error:
# [+] Building 19.6s (1/1) FINISHED
# => ERROR [internal] booting buildkit                                                                                                                                   19.6s
# => => pulling image moby/buildkit:buildx-stable-1                                                                                                                      17.7s
# => => creating container buildx_buildkit_container0                                                                                                                     0.3s
# ------
#  > [internal] booting buildkit:
# ------
# ERROR: Error response from daemon: failed to create task for container: failed to create shim task: OCI runtime create failed: runc create failed: unable to start container process: error during container init: error mounting "sysfs" to rootfs at "/sys": mount src=sysfs, dst=/sys, dstFd=/proc/thread-self/fd/14, flags=MS_NOSUID|MS_NODEV|MS_NOEXEC: operation not permitted
docker buildx rm container 2>/dev/null || true
docker buildx rm mybuilder 2>/dev/null || true

# Use the default
docker buildx use default
docker buildx inspect --bootstrap

# check list
docker buildx ls

# test multi-platform build
docker buildx build --platform linux/amd64,linux/arm64 -t myimage:latest --push .

# Optional: Make Buildx the default builder permanently
docker buildx install
```
