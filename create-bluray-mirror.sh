#!/bin/bash
set -e

echo "=== RHEL 9 / Rocky 9 Blu-ray-R Offline Mirror ==="
echo "This will create ~23–25 GB ready for one BD-R 25 disc"
echo "Insert or mount your writeable location (USB or folder that will fit 25 GB)"

read -p "Path to write mirror (e.g. /mnt/burn or /home/user/bluray): " DEST
DEST=$(realpath "$DEST")
mkdir -p "$DEST"

echo "Creating directory structure..."
mkdir -p "$DEST"/{BaseOS,AppStream,epel,wheels,extra-pkgs}

echo "Enabling and syncing repositories..."
sudo dnf reposync --repoid=baseos --download-path="$DEST/BaseOS" --download-metadata
sudo dnf reposync --repoid=appstream --download-path="$DEST/AppStream" --download-metadata
sudo dnf reposync --repoid=epel --download-path="$DEST/epel" --download-metadata

echo "Downloading exact packages + ALL dependencies..."
sudo dnf repoquery --arch=x86_64,noarch \
  ansible-core ansible ansible-navigator podman tree python3-pip pipx gedit \
  --resolve --requires --recursive \
  | sort -u \
  | xargs sudo dnf download --destdir="$DEST/extra-pkgs" --alldeps

echo "Downloading Python wheels for ansible-navigator (works offline)"
pip wheel --wheel-dir "$DEST/wheels" ansible-navigator

echo "Creating repo metadata..."
sudo createrepo_c "$DEST/BaseOS"
sudo createrepo_c "$DEST/AppStream"
sudo createrepo_c "$DEST/epel"
sudo createrepo_c "$DEST/extra-pkgs"

echo "Writing offline repo file..."
cat > "$DEST/offline-repos.repo" <<REPO
[offline-baseos]
name=Offline BaseOS
baseurl=file:///BaseOS
enabled=1
gpgcheck=0

[offline-appstream]
name=Offline AppStream
baseurl=file:///AppStream
enabled=1
gpgcheck=0

[offline-epel]
name=Offline EPEL
baseurl=file:///epel
enabled=1
gpgcheck=0

[offline-extra]
name=Offline Extra Packages
baseurl=file:///extra-pkgs
enabled=1
gpgcheck=0
REPO

echo "Writing install instructions..."
cat > "$DEST/README_OFFLINE_INSTALL.txt" <<'README'
OFFLINE INSTALL INSTRUCTIONS (RHEL 9 / Rocky 9)

1. Mount this Blu-ray
2. Copy everything to /mnt/offline (or any path)
3. sudo cp /mnt/offline/offline-repos.repo /etc/yum.repos.d/
4. sudo dnf clean all
5. Install everything:
   sudo dnf install ansible podman ansible-navigator tree pipx gedit -y
6. For ansible-navigator wheels (if needed):
   pip install --no-index --find-links=/mnt/offline/wheels ansible-navigator

You now have full Ansible + Podman + Navigator with ZERO internet required.
README

echo "=== DONE ==="
echo "Total size: $(du -sh "$DEST" | cut -f1)"
echo "Burn the contents of $DEST to a BD-R 25 GB disc with any burner (Brasero, k3b, Windows Disc Image Burner, etc.)"
echo "Label it: RHEL9_OFFLINE_2025 – Ansible + Podman + Navigator"
