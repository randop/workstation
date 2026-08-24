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
pacman -S lxc lxcfs shadow
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
# fix permission using shadow
chmod u+s /usr/bin/newuidmap /usr/bin/newgidmap

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
```bash
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
lxc.mount.auto = proc:mixed sys:ro
lxc.apparmor.profile = unconfined
EOF
```

### Allow nonroot user to create network interfaces
```shell
echo "<REPLACE_WITH_USERNAME> veth lxcbr0 10" >> /etc/lxc/lxc-usernet
```

### Create bridge network and use dhcpcd
```shell
ip link add name lxcbr0 type bridge
ip link set eth0 master lxcbr0
ip link set eth0 up
ip link set lxcbr0 up

dhcpcd -k
# Stop any existing dhcpcd on eth0
dhcpcd -k eth0 2>/dev/null || true
killall dhcpcd 2>/dev/null || true

# Start dhcpcd on the bridge
dhcpcd lxcbr0

# check internet connection
ip addr show lxcbr0
ip route
ping -c 3 1.1.1.1
```

### Setup persistent s6 lxc network startup
```bash
mkdir -p /etc/s6/adminsv/lxc-network/dependencies.d

touch /etc/s6/adminsv/lxc-network/dependencies.d/udevadm
touch /etc/s6/adminsv/lxc-network/dependencies.d/network-detection
touch /etc/s6/adminsv/lxc-network/dependencies.d/dhcpcd

cat > /etc/s6/adminsv/lxc-network/type <<'EOF'
oneshot
EOF

cat > /etc/s6/adminsv/lxc-network/up <<'EOF'
#!/bin/execlineb -P
foreground { /usr/local/sbin/lxc-network.sh }
EOF

chmod +x /etc/s6/adminsv/lxc-network/up

cat > /usr/local/sbin/lxc-network.sh <<'EOF'
#!/bin/sh
ip link add name lxcbr0 type bridge
ip link set eth0 master lxcbr0
ip link set eth0 up
ip link set lxcbr0 up
dhcpcd -k
dhcpcd -k eth0 2>/dev/null || true
killall dhcpcd 2>/dev/null || true
dhcpcd lxcbr0
EOF

chmod +x /usr/local/sbin/lxc-network.sh

s6 repo sync && s6 set commit && s6 live install
```

### Setup cgroup delegation 
```bash
cat << EOF | tee /root/lxc-delegate.sh
#!/bin/sh
CG=/sys/fs/cgroup
USER=randolph

echo "+cpuset +cpu +io +memory +pids" > "$CG/cgroup.subtree_control" 2>/dev/null
mkdir -p "$CG/user/$USER"
chown "$USER:$USER" "$CG/user/$USER"
echo "+cpuset +cpu +io +memory +pids" > "$CG/user/$USER/cgroup.subtree_control"
sleep 1
chown "$USER:$USER" /sys/fs/cgroup/user/$USER/cgroup.procs
chown "$USER:$USER" /sys/fs/cgroup/user/$USER/cgroup.threads
chown "$USER:$USER" /sys/fs/cgroup/user/$USER/cgroup.subtree_control
EOF

chmod +x /root/lxc-delegate.sh
/root/lxc-delegate.sh
```

### Compile and install `cgjoin`
```bash
su -l randolph
mkdir -p ~/projects
cd ~/projects
git clone https://gitlab.com/randop/applications.git
cd applications/cgjoin
gcc -O2 -o cgjoin main.c

su -l root
cd /home/randolph/projects/applications/cgjoin
install -o root -g root -m 4755 cgjoin /usr/local/bin/cgjoin

```

### Provision arch linux guest container

#### check lxc configuration
```shell
lxc-checkconfig
```

