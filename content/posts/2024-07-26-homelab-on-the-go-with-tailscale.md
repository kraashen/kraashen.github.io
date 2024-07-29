---
title: "Homelab on the go with Tailscale"
date: 2024-07-26
draft: false
showToc: true
summary: Having a home lab and services such as PiHole, RSS reader, K3s, Home Assistant, and more is fun and all at home, but how to access them when leaving the house without opening up parts of the home network to the Internet? In this post, we'll go through a setup of Tailscale VPN and running services such as PiHole on Debian server.
tags:
    - network
    - tailscale
---

# Home Lab on the Go with Tailscale

## Introduction

Having a home lab and services such as PiHole, RSS reader, K3s, Home Assistant, and
more is fun and all at home, but how to access them when leaving the house
without opening up parts of the home network to the Internet?

One option is to use a VPN service to access them, but they can be bunch of work
to set up on your own. Luckily there is a ready solution called Tailscale which:

- doesn't take too much time to set up
- has native client applications for Linux servers, Linux laptop, and iOS/Android
- is free for private small-scale use (though always consider to support a great project!)
- is easy to maintain and operate

And lastly an exciting feature that was added to the Tailscale iOS app some time back that helps
with having everything on-the-go: **It can be configured to turn on automatically**
**when leaving a WiFi network.**

Note here that you will need an account to a domain registrar and an existing domain
with an ownership to manage and create API tokens and A/AAAA records for this post.

In this post, we'll go through a setup of running following on Debian server:

