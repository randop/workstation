# Proxmox

## Install tools
```bash
apt install \
    kde-plasma-desktop \
    mesa-vulkan-drivers \
    ark \
    kdevelop \
    git \
    meson \
    cmake \
    cryptsetup
```

### Time sync
#### Restart the chrony service to apply changes
```bash
systemctl restart chronyd
```

#### Verify synchronization status
```bash
journalctl --since -1h -u chrony
```
> Jun 10 12:10:20 workstation chronyd[1236]: Received KoD RATE from 58.71.12.13
>
> Jun 10 12:13:16 workstation chronyd[1236]: chronyd exiting
>
> Jun 10 12:13:16 workstation systemd[1]: Stopping chrony.service - chrony, an NTP client/server...
>
> Jun 10 12:13:16 workstation systemd[1]: chrony.service: Deactivated successfully.
>
> Jun 10 12:13:16 workstation systemd[1]: Stopped chrony.service - chrony, an NTP client/server.
>
> Jun 10 12:13:16 workstation systemd[1]: Starting chrony.service - chrony, an NTP client/server...
>
> Jun 10 12:13:16 workstation chronyd[57228]: chronyd version 4.3 starting (+CMDMON +NTP +REFCLOCK +RTC +PRIVDROP +SC>
>
> Jun 10 12:13:16 workstation chronyd[57228]: Frequency 0.105 +/- 0.966 ppm read from /var/lib/chrony/chrony.drift
>
> Jun 10 12:13:16 workstation chronyd[57228]: Using right/UTC timezone to obtain leap second data
>
> Jun 10 12:13:16 workstation chronyd[57228]: Loaded seccomp filter (level 1)
>
> Jun 10 12:13:16 workstation systemd[1]: Started chrony.service - chrony, an NTP client/server.
>
> Jun 10 12:13:22 workstation chronyd[57228]: Selected source 216.239.35.12 (time4.google.com)
>
> Jun 10 12:13:22 workstation chronyd[57228]: System clock TAI offset set to 37 seconds
>
> Jun 10 12:13:23 workstation chronyd[57228]: Selected source 216.239.35.4 (time2.google.com)
>
> Jun 10 12:14:28 workstation chronyd[57228]: Selected source 216.239.35.8 (time3.google.com)
>
> Jun 10 12:18:47 workstation chronyd[57228]: Selected source 216.239.35.4 (time2.google.com)
