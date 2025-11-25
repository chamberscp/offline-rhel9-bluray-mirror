#!/bin/bash
set -e

echo "=== RHEL 9.7 Offline Blu-ray Mirror (Real Red Hat) ==="
read -p "Destination folder for mirror (e.g. $HOME/rhel9-mirror): " DEST
DEST=$(realpath "$DEST")
mkdir -p "$DEST"/{baseos,appstream,epel,extra-pkgs,wheels}

echo "Syncing repositories (20–50 min)..."
sudo dnf reposync --repo=rhel-9-for-x86_64-baseos-rpms    --download-path="$DEST/baseos"    --download-metadata
sudo dnf reposync --repo=rhel-9-for-x86_64-appstream-rpms --download-path="$DEST/appstream" --download-metadata
sudo dnf reposync --repo=epel                             --download-path="$DEST/epel"      --download-metadata

echo "Downloading Ansible, Podman, Navigator + all deps..."
sudo dnf download --destdir="$DEST/extra-pkgs" --alldeps \
  ansible-core ansible ansible-navigator podman tree python3-pip pipx

echo "Python wheels for offline pip..."
pip wheel --wheel-dir "$DEST/wheels" ansible-navigator

echo "Creating repo metadata..."
sudo createrepo_c "$DEST/baseos" "$DEST/appstream" "$DEST/epel" "$DEST/extra-pkgs"

cat > "$DEST/offline-repos.repo" <<REPO
[offline-baseos]     name=Offline BaseOS     baseurl=file:///baseos     enabled=1 gpgcheck=0
[offline-appstream]  name=Offline AppStream  baseurl=file:///appstream  enabled=1 gpgcheck=0
[offline-epel]       name=Offline EPEL       baseurl=file:///epel       enabled=1 gpgcheck=0
[offline-extra]      name=Offline Extra      baseurl=file:///extra-pkgs enabled=1 gpgcheck=0
REPO

echo "=== DONE === Size: $(du -sh "$DEST" | cut -f1)"
echo "Burn with:  growisofs -dvd-compat -Z /dev/sr0 -udf -R -J $DEST"
