---
title: "Follow-up: Android privacy tools best served fresh"
date: 2015-04-14T05:49:01+03:00
draft: false
---

Recently, there was a study published on OpenSSL versions used by privacy conscious software recommended in the Privacytools.io guide [1]. This study took a stance on not only the OpenSSL crypto library, but the components used by software critical to privacy and safety. The study revealed that many applications are using outdated components. As mobile world is becoming a significant part of how we communicate with people and mobile malware development in Q1 2014 continues to focus exclusively on the Android platform [2], this follow-up study focuses on Android applications mentioned in the study.

I was also curious about some of the most popular free social media and utility applications used on Android, and reported to the developers if I noticed old OpenSSL libraries being used. To not to lose focus from the privacy and security critical applications from the original study, we will focus only on them.

In this follow-up study I used BOMtotal [3] service. It is a service which provides a list of software components used in software and also attempts to provide information about the version of the component.

## Study setup

    * Choose target Android applications based on Privacytools.io collection and the original study [1]
    * Collect the Android Application Packages (APK) from the Google Play Store
        * Applications were downloaded on 2015-04-12
    * Use BOMTotal service for scanning the application components
    * Collect the Bill of Materials URLs, tool version identification, and software components including their respective versions
        * Focus was on OpenSSL and PolarSSL versions
    * Collect OpenSSL version history from the OpenSSL release notes and use the release intervals for 'best before dates' mentioned in the original study [1].
    * Compare OpenSSL versions used by the applications to the OpenSSL version history [4]

## Results

Results with BOMtotal URLs along with full component analysis can be found from here:

https://docs.google.com/spreadsheets/d/12TE-Wr2NpVyGNAIfwAO1A-RdyemhEdfO-_dWBt7p6cA/pubhtml

|Software|Type|Best Before Date based on oldest OpenSSL version | Detected SW Version | OpenSSL Version | PolarSSL Version |
|--------|:--:|:-----------------------------------------------:|:-------------------:|:---------------:|:----------------:|
|proxy.sh Safejumper| VPN provider | 2015-01-08 | 1.5 | 1.0.1j | - |
|AirVPN | VPN provider | - | 1.1.16 | -	|1.3.9|
|Torbrowser| Browser recommendation | - | 15.0.0-RC2 | - | - |
|Firefox|Browser recommendation| - | 36.0.4 | - | - |
| Tutanota | Privacy-conscious email | - | 1.9.2 | - | - |
| ChatSecure | Encrypted instant messenger | 2014-06-05 | 14.1.1-RC2 | 1.0.1g | - |
| Text Secure / Signal | Encrypted instant messenger | - | 2.9.3 | - | - |
| RedPhone / Signal | Encrypted video / voice | 2014-08-06 | 1.0.3 | 1.0.1h | - |
| Linphone | Encrypted video / voice | - | 2.3.2 | - | 1.3.2 |
| Seafile (client) | Encrypted cloud storage | - | 1.6.0 | - | - |
| encryptr | Password manager | - | 1.1.0 | - | - |

It can be seen from the Table 1, from the Android applications three are using OpenSSL in their current versions and two PolarSSL. 6 out of 11 applications were not using either. As this blog post was written, latest version of PolarSSL is 1.3.10 which was then rebranded to mbed SSL [5]. Of these three applications all OpenSSL versions were outdated and several vulnerabilities have been fixed since then [6]. The best before date is calculated based on the oldest version of the OpenSSL used in the tool binary in question [7].

## Brief discussion

It should be noted that BOMtotal does not do vulnerability analysis, but rather gives user a Bill of Materials which contains the components of which the software is built on. This is one approach to begin to understand what our software consists of. It can also be considered what kind of impact the components we use have in our software.

## Credits

Thanks to Kasper Kyllönen ([@KasperKyll](https://twitter.com/KasperKyll))  for doing such an extensive study on privacy and safety conscience applications and tracking OpenSSL version history in a detailed manner, which this follow-up study utilized extensively. Additional thanks also to Marko Laakso in Codenomicon for giving the idea for the follow-up study on Android applications, my colleagues for feedback on the study, and Privacytools.io for maintaining such an important collection of privacy-critical applications.

## References

[1] Privacy Tools best served fresh - a study I made on the OpenSSL versions of the privacytools.io downloads
nkapu (Security Researcher / Hacker)
http://www.reddit.com/r/privacytoolsIO/comments/32fy7h/privacy_tools_best_served_fresh_a_study_i_made_on/ (2015-04-13)

[2] Mobile Threat Report Q1 2014
F-Secure
https://www.f-secure.com/documents/996508/1030743/Mobile_Threat_Report_Q1_2014.pdf (2014)

[3] BOMtotal
Codenomicon
http://www.bomtotal.com

[4] Google Docs Survey: privacytools.io best served fresh (2015-04-11 - 2015-04-12)
nkapu
https://docs.google.com/spreadsheets/d/12YWSVuItaXtsgY2kH134D1_vt1Nkszs_QrhkPISHrgQ/pubhtml

[5] mbed SSL
https://tls.mbed.org/download

[6] OpenSSL Release Notes
https://www.openssl.org/news/openssl-notes.html

[7] Privacy Tools best served fresh documentation and analysis
nkapu
https://docs.google.com/document/d/1Q_wPBBzObSBw1gYChNjVG8zTmxaAjQ7ne1mYU-hCrds/pub