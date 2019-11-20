---
title: "Mikrotik 493G with a Home DMZ"
date: 2017-10-22T02:37:22+03:00
draft: false
tags:
    - mikrotik
    - network
    - tweaking
---

In the [previous post](../2017-10-15-setting-up-mikrotik-493g-as-a-home-router-wlan-ap/) I showed one way to set up a home network using Mikrotik Routerboard. Next up in my project list was to set up a Raspberry Pi web server to host my own website and a blog (this one in fact). This required some tweaks to my home network set up as I needed to allow access to a device in my network from the public Internet. As Mikrotik allows nice configurability to do this kind of set ups, I dove into some of Mikrotik's own manuals to start up with. One solution to this could be a DMZ, for instance.

In _really_ short, DMZ ("demilitarized zone") means either a physical or logical network in which are services that are facing an untrusted network. In this case, it would be a web server. 
My goal was to isolate my server(s) from my home network at least on Layer 3 level.

In addition to the previous setup, I'd need a separate subnet and firewall rules to isolate the DMZ. Lets go and dive in:

```
# start by redefining the dmz interface name for clarity
/interface ethernet set [find name=ether9] name=dmz


# define a private IPv4 address space
/ip address add address=10.0.0.1/24 interface=dmz


# finally add firewall rules to allow traffic from and to the dmz if it is either
# entering the dmz or the hosts in dmz are accessing the internet.
# allow HTTP and HTTPS traffic.

/ip firewall filter
add chain=forward in-interface=dmz out-interface=ether1 action=accept
add chain=forward out-interface=dmz protocol=tcp dst-port=80,443 action=accept
```

As the network is NATted, **Dstnatting** (destination NATting, which I explained in the [previous post](../2017-10-15-setting-up-mikrotik-493g-as-a-home-router-wlan-ap/)), is needed as [port forwarding](https://en.wikipedia.org/wiki/Port_forwarding) to allow access from the Internet to the server in a local network. Next, access to 80 and 443 ports will is set like:

```
/ip firewall nat 
add chain=dstnat in-interface=ether1 dst-port=80,443 protocol=tcp action=dst-nat to-addresses=[web-server-address]
```

This should be enough for basic home network routing and isolation of the DMZ. If more interfaces are needed, they can be added as slaves to the dmz master port which in this case is ```ether9```. One of the cases that I thought was that even if this kind of firewalling is implemented and if the traffic would be allowed to the server directly from LAN without passing through the Internet, would the local network compromise their existence to the server by connecting using private IP address ranges?

## Conclusions

This time I went through a quick introduction of creating a DMZ in a home network using a Mikrotik Routerboard. Now that there is some sparkling dust and magic network segregation in place, next I'll continue to take a look at the installation and configuration of a Raspberry Pi as a web server. 
