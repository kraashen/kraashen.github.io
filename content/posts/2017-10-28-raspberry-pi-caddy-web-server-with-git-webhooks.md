---
title: "Raspberry Pi Web Server Using Caddy and Git Webhooks"
date: 2017-10-28T16:57:26+03:00
draft: true
---

After setting up the DMZ in my home network, it was time to get hands on with the actual server. I heard of a web server called Caddy, which is a HTTP/2 HTTPS-by-default web server written in Go. I got into Go as a programming language some time ago recently and I was a bit excited about a possibility of running a production capable web server with it on a Raspberry Pi. RasPis have always been a tempting choice for me as a very affordable platform for me to either tinker with any projects or have services running on them. Raspberry Pi 3 [packs quite a bunch of processing power and features](https://www.raspberrypi.org/magpi/raspberry-pi-3-specs-benchmarks/) nowadays, so it seemed like a good option for hosting a website without losing the server availability if there is something else being processed on the server.

## Setup

I divided the process of the setup into couple of phases:

* User account creation and separation. Clean up default ```pi``` user.
* Firewalling of the server (```iptables```)
* Configure automatic updates
* Define static IP addressing, study how it works on Pi, what services handle it etc, how interface naming works on Debian distros.
* Investigate what services Pi runs out of the box; Why are they needed or why they are not needed. Remove unneeded services.
* Deploy and configure Caddy.
 * While it uses Let's Encrypt by default, study how it works and why it works as it does.
* Configure Git webhooks
* "Audit" the server

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

As the Pi will be running purely as a web server, there were handful of features and services that can be just disabled. Here's some for starters.

Disable BlueTooth and WiFi during bootup:
```

/boot/config.txt

...

dtoverlay=pi3-disable-bt
dtoverlay=pi3-disable-wifi
```

Disable unndeeded *systemd* services:

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

[Caddy](https://caddyserver.com/) is a HTTP/2 web server with support for automatic HTTPS using Let's Encrypt certificates. While it would not be tedious to set up a battle-hardened *nginx* or *Apache* using the same certificate provider, I wanted to give a shot at Caddy due to a recommendation from a friend. Besides, it's written in Go instead of C (yes, I am a bit biased to try new tech), which made me more curious for my use case as a personal web server.

#### Let's Encrypt

[Let's Encrypt](https://letsencrypt.org/) (LE) is a certificate authority founded by [EFF](https://www.eff.org/), [Mozilla Foundation](https://www.mozilla.org/en-US/foundation/) et al. whose mission is to allow easy and fast deployment of X.509 certificates. The project aims to make encrypted connections ubiquitous and being completely transparent of the certificate issuances. The approach to the issuance process is interesting, and I  really recommend reading it from [Let's Encrypt documentation](https://letsencrypt.org/how-it-works/). To sum it up, Let's Encrypt together with Automatic Certificate Management Environment protocol are the basis to handle requesting, creation, issuance, and validation without human intervention. Domain validation is based on a challenge that the LE server sends to the client (your server) that is requesting a certificate. By proving these challenges that you actually host the server in the domain and the key authorization, the client is allowed to do certificate management for the domain and can request for a certificate. Caddy handles all this automatically, but it would require just two shell commands to do manually as well.

#### Configuration

Caddy is quite straightforward to install and configure:

```bash
# git and hugo submodules are needed: git for webhook, I hugo for compiling and deploying static website so it's optional.
curl https://getcaddy.com | bash -s http.git,http.hugo
```

Basic configuration is also quite simple and HTTP is enabled by default, which is quite beautiful. Note also that [HSTS](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Strict-Transport-Security) header needs to be added manually. In short, this tells web browsers to use only HTTPS to access the site. If you have subdomains, refer to the Mozilla documentation for more details.

```
domain {
    root /var/www/domain
    tls [mail-address]

    header / {
        Strict-Transport-Security "max-age=31536000;"
    }
}
```

That's all that is needed for basic hosting of a website. Now Caddy is should be run as separate user, which is commonly ```www-data```, and as a daemon on the background. Caddy documentations have a nice template how this is done using ```systemd``` which I also ended up using. You can find the documentation for this at [https://github.com/mholt/caddy/tree/master/dist/init/linux-systemd], which also includes instructions to set up the www-data user properly.

As in documentation, the Caddy binary needs the ability to bind to privileged ports 80 and 443. ```cap_net_bind_service``` [does exactly this](http://man7.org/linux/man-pages/man7/capabilities.7.html)

```
setcap 'cap_net_bind_service=+ep' /usr/local/bin/caddy
```

After this, check, study, edit, and deploy the ```caddy.service``` file accordingly and enable these parameters in the configuration. At least I had issues starting Caddy as a service due to that it was not able to bind to the ports 80 and 443. This ticket in Caddy Community was quite helpful: https://caddy.community/t/caddy-wont-start-could-not-start-http-server-for-challenge-listen-tcp-80-bind-permission-denied/2543/2

```
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_BIND_SERVICE
NoNewPrivileges=true
```

### Github Webhooks

Now that the web server is running and serves the website properly, it would be nice to have something else than Hello World as content. I use Hugo as main platform for delivering static websites. It's a static website framework written - *surprise* - Go. The posts are written in Markdown which is compiled to a static website. It also has already quite a handful of themes available as well from the community.

How about if you could make blog posts anywhere with your devices with a text editor and *git*, and publish them on your server without need to interact with the server yourself? One way to do this are Git webhooks. So the workflow goes about like this:

* Blog posts are in Markdown in a ***private*** git repository
* Edit posts locally and push changes to git
* With every push to master branch from your device, posts that are not drafted should be published
* The server has a Git webhook configured that receives a notification of activity in the branch
* The server pulls latest revision of the site
* The server builds new version of the site and deploys it

Caddy has a plugin support for Git webhooks, which was installed earlier. Now this requires just couple of more lines to the local configuration, creation of a SSH keypair for www-data user and activating Git webhook to the repository. Note that if your site is in a public git repository, you can also skip the key creation and configuration and use the public HTTPS URL instead.

```bash
sudo su www-data -s /bin/bash
mkdir -p /srv/www/.ssh
chmod 700 /srv/www/.ssh
ssh-keygen -t rsa -b 4096 /srv/www/.ssh/github_webhook_key
# check that permissions are 644 for the public key, 600 for the private key
```

After the key creation the Caddyfile needs to be edited to use the git plugin and access the repository using the private key which we created earlier. One handy way to create a secret key is to use ```openssl rand -base64 32```, but there are definitely as many ways to create it as there are developers out there in the wild.

```
/etc/caddy/Caddyfile

domain {
    root /var/www/site
    tls [mail]
    
    git git@github.com:[account]/[repository].git {
        hook /webhook [SECRET_KEY]
        path /tmp/site
        key /srv/www/.ssh/github_webhook_key
        then hugo --destination=/var/www/site --cleanDestinationDir
    }

    header / {
        Strict-Transport-Security "max-age=315360000;"
    }
}
```

All these operations are performed as www-data user using which the Caddy is running. After this, Caddy needs to be restarted: ```systemctl restart caddy.service```. Now the webhook and SSH key needs to be configured to the repository in Github.com. Open up your private repository settings and select *"webhooks"*. Select *"Add webhook"* and fill up the settings:

* ```Payload URL```: https://your.site.domain/webhook (the path was configured for the webhook)
* ```Content type```: ```application/json``` (Caddy seemed to require this?)
* ```Secret```: SECRET_KEY which was inserted in the Caddyfile configuration
* Select "Just the push event", it's enough for the site updates.

Read permissions are enough for this server client to update the hosted site, so the SSH key can be added to "Deploy keys" with read-only access. Read more at: [Github documentation on Webhook creation](https://developer.github.com/webhooks/creating/).

## Auditing

Huzzah! Now the web server is hosting the static website. Now what? It would be also fun to check out how the server fares against hostile access attempts, so it was fun to do even basic level auditing. While I'm not a huge fan of "checkbox security", I'd recommend at minimum running ```nmap``` and also found out about ```lynis``` for auditing. Auditing my own servers was fun, and these tools are something to start from something.

## Conclusions

Well, this setup was a rabbit hole after all: After starting with something, new concepts led to another and I found myself reading hours of *systemd* and Debian networking internals documentations at 2AM in the night. Also from auditing point of view, Caddy feels like an interesting fuzzing target. It uses Go's standard library for HTTP functionalities and the list of Caddy's [capabilities](https://en.wikipedia.org/wiki/Caddy_(web_server)#Capabilities) is quite long, which might be interesting to target against.

I could have also set up the web server in a separate Docker container but as I won't be running other services (yet) on the server, it felt a bit overkill. From security point of view, also Docker containers don't work as 100% proof isolation from the system even if it might provide some level of isolation e.g. from privilege escalation. Might be still an interesting project to do some day and it would provide more consistent backup mechanisms to restore the server in case anything goes wrong. One improvement task would also be to deploy Cloudformation in front of the server, as the caching would also save card I/O on the Pi. Deploying SELinux as well would be an interesting project to study at some point.

It was also interesting to notice that while using a system account feels a bit questionable for repository syncing, I did not find a way to configure Caddy to use a separate sync user to pull the Git repository.

## Further reading

[Freedesktop.org: Predictable Network Interface Names]((https://www.freedesktop.org/wiki/Software/systemd/PredictableNetworkInterfaceNames/))
[Debian: Network Configuration](https://wiki.debian.org/NetworkConfiguration#Predictable_Network_Interface_Names)