---
title: "Simple LAN party network with Zyxel GS1900-24E managed switch"
date: 2018-03-30
draft: false
---

## Introduction

We were about to have a LAN party during easter. Network infrastructure was really simple: one consumer-grade `10/100/1000` router with connection to the Internet with a NATted network, one port for the host of the party, and extending this network behind a switch for everyone else. Originally we had only `10/100` capable switch, but as the location we were in had now also support for faster uplink, we needed to upgrade the switch to get everything out of the bandwidth available.

Zyxel describes their GS1900 series as entry-level and small office-grade products. From price-point of view, they are quite decently priced managed routers with 8-port managed switch being ~70 euros and 24-port ~110 euros at the time of writing of this post. Due to this, they seemed a tempting option also for simple small LAN party networks. It was also a nice investment for future LAN parties as well in case there will be >100Mbit/s connection available.

![](/img/zyxel.jpg)

## Goal

* Set up a switched LAN network behind a common consumer-grade router that had an Internet uplink of `200/20` with NATting.
* VLAN for LAN party attendees.
* VLAN for switch management, attendees don't have access to the management interface.

## Setup

After unboxing the router and firing it up the first time, all of the ports are part of the VLAN1, which is the default VLAN with access to the management interface. If you happen to follow the configuration steps of this post, plug in your ethernet cable to either port ```1``` or ```2``` and uplink to the router to port ```3```.

Management interface was sadly only available using the browser UI without telnet or SSH access. The default factory firmware also seemed to render properly only on Internet Explorer at first, but no worries: Fire up your favourite browser and go get the latest firmware from Zyxel's website, extract the package, and install the ```.bix``` firmware file using the HTTP method in the settings of the management UI. The latest firmware updated also the management interface and it seemed to be friendlier with modern browsers as well.

### IP address configuration

Next up: Set up the IP address of the switch. I used following configs with static IP:

* IP: ```192.168.1.x``` (any that was not in use with the router IP subnet prefix)
* Mask: ```255.255.255.0/24```
* Gateway: [router IP]
* DNS: 0.0.0.0
* Alternative DNS: 0.0.0.0

Now the switch should be able to connect both to the router and the Internet. You can verify this using ```ping```.

### VLANs

The next task was to set up VLANs for the users within the LAN party network to separate them from the management access to the switch. From the management interface front page, create a new VLAN e.g. with name ```VLAN100``` for common user access and add, all interfaces besides ```1``` and ```2``` to that newly created VLAN as untagged. In case you already have VLAN also from the router, and you'd like to extend that VLAN also to the switch's network, you'll need to use tagged VLAN. But in this case as the router handles the NAT IP address allocation using DHCP and no VLANs existed within the network, untagged was fine enough. Only separation of the users within the switched network was needed.

After creating the VLAN, all of the interfaces' port VLAN ID (PVID) needs to be changed to be part of that VLAN as well. This can be that from the ```VLAN``` -> ```Port``` settings. Now all interfaces from 3-24 (or how many ports you happen to have) should be within their own VLAN100 that don't have management access, if you kept the management access only for the VLAN1.

This should be pretty much it. Ports 1 and 2 are within VLAN1 and can access the management interface, and rest of the ports are in their own isolated VLAN. When the cable from any port in the `VLAN100` is connected to a router, the consumer-grade devices behave in quite simple manner and hosts in the VLAN are connected to the network. They should get an IP address, and connect the internet. Now next topic to investigate further is [VLAN hopping](https://en.wikipedia.org/wiki/VLAN_hopping). :)

#### Tagged vs untagged VLANs?

So what's the difference between tagged and untagged VLAN ports? To get back to this question, lets check out the [IEEE 802.1Q standard](https://en.wikipedia.org/wiki/IEEE_802.1Q).

By definition:

> IEEE 802.1Q, often referred to as Dot1q, is the networking standard that supports virtual LANs (VLANs) on an IEEE 802.3 Ethernet network. The standard defines a system of VLAN tagging for Ethernet frames and the accompanying procedures to be used by bridges and switches in handling such frames.

![](/img/640px-Ethernet_802.1Q.png)

What this means that based on this standard, network packets within a virtual LAN can be tagged with a 802.1Q header that includes a tag protocol identifier (TPID) and tag control information (TCI). TCI further also includes priority code, drop eligibility indicator, and a VLAN identifier.

This 802.1Q header is interpreted by the assigned VLAN trunk ports which determine that to which VLAN segment the packets belong to and directs the traffic to the hosts within that VLAN. An untagged VLAN packet does not include this information.

So, the reason why the ports where marked as untagged in the ```VLAN100``` is that no VLAN is available or created on the router side - there was no need for the router end to understand about the switch's VLAN segments as only local shallow isolation of the hosts was required in the switch network.

## Conclusions

Here, a simple LAN party network was set up using Zyxel's entry level and small office managed switch and a consumer-grade router. It also separates users in the switched network from the management interfaces using a basic VLAN with untagged traffic. It seems that the switch is very capable, compact, fast to set up simple small networks, and good investment for the future as well considering possible LAN parties as well.