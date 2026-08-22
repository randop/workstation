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
