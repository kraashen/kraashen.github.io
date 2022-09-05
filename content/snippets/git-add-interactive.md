---
title: Git add with interactive mode
date: 2022-09-06
draft: false
tags:
    - cli
    - git
    - tools
---

Stuck on situation where you have multiple files with many changes but want to commit some part of the
changes as separate commits?

Git patch feature to the rescue! There are two quick options: `git add --patch` and patching interactively via `git add -i` .
Each have some differences.

With git add you get the interactive git terminal to go through your unstaged, staged, and untracked files,
as well as to call patch (5) to interactively go through the unstaged changed from files. 

```
❯ git add -i
           staged     unstaged path
  1:    unchanged        +1/-1 file1
  2:    unchanged        +7/-1 file2
  
*** Commands ***
  1: status	  2: update	  3: revert	  4: add untracked
  5: patch	  6: diff	  7: quit	  8: help
What now> p

           staged     unstaged path
  1:    unchanged        +1/-1 file1
  2:    unchanged        +7/-1 file2
  
Patch update>> 1

           staged     unstaged path
* 1:    unchanged        +1/-1 file1
  2:    unchanged        +7/-1 file2
  
Patch update>>

diff --git a/file1 b/file1
<diff output>

(1/1) Stage this hunk [y,n,q,a,d,e,?]? ^C
...
```

When calling `git add` with `--patch`, you get only the unstaged changes as prompts if you want them to be included:

```
git add --patch

...
(1/1) Stage this hunk [y,n,q,a,d,e,?]? ?
y - stage this hunk
n - do not stage this hunk
q - quit; do not stage this hunk or any of the remaining ones
a - stage this hunk and all later hunks in the file
d - do not stage this hunk or any of the later hunks in the file
e - manually edit the current hunk
? - print help
```

Manpages are always great resources, so check out `man git-add` for more!
