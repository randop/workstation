# CI

## Full setup: `ci` system user on Arch Linux with git over SSH + chroot

### 1. Create user
```bash
useradd --system --no-create-home --shell /usr/local/bin/git-shell ci
usermod --home /home/ci ci
```

### 2. Download binaries
```bash
BASE=https://github.com/randop/machines/releases/download/v1.0.0

wget $BASE/git-shell -O /usr/local/bin/git-shell
wget $BASE/git       -O /usr/local/bin/git

chmod 755 /usr/local/bin/git-shell
chmod 755 /usr/local/bin/git

echo "/usr/local/bin/git-shell" >> /etc/shells
```

### 3. Build chroot structure
```bash
# Directories
install -d -o root -g root -m 755 /var/ci
install -d -o root -g root -m 755 /var/ci/etc
install -d -o root -g root -m 755 /var/ci/dev
install -d -o root -g root -m 755 /var/ci/usr/bin
install -d -o root -g root -m 755 /var/ci/usr/local/bin
install -d -o root -g root -m 755 /var/ci/usr/lib
install -d -o ci   -g ci   -m 755 /var/ci/home/ci
install -d -o ci   -g ci   -m 755 /var/ci/repo.git

# Devices
mknod /var/ci/dev/null c 1 3
chmod 666 /var/ci/dev/null

# Binaries
cp /usr/local/bin/git-shell /var/ci/usr/local/bin/
cp /usr/local/bin/git       /var/ci/usr/bin/

# Libraries for git-shell
ldd /usr/local/bin/git-shell | awk '{print $3}' | grep ^/ | while read lib; do
    cp --parents "$lib" /var/ci
done

# Libraries for git
ldd /usr/local/bin/git | awk '{print $3}' | grep ^/ | while read lib; do
    cp --parents "$lib" /var/ci
done

# Dynamic linker
cp --parents /lib64/ld-linux-x86-64.so.2 /var/ci 2>/dev/null || \
cp --parents /lib/ld-linux-x86-64.so.2   /var/ci

# ld cache
cp /etc/ld.so.conf /var/ci/etc/
ldconfig -r /var/ci

# User lookup
grep "^ci:" /etc/passwd       >> /var/ci/etc/passwd
grep "^ci:" /etc/group        >> /var/ci/etc/group
cp /etc/nsswitch.conf            /var/ci/etc/
cp /usr/lib/libnss_files.so.2    /var/ci/usr/lib/
cp /usr/lib/libz.so.1            /var/ci/usr/lib/
```

### 4. Init bare repo
```bash
su -s /bin/sh -c "git init --bare /var/ci/repo.git" ci
```

### 5. Authorized keys
```bash
install -d -o root -g root -m 755 /etc/ssh/authorized_keys
install -o root -g root -m 644 /dev/null /etc/ssh/authorized_keys/ci
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF/nHVQiugiQFw+smEHNHOaqEKXZJVoq5VA5H5FcFn/7 ci@tindango.com" >> /etc/ssh/authorized_keys/ci
```

### 6. `/etc/ssh/sshd_config`
```sshd_config
Match User ci
    ChrootDirectory /var/ci
    AuthorizedKeysFile /etc/ssh/authorized_keys/ci
    PasswordAuthentication no
    PubkeyAuthentication yes
    AllowTcpForwarding no
    X11Forwarding no
    PermitTTY no
```

```bash
sshd -t && systemctl reload sshd
```

### 7. Verify
```bash
# Config is valid
sshd -t

# Chroot works
chroot /var/ci /usr/local/bin/git-shell -c "git-upload-pack '/repo.git'"
# should hang waiting for input — Ctrl+C to exit
```

### 8. Dev machine
```bash
# use the exact host address
git init
git remote add origin ci@1.1.1.1:/repo.git
git push origin master
```
