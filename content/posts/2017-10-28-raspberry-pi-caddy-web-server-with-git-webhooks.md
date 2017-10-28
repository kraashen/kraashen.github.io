---
title: "Raspberry Pi Web Server Using Caddy and Git Webhooks"
date: 2017-10-28T16:57:26+03:00
draft: true
---

After setting up the DMZ in my home network, it was time to get hands on with the actual server. I heard of a web server called Caddy, which is a HTTP/2 HTTPS-by-default web server written in Go. I got into Go as a programming language some time ago recently and I was a bit excited about a possibility of running a production capable web server with it. Raspberry Pi has always been a tempting choice for me as a very affordable platform for me to either tinker with projects or have services running on them. Raspberry Pi 3 [packs quite a bunch of processing power and features](https://www.raspberrypi.org/magpi/raspberry-pi-3-specs-benchmarks/) nowadays, so it seemed like a good option for hosting a website without losing the server availability if there is something else being processed on the server.

## Setup

### Networking and interfaces

As the server will be hosting a website, it will need a static IP address [Finnish DynDNS dy.fi]([https://www.dy.fi]). In Raspbian, there is a client called ```dhcpcd``` DHCP client enabled by default, and there are couple of ways handling the static IP addressing of the server. One way would be to just disable the *dhcpcd* and use ```/etc/network/interfaces``` instead or configure *dhcpcd* to use static IP address instead. Running a DHCP client to get a static IP address was not needed in this kind of wired environment, so I went with the interfaces way for my case.

```
/etc/network/interfaces:

auto [interface]
iface [interface] inet static
    address [static server address configured in the router port forward rules]
    gateway [router DMZ gateway]
    netmask 255.255.255.0
```

Also it was fun to realize during wondering why this did not work that in Debian Stretch, [interface naming has changed by default](https://www.debian.org/releases/stable/amd64/release-notes/ch-whats-new.en.html#new-interface-names):

> The installer and newly installed systems will use a new standard naming scheme for network interfaces instead of eth0, eth1, etc. The old naming method suffered from enumeration race conditions that made it possible for interface names to change unexpectedly and is incompatible with mounting the root filesystem read-only. The new enumeration method relies on more sources of information, to produce a more repeatable outcome. It uses the firmware/BIOS provided index numbers and then tries PCI card slot numbers, producing names like ens0 or enp1s1 (ethernet) or wlp3s0 (wlan). USB devices, which can be added to the system at any time, will have names based upon their ethernet MAC addresses. 

The interface name needs to be of this defined form e.g. checking by ```ifconfig```, or it must be changed manually to the legacy format by including/editing a udev rule in ```/etc/udev/rules.d/``` directory. While there are plenty of resources on how to achieve this, note that [it will be deprecated starting Debian 10](https://lists.debian.org/debian-user/2017/07/msg01453.html).

More detailed explanation is in [here](https://www.freedesktop.org/wiki/Software/systemd/PredictableNetworkInterfaceNames/), but the key point is that fixed names based on firmware, topology, and location information has advantage of being consistent across changes in the environment e.g. including reboots, hardware changes.

### Disable unneeded services

As the Pi will be running purely as a web server, there are handful of features and services that can be just disabled. Here's some for starters.

Disable BlueTooth and WiFi during bootup:
```

/boot/config.txt

...

dtoverlay=pi3-disable-bt
dtoverlay=pi3-disable-wifi
```

```bash
# BLuetooth-related services
systemctl disable bluealsa.service && systemctl stop bluealsa.service
systemctl disable hciuart.service && systemctl stop hciuart.service
systemctl disable bluetooth.service && systemctl stop bluetooth.service

# Avahi is an open source implementation of Bonjour/Zeroconf protocol for service discovery.
systemctl disable avahi-daemon.service && systemctl stop avahi-daemon.service

# No sound needed and also disabled in boot configured earlier
systemctl disable alsa-restore.service && systemctl stop alsa-restore.service
```

There might still be unneeded services left on my RasPi, but I'll add them here afterwards as I find more. :-)

### Caddy

* install caddy and related plugins

### Github Webhooks

* how to configure the github webhooks on server and github page

## Audit

## Conclusions

Caddy interesting fuzzing target?
Docker?
Thanks joneskoo for tipping out on Caddy.
Cloudformation, caching saves card io...

## Further reading

[Freedesktop.org: Predictable Network Interface Names]((https://www.freedesktop.org/wiki/Software/systemd/PredictableNetworkInterfaceNames/))
[Debian: Network Configuration](https://wiki.debian.org/NetworkConfiguration#Predictable_Network_Interface_Names)