- Let's Encrypt for TLS certificates for all hosted subdomains
- PiHole for ad blocking (it's nice to browse the Internet without clutter on the go as well)

## Tailscale

[Tailscale](https://tailscale.com/) is an easy-to-use zero-config VPN that can be
used to quickly set up private networks. It is based zero trust networking principle
and uses an approach where each device and service is encapsulated individually
(practically meaning WireGuard and device-only local private keys), and each session
between devices in the network is end-to-end encrypted.

"Zero-config" in practice, means basically that all you need is:

- Tailscale account (created using only a third party OIDC service such as Google/Apple ID or such)
- Tailscale app on mobile
- Running Tailscale binary on your server

and with these, a basic functional hybrid-meshing VPN network is ready to go. Depending on personal or
company requirements, naturally more configuration might be required.

Furthermore, if there is need for more fine-grained networking, the configuration options
include ACLs, custom service integrations, custom DNS routing, and much more.
One cool feature is also a solution to share files directly between Tailscale clients!
Personal AirDrop'ish!

### How does it work?

Tailscale is developed in Golang and is based on WireGuard VPN.
Albeit being used synonymously as a VPN solution, WireGuard is a FOSS communication protocol
to implement encrypted VPNs which passes network traffic on UDP. One major implementation of it
has been [included in the Linux Kernel 5.6 in 2020](https://www.wireguard.com/papers/wireguard.pdf).
It aims for simplicity, extendability, and faster transfers compared to earlier solutions
such as OpenVPN or IPsec tunneling.

Building on top of WireGuard, Tailscale provides both developer and user-friendly features such as
[single sing-on (SSO), TCP transport (with DERP), NAT traversal, and ACLs (with programmatic APIs!)](https://tailscale.com/kb/1035/wireguard),
and much more. On top of this, it leverages integrations to various services, such as databases,
firewalls, web servers, NAS'es, and other remote use case services.

Going through all the features might be an overshoot for a home lab, though some of them might be interesting
to try out at some point such as [integration with Caddy](https://tailscale.com/kb/1190/caddy-certificates)
(or [Traefik](https://tailscale.com/kb/1234/traefik-certificates) when running K3s),
[remote VSCode](https://tailscale.com/kb/1265/vscode-extension),
and [NAS](https://tailscale.com/kb/1307/nas) servers.

How does Tailscale do the magic for the homelab network available for other devices outside the house?

There is an extensive blog post about how it works [here](https://tailscale.com/blog/how-tailscale-works),
but let's go through the concepts on a high level.

#### Tailnet

A Tailscale network, "Tailnet", consists of a data plane and a control plane. The data plane
is a collection of nodes/machines running a Tailscale client. The control plane consists of
the coordinator and for instance, the auth server. Control plane manages the metadata exchange
and maintenance between peers, in which resides the Coordinator - service maintained by Tailscale.

![](/img/tailscale-homelab-topology.png)

#### Coordinator

A coordination server is a service in a Tailnet that distributes the
public keys and settings to the clients in the private networks, referred to as "Tailnets".

When a new client is started the first time, new pair of private and public keys
are generated, and the public key with the Tailscale
controller is exchanged, and the client is added to your Tailnet.

![](/img/tailscale-client-join-flow.png)

The control plane works in hub-and-spoke manner, but does not carry the traffic that the clients discuss
between each other. It plainly assists the clients to exchange encryption keys and the domain policies.
It works as a hybrid solution in between traditional VPN hub-and-spoke model and
mesh model.

Now that the clients know about each others' whereabouts and have a hold on their public keys,
how do these communicate from behind a NATted home network?

#### NAT traversal magic and DERP

Tailscale implements seceral techniques to allow nodes to find each other online and establish
peer-to-peer connections. These techniques are based on STUN and ICE standards, and handful of
NAT traversal hoops and algorithms. [Tailscale has a great technical article explaining this](https://tailscale.com/blog/how-nat-traversal-works). Tailscale implements handful of interesting techniques to bypass this, and the article is
a highly recommended read for anyone interested in networking. (I was astounded when reading their documentation
about these NAT magics, it was pretty cool! Without spoiling too much, the birthday attack really got me.)
It works as a fallback in case direct connection fails.

In practice, all these together nicely avoid the need for any custom complex firewall configurations, 
NAT magic, or opening ports - **and it just works**.

In some harder networks where direct connection between nodes is hard or impossible,
the clients pass the connection through using Designated Encrypted Relay Protocol (DERP).

![](/img/tailscale-derp-init.png)

DERP is Tailscale's implementation that uses HTTPS streams and WireGuard
for communication. These relay proxies act as an intermediaries to pass traffic between clients
for example in networks where outbound UDP is blocked by default.

![](/img/tailscale-derp-after.png)

As the traffic is encrypted between peers, the relays cannot see what's up between the clients. After
they successfully initiate direct connection between each other, the connection changes
to mesh networking.

Now the clients are discussing and everything is great. Altough as a curiosity, if I want to share
a service with friends or I need to convince my corporate IT, how can I restrict access in my Tailnet?
How do the access controls work? How can services and nodes be restricted between users and user groups?

VPNs provide mechanisms for restricting traffic between clients using stuff like firewalls and
VPN identity systems, but in a role-based world
(I'm looking at you IAM and it's derivatives), Tailscale implements cool feature: Programmatic ACLs!

#### ACLs

Remember how Tailscale works as a peer-to-peer meshed VPN? The firewall rules need to be
somewhere, and if control server does not know them anymore after sending them back to the client,
where are they?

Answer is: In each client!

Each node handles blocking and allowing incoming and outgoing connections based on the configured
ACLs. Also, each node is given the public keys only of the nodes they are allowed to connect to.
This way, each node also on its own acts both as a firewall to the network and a client who communicates there.

![](/img/tailscale-acl-firewalls.png)

These can be configured granularly for users, groups, tags (yes, things can be tagged as well based
on use cases), services, posture rules, and nodes. The syntax is JSON based, has support for testing
changes before applying rules - and has native GitOps integrations as well! Hooray for CI automations!

### Setting up

Now, let's go through how to set this thing up in a home network and servers!

#### Server

Run the installation script provided in [Tailscale web page](https://tailscale.com/download/linux)

And run the binary

```
# tailscale up
```

You will be provided an authentication link in your terminal,
after which your Tailscale client is associated with your user account,
the private and public keys are generated, and the public key with the Tailscale
controller is exchanged, and the client is added to your Tailnet.

And that's it!

Let's still go through some nitty details about the networking
for few services, especially PiHole on-the-go.

After setting up your mobile app and connecting it to your Tailnet, you should be
able to see your server listed in the list of connected machines.

#### Mobile

This is pretty much the grain and salt for the automatic deployment:
turning Tailscale on-demand when on cellular network but disabled when on WiFi!

After installing the Tailscale app and logging in:

- Go to Settings
- VPN On-Demand
- Enable VPN On-Demand
    - Set Wi-Fi -> Never
    - Set Cellular -> Always
    - Optionally if you like, enable detecting MagicDNS hostnames

![](/img/tailscale-mobile-on-demand.png)

Obvious caveat for this of course is, that when connecting other WiFi's, the
VPN will be disabled. However limiting the use case now for home lab and
private use, I think this is sufficient to manage personally.

### DNS

By default, the machines can be referred to and accessed using their Tailnet IP
addresses and hostnames.
[Tailscale provides multiple ways of referring to host's addresses](https://tailscale.com/kb/1054/dns):

1. Using "Magic DNS", which is Tailscale feature of auto-assigning the hostname
of the machine as the connectable DNS name. This simply means that hostname
`lab-1` machine can be accessed e.g. by: `ssh lab-1` on your account.
How this works is that underneath, Tailscale generates an FQDN for the hostname,
which is a combination of the hostname and a Tailnet suffix. For example,
this means that `lab-kubernetes-1` hostname and a Tailnet name `foobar.ts.net`
full FQDN is `lab-kubernetes-1.foobar.ts.net`. This is then added to the
Search Domain of your Tailnet, which is used for processing incoming DNS
requests within the Tailnet. Tailnet is **always** the first search domain.
In case you are accessing a machine shared
to you, full FQDN is required, but in this case we'll be looking into private
homelab for personal uses. This feature is nowadays enabled by
default for all new accounts. 

2. Using custom DNS settings in the Tailscale Admin console. These settings
can be used to enable/disable the MagicDNS, and adding alternative
nameservers and their configurations. One setting we will be looking into is
`Split DNS` with PiHole.

3. Using public DNS records. This allows using either using custom self-managed
DNS servers or public DNS resolvers in the nameserver settings.

## Services

In this section, lets go through some use cases and services that can
be used with Tailscale while going around town and traveling.

### TLS Certificates with Let's Encrypt

Let's Encrypt is an open certificate authority (CA) which provides easy
automation, provision and renewal of TLS certificates. Personally I have enjoyed
using Certbot for managing TLS certificates, but there are handful of options as well
to choose from.

Explanation and use of Let's Encrypt certificates with
[DNS-01 challenge](https://letsencrypt.org/docs/challenge-types/#dns-01-challenge) and Certbot could be a
whole separate topic itself, so here matter won't be discussed so much.
Let's go through the crude installation and setup process. This section will presume
having an existing registered domain and a
[supported registrar from the Certbot's list of DNS providers](https://eff-certbot.readthedocs.io/en/stable/using.html#dns-plugins).

Install certbot

```bash
sudo apt install certbot
```

Get the necessary API token / credential / config for your domain registrar and configure it

```bash
mkdir -m 0755 -p /etc/letsencrypt/<provider>
nvim /etc/letsencrypt/<provider>/<config-file>
chmod 0700 /etc/letsencrypt/<provider>/<config-file>
```

I'm using Caddy with a Certbot renewal hook which rotates the updated certificates, but
there are other options here to choose as well.

After configuring, new certificates can be requested with:

```bash
certbot certonly \
    --authenticator dns-<provider> \
    --dns-<provider>-credentials /etc/letsencrypt/<provider>/<config-file> \
    -d subdomain.foobar.com \
    -d more.foobar.com \
    --deploy-hook /etc/letsencrypt/renewal-hooks/deploy/00-caddy.sh
```

after this, certificates are issued and later renewed as well! (Certbot will maintain these
running as a Systemd unit in the background.)

### PiHole

Now that the certificate part is taken care of, let's dive into "How can I browse the
Internet without the clutter and ads on-the-go?" Yes, browser level blockers can be used
and I also use both of them. Personally, I feel both of them nicely complement each other!

Setting up PiHole can be done with their
[official instructions](https://docs.pi-hole.net/main/basic-install/) with the desired setup method.

When that is done, the local firewall (using `ufw`) needs to accept DNS requests in tailscale interface:
([IP address pool for Tailscale if not too restrictive](https://tailscale.com/kb/1304/ip-pool))
```bash
# just an example subnet and "to any" definition, feel free to adjust
ufw allow in on tailscale0 from 100.64.0.0/10 to any port 53 proto tcp
ufw allow in on tailscale0 from 100.64.0.0/10 to any port 53 proto udp
```

...and also the [rest of the ports provided in the Tailscale documentation](https://tailscale.com/kb/1082/firewall-ports).

```bash
ufw allow in on tailscale0 from 100.64.0.0/10 to any port 443 proto tcp
ufw allow in on tailscale0 from 100.64.0.0/10 to any port 41641 proto udp
```

...and rerun Tailscale with `--accept-dns=false` flag to avoid PiHole using itself as a resolver.

```bash
tailscale up --accept-dns=false
``` 

Tailscale also has a neat [documentation](https://tailscale.com/kb/1114/pi-hole) explaining
the rest of the steps, but in short summary:

- Disable the Tailnet key expiry for the server unless you want to maintain the key monthly
- [Set Raspberry Pi as the main DNS server in Tailscale DNS settings](https://tailscale.com/kb/1114/pi-hole#step-3-set-your-raspberry-pi-as-your-dns-server)
- Set override local as `Enabled`
- Go to PiHole Admin page **->** Settings **->** DNS **-> Listen on all interfaces, permit all origins** 
    - Otherwise, PiHole won't be accepting DNS requests from the Tailnet clients.
    - Make sure that your network is firewalled properly behind a router so that the PiHole does not publish itself to the world.

And that's pretty much it! Before going wild, there's still one more thing to do in this
kind of setup where TLS certificates are public for internal addresses: Split DNS!

#### Split DNS

Split DNS is a Tailscale feature for splitting DNS requests sent to different resolvers
based on their domain name.

For example, if you want to send out certain requests about `*.barfoo.ly` to another DNS server
and leave rest to the Tailscale to manage, you set up a Split DNS with the given domain suffix and
point them to your desired resolver provider.

In this case, the implementation is made using LE certificates - a public cert - and a
domain name with _an internal IP address_. So how can the devices find the Tailnet IP address
for your domains if the PiHole would be returning the local IP address set at your home and not
Tailnet IP address?

In other words, the server's Tailnet IP address (in the range 100.0.0.0/8) is added to the
domain registrar's records. This will be an A record with the domain you created the certificate
for and the IP address as the value for it. Otherwise your devices try to find your
server's IP address based on the Tailnet's configurations - the PiHole server, effectively
returning the private IP address whatever you have at home, so Tailnet clients cannot
find the server. It may depend on your personal risk model if internal IPs are okay to publish on
public resolvers.

Things to do in the Tailscale Admin panel DNS settings:

- Add a new nameserver and choose the desired provider
- Hit the `...` on the menu item **->** Edit
- Enable "Restrict to domain"
- Set the private domain you have ownership to as the restricted domain

Changes propagate quite fast with Tailscale to the mobile app, so
you should be able to connect to cellular network and try it out!

If the solution does not yet work, check if your newly added A records
in your domain registrar's system have been added to the public resolvers
you configured earlier:

```bash
dig whatever.foobar.com @1.1.1.1  # using the public resolver you added in the previous steps 
```

### Other services

At this point, a working home lab on-the-go should be up and running! All the services
running on your host with domain names should work when you have TLS certificates in place,
A records configured to point to your home server,
and the reverse proxies for the services running on the host(s).

These could be anything you do labbing with such as:

- Home Assistant - bring your home automation with you.
- RSS Reader - read news with the reader you use at home (Miniflux is pretty nice and simple).
- Photo gallery - Photoprism is a cool project!
- NFS - Personal data store in the pocket.

## Summary

In this post, a setup with Tailscale VPN and home lab connectivity was explored. Tailscale
provides a way to automatically turn on VPN when leaving the house, so you'll always
have your lab services with you. Tailscale provides handful of native integrations
for web servers and NFS, but these were not discussed this time.

Alternative options to implement this could include using `.lan` or similar
convention for local addresses and Tailnet machine names and addresses separately. This way,
no domain registrar would be needed. In this case however, if TLS is a needed feature,
a separate CA needs to be created and added to each Tailnet device's trust store
to avoid nagging about self-signed certificates.

Also, many Tailscale features like programmatic APIs, sharing services with friends,
more granular ACL controls, and such were not explored this time. Also, setting up
the LE certificates with auto renewal e.g. for Caddy or Nginx is a separate adventure of its own.

What are you running at home that you like to have also with you on-the-go?

## References

- [Tailscale - Why Tailscale?](https://tailscale.com/why-tailscale)
- [Tailscale Docs - Zero Trust](https://tailscale.com/kb/1123/zero-trust)
- [Tailscale Docs - Wireguard Comparison](https://tailscale.com/compare/wireguard)
- [Certbot Docs](https://eff-certbot.readthedocs.io/en/stable/)
- [Wireguard - Wikipedia](https://en.wikipedia.org/wiki/WireGuard)
- [Tailscale - IP Address Pool](https://tailscale.com/kb/1304/ip-pool)