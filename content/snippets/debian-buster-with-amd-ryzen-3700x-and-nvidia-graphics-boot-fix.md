---
title: "Debian Buster with AMD Ryzen 3700X and NVIDIA GFX Boot Fix"
date: 2020-02-29
draft: false
tags:
    - debian
    - linux
---

After fresh install of Debian 10 (Buster), booting to desktop failed to to an error:

```
sev command 0x4 timed out, disabling PSP
SEV: failed to get status. Error: 0x0
```

Now, it is still possible to login to a new terminal session with `ctrl+alt+fN`.
After login, enabling `non-free` to `sources.list` for AMD graphics firmware and `buster-backports` for NVIDIA drivers
and then installing packages `firmware-amd-graphics` and `nvidia-driver` seemed to work
for the issue. Probably installing only the AMD graphics package might have been enough to
get to boot to desktop, but this time happened to install both while I was there.

```bash
# add buster-backports to sources.list

echo deb http://deb.debian.org/debian buster-backports main contrib non-free | sudo tee -a /etc/apt/sources.list
```

Also remember to add `non-free` and `contrib` to existing `/etc/apt/sources.list`.

```bash
apt update
apt install nvidia-detect
nvidia-detect
# see the output for suggested packages, for me it was 'nvidia-driver'

apt install firmware-amd-graphics

# from Debian Wiki NVIDIA instructions

apt install linux-headers-$(uname -r|sed 's/[^-]*-[^-]*-//')
apt install -t buster-backports nvidia-driver

# reboot system
```

* [Debian Wiki: Sources List](https://wiki.debian.org/SourcesList)
* [Debian Wiki: NVIDIA Graphics Drivers](https://wiki.debian.org/NvidiaGraphicsDrivers#Debian_10_.22Buster.22)
