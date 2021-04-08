---
title: "Manual IP Config During Arch Install"
date: 2021-04-01
draft: false
tags:
    - linux
    - arch
---

Setting up `ip` config manually when forgetting to install DHCP client
while installing Arch:

```bash
ip link  # get the interface device [dev]
ip link up [dev]
ip address add [host ip]/[mask] broadcast + dev enp5s0
ip route add default via [gw] dev [dev]
echo "nameserver 8.8.8.8" >> /etc/resolv.conf  # (or any other)
```
