# LXC

## Setup and Installation

### Ensure user namespaces are allowed
```shell
sysctl kernel.unprivileged_userns_clone   # should be 1
# If 0:
echo "kernel.unprivileged_userns_clone=1" | sudo tee /etc/sysctl.d/80-lxc-userns.conf
sudo sysctl --system
```

### Install packages
```shell
pacman -S lxc lxcfs
```
Package descriptions:
```
world/lxc 1:7.0.0-2
    Linux Containers

world/lxcfs 7.0.0-2
    FUSE filesystem for LXC
```

### Allocate subordinate UID/GID ranges
As root, give your user a free range (100000:65536 is the most common):
```shell
# Check existing ranges first
cat /etc/subuid /etc/subgid

# example subuid subgid:
# randolph:100000:65536
# randolph:100000:65536

# Add the range if not yet
usermod --add-subuids 100000-165535 --add-subgids 100000-165535 <REPLACE_WITH_USERNAME>

# Log out and log back in (or reboot). Verify:
grep <YOURUSER> /etc/subuid /etc/subgid
```

### Create the user LXC configuration
```shell
mkdir -p ~/.config/lxc ~/.local/share/lxc ~/.cache/lxc

cat << EOF | tee ~/.config/lxc/default.conf
lxc.include = /etc/lxc/default.conf

# ID mapping
lxc.idmap = u 0 100000 65536
lxc.idmap = g 0 100000 65536

# Networking
lxc.net.0.type = veth
lxc.net.0.link = lxcbr0
lxc.net.0.flags = up
lxc.net.0.hwaddr = 00:16:3e:xx:xx:xx

# for unprivileged containers
lxc.mount.auto = proc:mixed sys:ro cgroup:mixed
lxc.apparmor.profile = unconfined
EOF
```

### Allow nonroot user to create network interfaces
```shell
echo "randolph veth lxcbr0 10" >> /etc/lxc/lxc-usernet
```
