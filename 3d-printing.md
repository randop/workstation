# 3D Printing

## UltiMaker Cura

UltiMaker Cura is a slicer, an application that prepares your model for 3D printing. Optimized, expert-tested profiles for 3D printers and materials mean you can start printing reliably in no time. And with industry-standard software integration, you can streamline your workflow for maximum efficiency.

**UltiMaker Cura Flatpak setup and configuration on Artix Linux with s6**

### Prerequisites

Install Flatpak and required portal packages:

```bash
sudo pacman -Syu
sudo pacman -S flatpak xdg-desktop-portal xdg-desktop-portal-gtk
```

Add the Flathub remote:

```bash
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
```

Ensure a functional D-Bus user session exists (required for Flatpak applications). On s6 this is typically handled via turnstile or by launching the graphical environment with `dbus-run-session`.

### Install Cura

```bash
flatpak install flathub com.ultimaker.cura
```

### Permissions

Apply the following overrides:

```bash
flatpak override --user --filesystem=$HOME/Public com.ultimaker.cura
flatpak override --user --nofilesystem=home com.ultimaker.cura
flatpak override --user --unshare=network com.ultimaker.cura
```

The Flatpak retains `--device=all` for USB printer access and the original media mounts unless further overridden.

View current permissions:

```bash
flatpak info --show-permissions com.ultimaker.cura
flatpak override --user --show com.ultimaker.cura
```

Reset all user overrides if required:

```bash
flatpak override --user --reset com.ultimaker.cura
```

### Host USB serial access

Create a udev rule for printer serial ports:

```bash
sudo tee /etc/udev/rules.d/99-3dprinter.rules << 'EOF'
SUBSYSTEM=="tty", KERNEL=="ttyUSB[0-9]*|ttyACM[0-9]*", MODE="0666", GROUP="uucp"
EOF
sudo udevadm control --reload-rules
sudo udevadm trigger
```

Add the user to the `uucp` group if group-based access is used:

```bash
sudo usermod -aG uucp $USER
```

Log out and back in for the group change to take effect.

### Configuration locations

Flatpak stores data under:

- Configuration: `~/.var/app/com.ultimaker.cura/config/cura/<version>/`
- Data (profiles, machines, materials, plugins): `~/.var/app/com.ultimaker.cura/data/cura/<version>/`
- Cache: `~/.var/app/com.ultimaker.cura/cache/`

### Launch

```bash
flatpak run com.ultimaker.cura
```

### Initial configuration

On first launch the Add Printer wizard appears. Select the printer model or add a custom FFF printer. Machine definitions, materials, and quality profiles are stored in the data directory listed above.

Preferences are accessed via Help → Preferences or the equivalent menu entry. Changes are written to the configuration directory under `~/.var/app/com.ultimaker.cura/`.

### Updates

```bash
flatpak update
flatpak update com.ultimaker.cura
```

### Troubleshooting

- Viewport rendering issues under Wayland:  
  ```bash
  flatpak override --user --env=QT_QPA_PLATFORM=xcb com.ultimaker.cura
  ```

- Application fails to start with session bus errors: verify D-Bus user session is active.

- USB printer not detected: confirm the udev rule is loaded and the device node permissions are correct (`ls -l /dev/ttyUSB* /dev/ttyACM*`).

- Desktop menu entry missing: log out and back in, or run `update-desktop-database`.
