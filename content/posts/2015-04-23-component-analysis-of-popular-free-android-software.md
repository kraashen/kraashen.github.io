---
title: "Component analysis of popular free Android software"
date: 2015-04-23T18:23:01+03:00
draft: false
tags:
    - android
---

In my previous post I took a look at some of the Privacytools.io guide's Android applications and their respective OpenSSL versions due to an inspiration that a study gave me [1]. I also thought to continue this as a follow-up and take a look into some of the popular free Android software available on Google Play and tried to study what they are built upon.

## Study set up

1. Choose target Android applications based on common popularity among people and Play Store lists of popular free applications
2. Collect the Android Application Packages (APK) from the Google Play Store
 * Applications were downloaded on 2015-04-15
3. Use BOMTotal[2] service for scanning the application components
4. Collect the Bill of Materials URLs, tool version identification, and software components including their respective versions
 * Focus was on OpenSSL and getting familiar with 3rd party ad components
5. Collect OpenSSL version history from the OpenSSL release notes and use the release intervals for 'best before dates' mentioned in the original study on Privacytools.io guide apps [3].
6. Compare OpenSSL versions used by the applications to the OpenSSL version history [4] and collect summary of possible third party ad components.
 * Contact security teams of those developers whose applications have outdated OpenSSL libraries

## Results

The document along with full BOMtotal links can be found from Google Docs:

https://docs.google.com/spreadsheets/d/1U-smPMQ-3xUIwdWApWH9VCAiAegTlk0zsi0B2tWDonU/pubhtml

|Software|Type|Best Before Date based on oldest OpenSSL version | Detected SW Version | OpenSSL Version |3rd party ad libraries|
|:------:|:--:|:-----------------------------------------------:|:-------------------:|:---------------:|:--------------------:|
| AntiVirus Security AVG | Utility | - | 4.3 | - | x |
| Avast Mobile Security | Utility | - | 4.0.7880 | -	||
| CCleaner | Utility | - | 1.09.36 | - ||
| Clean Master | Utility | - | 5.9.5 | - ||
| F-Secure Mobile Security | Utility | - | 15.0.016484 | - | [a] |
| Facebook | Social Media | current | 31.0.0.19.13 | 1.0.2a | [a] |
| Facebook Messenger | Instant Messaging | - | 25.0.0.17.14 | n/a |
| Flashlight | Utility | - | 5.2.4 | - | [a] |
| Freedome | VPN | 2014-08-06 | n/a | 1.0.1h ||
| Instagram | Social Media | - | 6.19.0 | -	||
| LINE | Video / Phone | - | 5.1.2 | - | [a] |
| OGQ Backgrounds HD | Utility | - | 3.6.4 | - | [a] |
| Skype | Video / Phone | 2014-10-15 | 5.3.0.65524 | 1.0.1i	||
| Snapchat | Instant Messaging | current | 9.5.2.0 | 1.0.1m | [a] |
| Stylem Media Backgrounds | Utility | - | 2.0.5 | - | [a] |
| Surpax LED Flashlight | Utility | - | 1.0.6 | - | x |
| Telegram | Instant Messaging | - | 2.7.0 | - |
| Tinder | Social Media / Dating | - | 4.0.6 | - |
| Viber | Video / Phone | - | 5.3.0.2339 | - | [a] |
| VKontakte | Social Media | - | 3.11 | - | [a] |
| Whatsapp | Instant Messaging | - | 2.12.5 | -	|

*Table 1. Android applications with their OpenSSL version results and possible 3rd party advertisement libraries. [x]=3rd party components present, [a]=google-ad component present.*

Table 1 shows the summary of OpenSSL versions, their 'best before dates' and if there was 3rd party ad libraries found. Applications were downloaded on 2014-04-15 but I wanted to take time for the developers of those applications who had outdated OpenSSL components to respond to me first before publishing the results. Best before date was calculated as Kasper Kyllönen collected them in his study based on the oldest OpenSSL version used in the tool binary in question [3].

It can be seen that most of the applications are not using OpenSSL, but then again there are some cases with ad components that are not Google's own. These ad components included libraries such as tapjoy, inmobi, and mopub, one of which was within an Antivirus application and other was a common flashlight app. I took the digging a bit deeper and focused also on what other components those applications needed: common apps included e.g. google-wallet, google-chromecast, social media apis, google-drive, and google-fitness libraries which are in some cases out of scope of the use of the application in my opinion. 

## Discussion and thoughts

What our applications are made of is one fundamental basis to start to understand what kind of impact the components that we use have in our software. This does not directly indicate vulnerability analysis but it comes as a part of this. BOMtotal has leveraged the work to dissect and dive into what the apps we use and have developed are using, and can plan and react if we notice something out of order - even in our own applications we develop.


## Credits and thanks

Thanks to Ossi Herrala and Antti Tönkyrä for assisting in reviewing my analysis, and all security teams of developers and services who include OpenSSL in their software who responded in a polite and quick manner to my reports.

As of writing this blog post, those parties responded to the notification within 48 hours I sent about OpenSSL to them. Some have also patched them already.

[1] http://tracingbytes.blogspot.com/2015/04/follow-up-android-privacy-tools-best.html

[2] http://www.bomtotal.com/
BOMtotal

[3] https://docs.google.com/document/d/1Q_wPBBzObSBw1gYChNjVG8zTmxaAjQ7ne1mYU-hCrds/pub
nkapu, Security Researcher / Hacker

[4] https://www.openssl.org/news/openssl-notes.html
OpenSSL Release Notes 
