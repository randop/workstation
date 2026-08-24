# ubuntu

LXC container system for ubuntu 22 LTS jammy

## Create
```bash
lxc-create -n ubuntu -t download -- \
                      --server ca.images.linuxcontainers.org \
                      --dist ubuntu \
                      --release jammy \
                      --arch amd64 \
                      --variant default
```

## Boot
```bash
lxc-start -n ubuntu -F
```

## Use root console
```bash
lxc-attach -n ubuntu -- su - root
```

## Use admin console
```bash
lxc-attach -n ubuntu -- su - johnpaul
```
