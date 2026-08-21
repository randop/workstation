#!/usr/bin/env bash
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

