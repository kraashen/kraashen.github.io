---
title: "FFXIV Linux Setup"
date: 2019-11-20
draft: false
tags:
    - gaming
    - linux
---

Get and install [GE 
Proton](https://github.com/GloriousEggroll/proton-ge-custom/). Confirmed working 
version at the time of writing was 4.19-GE-1.

Based on reports, for some reason the game has issues with the cutscene 
opening when opening the game client. Open to edit `FFXIV.cfg`. File is located 
in `.steam/steam/steamapps/compatdata/39210/pfx/drive_c/users/steamuser/My 
Documents/My Games/FINAL FANTASY XIV - A Realm Reborn`

```bash
# Update CutsceneMovieopening value
...
CutsceneMovieopening    1
...
```

Save and run the game <3.
