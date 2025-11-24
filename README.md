# offline-rhel9-bluray-mirror  
Complete **RHEL 9 / Rocky 9 air-gapped mirror** + **Ansible + Podman + ansible-navigator** on **one BD-R 25 GB disc**


### What’s included
- Full BaseOS + AppStream + EPEL
- ansible-core + ansible + ansible-navigator
- podman + tree + pipx + gedit
- Every single dependency (works 100% offline)
- Python wheels for ansible-navigator
- Ready-to-copy .repo file + step-by-step install guide

### One command (on an internet-connected machine)
```bash
./create-bluray-mirror.sh
# → point it at a folder or mounted USB
# → burn the folder to a BD-R 25 GB disc
