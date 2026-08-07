# Artix Linux

## Partition disk
```shell
cfdisk /dev/nvme0n1
# 1G EFI
# remaining as Linux filesystem

mkfs.fat -F 32 /dev/nvme0n1p1
mkfs.ext4 -L ROOT /dev/nvme0n1p2
```

## Setup disk mounts
```shell
mount /dev/nvme0n1p2 /mnt
mkdir /mnt/boot
mount /dev/nvme0n1p1 /mnt/boot
```

## Install base
```shell
basestrap /mnt \
  base \
  s6-base \
  base-devel \
  elogind-s6 \
  linux-lts \
  linux-lts-headers \
  linux-firmware \
  nftables \
  nftables-s6 \
  dhcpcd \
  dhcpcd-s6 \
  nano \
  vim \
  htop \
  btop \
  refind
```

## Generate fstab
```shell
fstabgen -U /mnt >> /mnt/etc/fstab
```

## Chroot into the new system
```shell
artix-chroot /mnt
```

## Set timezone
```shell
ln -sf /usr/share/zoneinfo/UTC /etc/localtime
hwclock --systohc
```

## Set language locale
```shell
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
```

## Set hostname
```shell
echo "ephesus5" > /etc/hostname
```

## Set root password
```shell
passwd
```

## Install and configure bootloader
```shell
refind-install

cat > /boot/refind_linux.conf <<EOF
"Boot Artix"  "root=UUID=$(blkid -s UUID -o value /dev/nvme0n1p2) rw"
EOF

# Example of /boot/refind_linux.conf
#"Boot Artix" "root=UUID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx rw rootwait video=1920x1080 "
```

## Conclude base installation
```shell
exit
umount -R /mnt
reboot
```

## ⚠️ CRITICAL!!! Fix initial boot issues
> As of August 2026 using `artix-base-s6-20260402-x86_64.iso` ISO release have boot issues

#### 1. Press `Ctrl + Alt + F12` to use the recovery console and perform boot recovery
#### 2. Login as `root`
```shell
# Expect an error message on the following commands:
s6 repo sync && s6 set commit && s6 live install

TIMESTAMP=$(date +%s%N)
mkdir -pv /etc/s6/adminsv/default/contents.d
echo "bundle" > /etc/s6/adminsv/default/type
touch /etc/s6/adminsv/default/contents.d/boot
touch /etc/s6/adminsv/default/contents.d/tty1
touch /etc/s6/adminsv/default/contents.d/tty2
touch /etc/s6/adminsv/default/contents.d/tty3
touch /etc/s6/adminsv/default/contents.d/tty4
touch /etc/s6/adminsv/default/contents.d/tty5
touch /etc/s6/adminsv/default/contents.d/tty6
touch /etc/s6/adminsv/default/contents.d/udevd
touch /etc/s6/adminsv/default/contents.d/udevadm
touch /etc/s6/adminsv/default/contents.d/mount-filesystems
touch /etc/s6/adminsv/default/contents.d/mount-tmpfs
touch /etc/s6/adminsv/default/contents.d/mount-procfs
touch /etc/s6/adminsv/default/contents.d/mount-sysfs
touch /etc/s6/adminsv/default/contents.d/mount-devfs
touch /etc/s6/adminsv/default/contents.d/hostname
touch /etc/s6/adminsv/default/contents.d/hwclock
touch /etc/s6/adminsv/default/contents.d/modules
touch /etc/s6/adminsv/default/contents.d/sysctl
touch /etc/s6/adminsv/default/contents.d/random-seed
touch /etc/s6/adminsv/default/contents.d/rc-local

s6-rc-compile /etc/s6/rc/compiled-${TIMESTAMP} /etc/s6/sv /etc/s6/adminsv
ln -sfnv /etc/s6/rc/compiled-${TIMESTAMP} /etc/s6/rc/compiled

# Reboot required
reboot
```

## Setup core services
```shell
s6 set enable dhcpcd
s6 set enable nftables
s6 set enable dbus
# Warning or error messages may appear and it is ok
s6 repo sync && s6 set commit && s6 live install

rm -rf /etc/s6/adminsv/default*
# Warning or error messages may appear and it is ok
s6 repo sync && s6 set commit && s6 live install

# Reboot required
reboot

# Check services
s6-rc -a list
s6-rc-db list bundles
```