```
LXC version 7.0.0

--- Namespaces ---
Namespaces: enabled
Utsname namespace: enabled
Ipc namespace: enabled
Pid namespace: enabled
User namespace: enabled
Network namespace: enabled
Namespace limits:
  cgroup: 62511
  ipc: 62511
  mnt: 62511
  net: 62511
  pid: 62511
  time: 62511
  user: 62511
  uts: 62511

--- Control groups ---
Cgroups: enabled
Cgroup namespace: enabled
Cgroup v1 mount points: 
Cgroup v2 mount points: 
 - /sys/fs/cgroup
Cgroup device: enabled
Cgroup sched: enabled
Cgroup cpu account: enabled
Cgroup memory controller: enabled
Cgroup cpuset: enabled

--- Misc ---
Veth pair device: enabled, loaded
Macvlan: enabled, not loaded
Vlan: enabled, loaded
Bridges: enabled, loaded
Advanced netfilter: enabled, loaded
CONFIG_IP_NF_TARGET_MASQUERADE: enabled, not loaded
CONFIG_IP6_NF_TARGET_MASQUERADE: enabled, not loaded
CONFIG_NETFILTER_XT_TARGET_CHECKSUM: enabled, not loaded
CONFIG_NETFILTER_XT_MATCH_COMMENT: enabled, not loaded
FUSE (for use with lxcfs): enabled, not loaded

--- Checkpoint/Restore ---
checkpoint restore: enabled
CONFIG_FHANDLE: enabled
CONFIG_EVENTFD: enabled
CONFIG_EPOLL: enabled
CONFIG_UNIX_DIAG: enabled
CONFIG_INET_DIAG: enabled
CONFIG_PACKET_DIAG: enabled
CONFIG_NETLINK_DIAG: enabled
File capabilities: enabled

Note: Before booting a new kernel, you can check its configuration with:

  CONFIG=/path/to/config /usr/bin/lxc-checkconfig
```

```bash
lxc-create -n arch-test -t download -- \
             --server ca.images.linuxcontainers.org \
             --dist archlinux \
             --release current \
             --arch amd64

cgjoin
echo $fish_pid > /sys/fs/cgroup/user/randolph/cgroup.procs

mkdir -pv /sys/fs/cgroup/user/randolph/lxc

# fish
echo $fish_pid > /sys/fs/cgroup/user/randolph/lxc/cgroup.procs

## or bash
# echo $$ > /sys/fs/cgroup/user/randolph/lxc/cgroup.procs

cat /proc/self/cgroup
# 0::/user/randolph/lxc

lxc-start -n arch-test -F -l DEBUG
```

