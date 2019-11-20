---
title: "Kapsi <3 Miniflux RSS"
date: 2019-10-22
tags:
    - linux
    - tweaking
    - self hosting
---

Oletusarvoisesti tämä koskee https://nick.kapsi.fi/miniflux -polkua asennukseen.

```
.htaccess
---

RewriteEngine On

RewriteCond %{REQUEST_URI} ^/miniflux(.*)$
RewriteRule ^index\.html$ http://webapp1.n.kapsi.fi:port/ [P] 
RewriteRule ^(.*)$ http://webapp1.n.kapsi.fi:port/$1 [P]
```

```
webapp1.kapsi.fi
0600 ~/.local/etc/miniflux/miniflux.conf
---
DATABASE_URL=postgresql://nick:pass@db1.n.kapsi.fi/nick
PORT=port
BASE_URL=https://nick.kapsi.fi/miniflux/  # jos konffattu johonkin alipolkuun 
.htaccessissa
```

```
run-miniflux.sh
---

#!/usr/bin/env bash

flock \
  --exclusive \
  --nonblock \
  --conflict-exit-code 0 \
  ~/.lock/miniflux.lock \
  ~/sites/nick.kapsi.fi/miniflux/miniflux -c ~/.local/etc/miniflux/miniflux.conf
```
