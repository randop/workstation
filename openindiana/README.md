# OpenIndiana

## Create usb installer
```bash
dd if=/exports/installers/OI-hipster-text-20250402.usb \
	of=/dev/sdc \
	bs=16k \
	oflag=direct \
	conv=sync \
	status=progress
```

## Update packages
```bash
pkg update
```

## Install GUI
```bash
pkg install \
    --reject pkg://openindiana.org/driver/graphics/nvidia-340 \
    --reject pkg://openindiana.org/driver/graphics/nvidia-390 \
    --reject pkg://openindiana.org/driver/graphics/nvidia-470 \
    --reject pkg://openindiana.org/driver/graphics/nvidia-535 \
    mate_install
svcadm enable -r /application/graphical-login/lightdm
reboot
```