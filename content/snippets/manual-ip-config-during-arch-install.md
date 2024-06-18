---
title: "Manual IP Config During Arch Install"
date: 2021-04-01
draft: false
tags:
    - linux
    - arch
---

Note to self: How to set up `ip` config manually after forgetting
to install DHCP client while installing Arch and rebooting fresh
install before doing so:

```bash
ip link  # get the interface device <dev>
ip link up <dev>
ip address add <host ip>/<mask> broadcast + dev <dev>
ip route add default via <gw> dev <dev>
echo "nameserver 8.8.8.8" >> /etc/resolv.conf  # (or any other)
```
