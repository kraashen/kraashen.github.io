---
title: "Golang Development and Self-signed Cert"
date: 2019-11-28
draft: false
tags:
    - golang
---

Easy way to create a self-signed cert for local development purposes. Handy e.g. 
for running HTTPS locally form the very start of the development.

```bash
$ go run /usr/local/go/src/crypto/tls/generate_cert.go --help

Usage of /tmp/go-build148491876/b001/exe/generate_cert:
  -ca
        whether this cert should be its own Certificate Authority
  -duration duration
        Duration that certificate is valid for (default 8760h0m0s)
  -ecdsa-curve string
        ECDSA curve to use to generate a key. Valid values are P224, P256 
(recommended), P384, P521
  -ed25519
        Generate an Ed25519 key
  -host string
        Comma-separated hostnames and IPs to generate a certificate for
  -rsa-bits int
        Size of RSA key to generate. Ignored if --ecdsa-curve is set (default 
2048)
  -start-date string
        Creation date formatted as Jan 1 15:04:05 2011
```
