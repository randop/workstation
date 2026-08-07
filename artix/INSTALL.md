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

## Install X11 desktop build development packages
```shell
pacman -S base-devel \
  git \
  meson \
  cmake \
  xlibre-xserver \
  xlibre-xserver-common \
  xlibre-input-libinput \
  libx11 \
  libxft \
  libxinerama \
  freetype2 \
  fontconfig \
  ttf-hack-nerd \
  noto-fonts \
  noto-fonts-emoji \
  ttf-dejavu \
  libxcursor \
  xorg-xdm \
  xdm-s6 \
  xorg-xinit \
  xorg-xset \
  xorg-xsetroot \
  xorg-xrandr \
  libxkbcommon \
  xsel
```

## Compile `dwm` bundle
```shell
mkdir -pv /opt/desktop && cd /opt/desktop
git clone https://git.suckless.org/dwm
cd /opt/desktop/dwm
cp -v /opt/desktop/dwm/config.def.h /opt/desktop/dwm/config.h
make clean install
cd /opt/desktop
git clone https://git.suckless.org/dmenu
cd /opt/desktop/dmenu
cp -v /opt/desktop/dmenu/config.def.h /opt/desktop/dmenu/config.h
make clean install
cd /opt/desktop
git clone https://git.suckless.org/st
cd /opt/desktop/st
cp -v /opt/desktop/st/config.def.h /opt/desktop/st/config.h
make clean install
```

## Create regular user account
```shell
pacman -S fish
useradd -m randolph
usermod -s /usr/bin/fish randolph
passwd randolph
```

## Install and setup nvidia gpu drivers
> NVIDIA Quadro P400 requires 580.xx driver version

```shell
# Disable incompatible driver module
cat > /etc/modprobe.d/blacklist-nouveau.conf <<EOF
blacklist nouveau
options nouveau modeset=0
EOF

pacman -S nvidia-580xx-dkms
nvidia-xconfig

# check configuration
cat /etc/X11/xorg.conf

# Edit module configuration and put nvidia drivers
# MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)
vim /etc/mkinitcpio.conf

# Rebuild system modules
mkinitcpio -P

# Reboot required
reboot
```

## Install cpu microcode
```shell
# For intel systems
pacman -S intel-ucode

# For amd systems
pacman -S amd-ucode

# Reboot required
reboot
```

## Configure and load user desktop
```shell
cat > /home/randolph/.xsession <<EOF
#!/bin/sh
xset s off -dpms s noblank
xsetroot -name "$(uname -r -s)"
export XDG_CURRENT_DESKTOP=X-Generic
export TERM=xterm-256color
export PATH="$PATH:$HOME/.local/bin"
exec dbus-launch --exit-with-session dwm
EOF

chown randolph:randolph /home/randolph/.xsession
chmod +x /home/randolph/.xsession

s6 set enable xdm
s6 repo sync && s6 set commit && s6 live install
s6-rc -u change xdm 
```

## Install core utilities
```shell
pacman -S \
  cryptsetup \
  pass \
  unzip \
  wget \
  ripgrep \
  fd \
  openssh \
  tmux
```

## Setup `pass`
```shell
pass init 880DF768F4C2A473
```

## Install development toolchain
```shell
pacman -S \
  cmake \
  meson \
  pkg-config \
  xfsprogs
```

## Install multimedia software packages
```shell
pacman -S \
  pipewire-jack \
  pipewire \
  pipewire-pulse \
  wireplumber \
  ffmpeg
```

## Install and setup `flatpak`
```shell
pacman -S flatpak
flatpak remote-delete flathub

# Login as regular user and install flatpaks
su -l randolph
mkdir -vp ~/Downloads
flatpak --user remote-add flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install flathub com.brave.Browser
flatpak override --user --filesystem=~/Downloads com.brave.Browser
flatpak install flathub com.vscodium.codium
flatpak install flathub com.obsproject.Studio
flatpak install org.freedesktop.Platform.ffmpeg-full
flatpak install flathub org.mozilla.firefox
flatpak install flathub org.kde.kwrite
flatpak install flathub com.saivert.pwvucontrol
flatpak install flathub org.kde.krita
flatpak install flathub org.gimp.GIMP
flatpak install flathub org.kde.gwenview
flatpak install flathub org.kde.okular
flatpak install flathub org.libreoffice.LibreOffice
flatpak install flathub org.flameshot.Flameshot
flatpak install flathub rest.insomnia.Insomnia
flatpak install flathub org.kde.kget
flatpak install flathub org.kde.kommit
flatpak install flathub org.kde.kdiff3
flatpak install flathub org.kde.kate
flatpak install flathub org.videolan.VLC
flatpak install flathub cc.arduino.IDE2
flatpak install flathub cc.arduino.arduinoide
flatpak install flathub org.filezillaproject.Filezilla
flatpak install flathub io.dbeaver.DBeaverCommunity
flatpak install flathub com.mongodb.Compass
flatpak install flathub com.redis.RedisInsight

# check flatpak list
flatpak list

# Done
exit
```
