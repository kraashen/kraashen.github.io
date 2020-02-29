---
title: "Debian Buster and Bluetooth Audio"
date: 2020-02-29
draft: false
tags:
    - debian
    - linux
---

`pulseaudio-module-bluetooth` package needs to be installed for being able to use bluetooth speakers and probably also headsets.

```
apt install pulseaudio-module-bluetooth
pulseaudio -k && pulseaudio --start
```