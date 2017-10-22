---
title: "Setting up MikroTik 493G as a home router (+WLAN AP)"
date: 2017-10-15T23:39:06+03:00
draft: false
---

MikroTik is a company that sells e.g. configurable network appliances for a decent price point. I thought that their routerboard could be great for both casual and home lab use, so I went and bought a second-hand routerboard to tinker with. It felt it would be a nice change and an addition to get hands-on and acquainted with setting up computer networks from the scratch besides looking at tcpdumps/whatnot

![Router](/img/routerap.jpg)

Routerboards have an operating system called RouterOS, which is developed by MikroTik and is based on Linux kernel. There is also a software called WinBox for controlling the RouterOS devices via a graphical interface. It has a setup wizard to do this kind of setup the easy way, but what's the fun in that? As I wanted to dive in a bit more into the setup process and understand networking in practice on lower level, I went to terminal gymnastics in the end. Goal was to have a working LAN for desktop PCs and a WLAN AP. Note: I think the configurations would partially apply to also other MikroTik models as well but certainly with a grain of salt depending on the hardware.

By the way, MikroTik Wiki page "[How to configure a home router](https://wiki.mikrotik.com/wiki/How_to_configure_a_home_router)" is a great source to start from to learn more about the details.

## Conclusions

The setup seems to work fine, but some questions still remain: Is the bogus IP filtering really needed, or when is it needed in a home router setup? Also I did not touch VLAN setup, fast tracking, fast path and fast-forward options in interfaces and bridging this time. I also did not allow external ICMP packets either when dropping all connections coming from the Internet, but there seems to be multiple opinions about this: some allow it in a limited manner but some say that for home network it's not really needed. 

The configuration and descriptions for the set up phase are available in [Gist](https://gist.github.com/anerani/707bf0b006d2db14205819b7ca0813da):

{{< gist anerani 707bf0b006d2db14205819b7ca0813da>}}

