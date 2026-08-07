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

