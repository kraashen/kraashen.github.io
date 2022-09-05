---
title: Useful tools to remember
date: 2022-09-05
draft: false
tags:
    - cli
    - tools
    - linux
---

Collection of notes about some of my favourite or otherwise great tools encountered.
Some I have used, some only encountered yet / read about but heard good things about.

💡 = "note to self" for curiosity, to be checked out

## UX^2

* [`fzf`](https://github.com/junegunn/fzf): Reverse search goodness. Cannot live without this.
* [`ripgrep`](https://github.com/BurntSushi/ripgrep): Recursive grepping with pretty outputs.

## Shell things

* [`powerline10k`](https://github.com/romkatv/powerlevel10k): Zsh supercharger
* [`zsh-autosuggestions`](https://github.com/zsh-users/zsh-autosuggestions): Makes zsh more [fish'y](https://fishshell.com/).
* [`zsh-completions`](https://github.com/zsh-users/zsh-completions): Additional completion definitions for [many](https://github.com/zsh-users/zsh-completions/tree/master/src) tools
* [`neofetch`](https://github.com/dylanaraps/neofetch): Distro information with candyfloss in terminal
* [`bash hackers wiki`](https://wiki.bash-hackers.org/): Great source for learning to shell.

## Connectivity

* [`mosh`](https://mosh.org/): When SSH meets UDP! More redundant SSH, especially when traveling.

## Debugging

* [`strace`](https://strace.io/): System call tracer
* [`radare2`](https://github.com/radareorg/radare2): Full-blown customizable reverse engineering framework
* [`tcpdump`](https://www.tcpdump.org/): Capture packets
* [`qemu`](https://www.qemu.org/): Processor emulation
* [`chainsaw`](https://github.com/WithSecureLabs/chainsaw): Windows Event Log searching and hunting 💡

## Data manipulation

* [`jq`](https://stedolan.github.io/jq/): Just jq'ing with JSON
  * [JMESPath syntax](https://jmespath.org/)
* [`yq`](https://mikefarah.gitbook.io/yq/): Do you even YAML?
* [`csvq`](https://mithrandie.github.io/csvq/): CSV prettified

## Kubernetes tools

* [`k3s`](https://k3s.io/): Minimalistic kubernetes environment runtime in single binary 💡
* [`falco`](https://falco.org/): Kubernetes threat detection on steroids 💡
* [`popeye`](https://popeyecli.io/): K8s cluster sanitizer 💡

## systemd notes

### Tools

* `systemd-nspawn`: Run lightweight namespace containers
* [`mkosi`](https://github.com/systemd/mkosi)

### Commands to remember

* `systemd-analyze security <unit-name>`: Print out some basic systemd unit hardening status information
* `systemctl list-units|list-timers --failed`: Quickly glance over failed units or timers
* `systemctl show <unit-name>`: Show unit information

## Practicing

* [Kioptrix](https://www.vulnhub.com/series/kioptrix,8/): Great practicing platform

## Software supply chains

* [`OWASP Dependency Checker`](https://mikefarah.gitbook.io/yq/)
* [`Safety (Python)`](https://github.com/pyupio/safety)
* [`Dependency Track`](https://dependencytrack.org/): Track your software and hardware inventories 💡 
