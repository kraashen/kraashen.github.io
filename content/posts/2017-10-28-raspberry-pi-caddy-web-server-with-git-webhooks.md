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

[Caddy](https://caddyserver.com/) is a HTTP/2 web server with support for automatic HTTPS using Let's Encrypt certificates. It would not be tedious to set up a battle-hardened *nginx* or *Apache* using the same certificate provider, but I wanted to give a shot at Caddy due to a recommendation from a friend. Besides, it's written in Go instead of C, which made me more curious for my use case as a personal web server.

Caddy is quite straightforward to install and configure:

```bash
# git and hugo submodules are needed: git for webhook, I hugo for compiling and deploying static website so it's optional.
curl https://getcaddy.com | bash -s http.git,http.hugo
```

Basic configuration is also quite simple and HTTP is enabled by default, which is quite beautiful. Note also that [HSTS](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Strict-Transport-Security) header needs to be added manually. In short, this tells web browsers to use only HTTPS to access the site. If you have subdomains, refer to the Mozilla documentation for more details.

```
pixl.dy.fi {
    root /var/www/pixl.dy.fi
    tls [mail-address]

    header / {
        Strict-Transport-Security "max-age=31536000;"
    }
}
```

That's all that is needed for basic hosting of a website. Now Caddy is needed to run as ```www-data``` user and as a daemon on the background. Caddy documentations have a nice template how this is done using ```systemd``` which I also ended up using. You can find the documentation foir this at [https://github.com/mholt/caddy/tree/master/dist/init/linux-systemd], which also includes instructions to set up the www-data user properly.

As in documentation, the Caddy binary needs the ability to bind to privileged ports 80 and 443. ```cap_net_bind_service``` [does exactly this](http://man7.org/linux/man-pages/man7/capabilities.7.html)

```
setcap 'cap_net_bind_service=+ep' /usr/local/bin/caddy
```

After this, check, study, edit, and deploy the ```caddy.service``` file accordingly and enable these parameters in the configuration. At least I had issues starting Caddy as a service due to that it was not able to bind to the ports 80 and 443. This ticket in Caddy Community was quite helpful: [https://caddy.community/t/caddy-wont-start-could-not-start-http-server-for-challenge-listen-tcp-80-bind-permission-denied/2543/2]

```
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_BIND_SERVICE
NoNewPrivileges=true
```

### Github Webhooks

Now that the web server is running and serves the website properly, it would be nice to have something else than Hello World as content. I use Hugo as main platform for delivering static websites. It's static site rendering framework written - tadah - Go. The posts are written in Markdown and it has already quite a handful of themes available as well from the community.

How about if you could make blog posts anywhere with our devices with git and a text editor and publish them on your server without intervention? One way to do this are Git webhooks. So the workflow goes about like this:

* Blog posts are in Markdown in a private git repository
* With every push to master branch, posts that are not drafted should be published
* Client edits posts locally and pushes changes to git
* The server has a Git webhook configured that received a notification of activity in the branch
* The server pulls latest revision of the blog
* The server builds new version of the site and deploys it

## Audit

## Conclusions

Caddy interesting fuzzing target?
Docker?
Thanks joneskoo for tipping out on Caddy.
Cloudformation, caching saves card io...

## Further reading

[Freedesktop.org: Predictable Network Interface Names]((https://www.freedesktop.org/wiki/Software/systemd/PredictableNetworkInterfaceNames/))
[Debian: Network Configuration](https://wiki.debian.org/NetworkConfiguration#Predictable_Network_Interface_Names)