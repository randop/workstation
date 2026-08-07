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

