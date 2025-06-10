# Proxmox

## Install tools
```bash
apt install \
    kde-plasma-desktop \
    mesa-vulkan-drivers \
    ark \
    kdevelop \
    git
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