```
systemd 261.2-1-arch running in system mode (+PAM +AUDIT -SELINUX +APPARMOR -IMA +IPE +SMACK +SECCOMP +GCRYPT +GNUTLS +OPENSSL +ACL +BLKID +CURL +ELFUTILS +FIDO2 +IDN2 +KMOD +LIBCRYPTSETUP +LIBCRYPTSETUP_PLUGINS +LIBFDISK +PCRE2 +PWQUALITY +P11KIT +QRENCODE +TPM2 +BZIP2 +LZ4 +XZ +ZLIB +ZSTD +BPF_FRAMEWORK +BTF +XKBCOMMON +UTMP +LIBARCHIVE)
Detected virtualization lxc.
Detected architecture x86-64.
Detected first boot.

Welcome to Arch Linux!

Initializing machine ID from random generator.
Applying preset policy.
Failed to preset all unit: Unit /run/systemd/system/systemd-pstore.service is masked
Failed to preset all unit: Unit /run/systemd/system/systemd-journald-audit.socket is masked
Unit /run/systemd/system/systemd-pstore.service is masked, ignoring.
Unit /run/systemd/system/systemd-journald-audit.socket is masked, ignoring.
Created symlink '/etc/systemd/system/ctrl-alt-del.target' → '/usr/lib/systemd/system/reboot.target'.
Created symlink '/etc/systemd/system/factory-reset.target.wants/systemd-tpm2-clear.service' → '/usr/lib/systemd/system/systemd-tpm2-clear.service'.
Created symlink '/etc/systemd/system/sysinit.target.wants/systemd-boot-update.service' → '/usr/lib/systemd/system/systemd-boot-update.service'.
Created symlink '/etc/systemd/system/sockets.target.wants/systemd-mountfsd.socket' → '/usr/lib/systemd/system/systemd-mountfsd.socket'.
Created symlink '/etc/systemd/system/multi-user.target.wants/remote-integritysetup.target' → '/usr/lib/systemd/system/remote-integritysetup.target'.
Created symlink '/etc/systemd/system/sockets.target.wants/systemd-nsresourced.socket' → '/usr/lib/systemd/system/systemd-nsresourced.socket'.
Created symlink '/etc/systemd/system/sockets.target.wants/systemd-report-cgroup.socket' → '/usr/lib/systemd/system/systemd-report-cgroup.socket'.
Created symlink '/etc/systemd/system/dbus-org.freedesktop.home1.service' → '/usr/lib/systemd/system/systemd-homed.service'.
Created symlink '/etc/systemd/system/multi-user.target.wants/systemd-homed.service' → '/usr/lib/systemd/system/systemd-homed.service'.
Created symlink '/etc/systemd/system/systemd-homed.service.wants/systemd-homed-activate.service' → '/usr/lib/systemd/system/systemd-homed-activate.service'.
Created symlink '/etc/systemd/system/multi-user.target.wants/remote-veritysetup.target' → '/usr/lib/systemd/system/remote-veritysetup.target'.
Created symlink '/etc/systemd/system/sysinit.target.wants/systemd-sysext.service' → '/usr/lib/systemd/system/systemd-sysext.service'.
Created symlink '/etc/systemd/system/sysinit.target.wants/systemd-confext.service' → '/usr/lib/systemd/system/systemd-confext.service'.
Created symlink '/etc/systemd/system/dbus-org.freedesktop.timesync1.service' → '/usr/lib/systemd/system/systemd-timesyncd.service'.
Created symlink '/etc/systemd/system/sysinit.target.wants/systemd-timesyncd.service' → '/usr/lib/systemd/system/systemd-timesyncd.service'.
Created symlink '/etc/systemd/system/sockets.target.wants/systemd-report-basic.socket' → '/usr/lib/systemd/system/systemd-report-basic.socket'.
Created symlink '/etc/systemd/system/multi-user.target.wants/remote-cryptsetup.target' → '/usr/lib/systemd/system/remote-cryptsetup.target'.
Created symlink '/etc/systemd/system/sysinit.target.wants/systemd-boot-clear-sysfail.service' → '/usr/lib/systemd/system/systemd-boot-clear-sysfail.service'.
Created symlink '/etc/systemd/system/multi-user.target.wants/machines.target' → '/usr/lib/systemd/system/machines.target'.
Queued start job for default target Graphical Interface.
[  OK  ] Created slice Slice /system/container-getty.
[  OK  ] Created slice Slice /system/dirmngr.
[  OK  ] Created slice Slice /system/getty.
[  OK  ] Created slice Slice /system/gpg-agent.
[  OK  ] Created slice Slice /system/gpg-agent-browser.
[  OK  ] Created slice Slice /system/gpg-agent-extra.
[  OK  ] Created slice Slice /system/gpg-agent-ssh.
[  OK  ] Created slice Slice /system/keyboxd.
[  OK  ] Created slice Slice /system/modprobe.
[  OK  ] Created slice User and Session Slice.
[  OK  ] Started Dispatch Password Requests to Console Directory Watch.
[  OK  ] Started Forward Password Requests to Wall Directory Watch.
[  OK  ] Reached target Image Downloads.
[  OK  ] Reached target Local Integrity Protected Volumes.
[  OK  ] Reached target Path Units.
[  OK  ] Reached target Remote Encrypted Volumes.
[  OK  ] Reached target Remote File Systems.
[  OK  ] Reached target Remote Integrity Protected Volumes.
[  OK  ] Reached target Remote Verity Protected Volumes.
[  OK  ] Reached target Slice Units.
[  OK  ] Reached target Swaps.
[  OK  ] Reached target Local Verity Protected Volumes.
[  OK  ] Listening on Device-mapper event daemon FIFOs.
[  OK  ] Listening on Query the User Interactively for a Password.
[  OK  ] Listening on Process Core Dump Socket.
[  OK  ] Listening on Credential Encryption/Decryption.
[  OK  ] Listening on Factory Reset Management.
[  OK  ] Listening on Hostname Service Socket.
[  OK  ] Listening on Journal Socket (/dev/log).
[  OK  ] Listening on Journal Sockets.
[  OK  ] Listening on DDI File System Mounter Socket.
[  OK  ] Listening on Console Output Muting Service Socket.
[  OK  ] Listening on Network Management Metrics Varlink Socket.
[  OK  ] Listening on Network Management Varlink Socket.
[  OK  ] Listening on Network Management Netlink Socket.
[  OK  ] Listening on Namespace Resource Manager Socket.
[  OK  ] Listening on Disk Repartitioning Service Socket.
[  OK  ] Listening on Report System Basic Metrics Socket.
[  OK  ] Listening on CGroup Report Varlink Socket.
[  OK  ] Listening on Resolve Monitor Varlink Socket.
[  OK  ] Listening on Resolve Service Varlink Socket.
[  OK  ] Listening on Simple Block Device Backed Storage Provider.
[  OK  ] Listening on Simple File System Backed Storage Provider.
[  OK  ] Listening on udev Control Socket.
[  OK  ] Listening on udev Kernel Socket.
[  OK  ] Listening on udev Varlink Socket.
[  OK  ] Listening on User Database Manager Socket.
         Mounting POSIX Message Queue File System...
         Mounting Kernel Debug File System...
tmp.mount: x-systemd.graceful-option=usrquota specified, but option is not available, suppressing.
         Mounting Temporary Directory /tmp...
         Mounting Kernel Configuration File System...
         Starting Journal Service...
         Starting Generate Network Units from Kernel Command Line...
         Starting Remount Root and Kernel File Systems...
         Starting Apply Kernel Variables...
         Starting Create Static Device Nodes in /dev gracefully...
[  OK  ] Reached target Local Encrypted Volumes.
         Starting Load udev Rules from Credentials...
         Starting Coldplug All udev Devices...
[  OK  ] Mounted POSIX Message Queue File System.
sys-kernel-debug.mount: Mount process exited, code=exited, status=32/n/a
sys-kernel-debug.mount: Failed with result 'exit-code'.
[FAILED] Failed to mount Kernel Debug File System.
See 'systemctl status sys-kernel-debug.mount' for details.
[  OK  ] Mounted Temporary Directory /tmp.
sys-kernel-config.mount: Mount process exited, code=exited, status=32/n/a
sys-kernel-config.mount: Failed with result 'exit-code'.
[FAILED] Failed to mount Kernel Configuration File System.
See 'systemctl status sys-kernel-config.mount' for details.
[  OK  ] Finished Generate Network Units from Kernel Command Line.
[  OK  ] Finished Remount Root and Kernel File Systems.
[  OK  ] Finished Apply Kernel Variables.
[  OK  ] Reached target Preparation for Network.
[  OK  ] Listening on Network Management Resolve Hook Socket.
[  OK  ] Reached target First Boot Complete.
[  OK  ] Finished Load udev Rules from Credentials.
         Starting Load Kernel Module tun...
         Starting User Database Manager...
[  OK  ] Started Journal Service.
         Starting Flush Journal to Persistent Storage...
[  OK  ] Finished Load Kernel Module tun.
         Starting Namespace Resource Manager...
[  OK  ] Started User Database Manager.
[  OK  ] Started Namespace Resource Manager.
[  OK  ] Finished Flush Journal to Persistent Storage.
[  OK  ] Finished Create Static Device Nodes in /dev gracefully.
         Starting Create System Users...
[  OK  ] Finished Create System Users.
         Starting Journal Log Access Socket...
         Starting Network Name Resolution...
[  OK  ] Reached target System Time Set.
         Starting Create Static Device Nodes in /dev...
[  OK  ] Listening on Journal Log Access Socket.
[  OK  ] Finished Create Static Device Nodes in /dev.
[  OK  ] Reached target Preparation for Local File Systems.
[  OK  ] Reached target Local File Systems.
[  OK  ] Reached target Virtual Machines and Containers.
[  OK  ] Listening on Boot Loader Control Service Socket.
[  OK  ] Listening on Disk Image Download Service Socket.
[  OK  ] Listening on System Extension Image Management.
         Starting Automatic Boot Loader Update...
         Starting Save Transient machine-id to Disk...
         Starting Create System Files and Directories...
         Starting Rule-based Manager for Device Events and Files...
         Starting Load JSON user/group Records from Credentials...
[  OK  ] Finished Automatic Boot Loader Update.
[  OK  ] Finished Load JSON user/group Records from Credentials.
[  OK  ] Started Network Name Resolution.
[  OK  ] Reached target Host and Network Name Lookups.
[  OK  ] Finished Save Transient machine-id to Disk.
[  OK  ] Started Rule-based Manager for Device Events and Files.
         Starting Network Management...
[  OK  ] Finished Create System Files and Directories.
         Starting Rebuild Dynamic Linker Cache...
         Starting Rebuild Journal Catalog...
         Starting Record System Boot/Shutdown in UTMP...
[  OK  ] Finished Record System Boot/Shutdown in UTMP.
[  OK  ] Finished Rebuild Journal Catalog.
[  OK  ] Finished Rebuild Dynamic Linker Cache.
         Starting Update is Completed...
[  OK  ] Finished Update is Completed.
[  OK  ] Started Network Management.
[  OK  ] Reached target Network.
         Starting Enable Persistent Storage in systemd-networkd...
[  OK  ] Finished Coldplug All udev Devices.
[  OK  ] Reached target System Initialization.
[  OK  ] Started Refresh existing PGP keys of archlinux-keyring regularly.
[  OK  ] Started Daily rotation of log files.
[  OK  ] Started Daily man-db regeneration.
[  OK  ] Started Daily verification of password and group files.
[  OK  ] Started Daily Cleanup of Temporary Directories.
[  OK  ] Reached target Timer Units.
[  OK  ] Listening on D-Bus System Message Bus Socket.
[  OK  ] Listening on User Login Management Varlink Socket.
[  OK  ] Listening on Virtual Machine and Container Registration Service Socket.
[  OK  ] Reached target Socket Units.
         Starting D-Bus System Message Bus...
[  OK  ] Finished Enable Persistent Storage in systemd-networkd.
[  OK  ] Started D-Bus System Message Bus.
[  OK  ] Reached target Basic System.
         Starting Incus - initializes Pacman keyring...
         Starting Home Area Manager...
         Starting User Login Management...
[  OK  ] Started Home Area Manager.
[  OK  ] Finished Home Area Activation.
         Starting Permit User Sessions...
[  OK  ] Finished Permit User Sessions.
[  OK  ] Started Console Getty.
[  OK  ] Started Container Getty on /dev/pts/1.
[  OK  ] Started Container Getty on /dev/pts/2.
[  OK  ] Started Container Getty on /dev/pts/3.
[  OK  ] Started Container Getty on /dev/pts/4.
[  OK  ] Reached target Login Prompts.
[  OK  ] Started User Login Management.
         Starting Hostname Service...
[  OK  ] Started Hostname Service.

Arch Linux 6.18.41-1-lts (console)

arch-test login:
```

### Attach and login as sub-user
```shell
cgjoin
echo $fish_pid > /sys/fs/cgroup/user/randolph/lxc/cgroup.procs
lxc-attach -n arch-test -l DEBUG -- su - johnpaul
```

### Check guest container info
```bash
hostnamectl
```
```bash
 Static hostname: ephesus9
       Icon name: computer-container
         Chassis: container 📦
      Machine ID: 00000000000000000000000000000000
         Boot ID: 39479bb28f3d41f3ae36a282c1865892
  Virtualization: lxc
Operating System: Arch Linux    
        OS Image: archlinux
OS Image Version: 2026.08.01
          Kernel: Linux 6.18.41-1-lts
    Architecture: x86-64
```

### Provision debian trixie lxc container
```bash
lxc-create -n trixie -t download -- \
                      --server ca.images.linuxcontainers.org \
                      --dist debian \
                      --release trixie \
                      --arch amd64
```

### Shutdown containers
```bash
lxc-stop -n arch-test
lxc-stop -n trixie
```
