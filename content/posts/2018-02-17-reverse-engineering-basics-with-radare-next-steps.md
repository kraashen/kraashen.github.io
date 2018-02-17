---
title: "Reverse Engineering With Radare - Basic Steps Continued"
date: 2018-02-17
draft: true
---

In my [previous post](./2018-01-22-reverse-engineering-basics-with-radare-fundamentals-and-basics), basics and fundamentals for reverse engineering software were discussed. This time I thought about writing a bit more about getting a bit further in inspecting and understanding software binaries. In this post, we'll take a look at one password guess reverse engineering challenge using Radare.

## Goals

The aim of this post is to reverse engineer yet again a simple binary and get going with understanding the flow of disassembled code and how to read it and understand how it works. We'll take a look at concepts such as:

* The execution of a program
* Flags, strings in Radare
* Understanding program flow and disassembled code
* Visual graphs
* Function calls and flow
* Extra: What are stack canaries on Linux?

## Setup

I have put the C code of this exercise to Gist. You can go and check it out yourself 
or you can download the provided binary first which I have included to this post. This exercise is actually based on one [Lab exercise I found from Github](https://github.com/s4n7h0/Practical-Reverse-Engineering-using-Radare2/). 
I decided to do a quick copy and a bit of rewriting of the Lab task as I wanted to avoid sploiling the 
original Lab exercise. So after reading, you can also check them out as well. :-) But for now, I'll focus on keeping the binary as black box'ish.

[Download the binary](./exercise.bin)

```c
#include <stdio.h>
#include <string.h>

char* get_secret() {
    return "s3cr37p455w0rd";
}

int main() {
    char password[16];

    while (1) {
        
        printf("Enter password: \n");
        scanf("%s", password);

        int is_correct = strcmp(password, get_secret());

        if (is_correct == 0) {
            printf("Correct!\n");
            break;
        } else {
            printf("Wrong!\n");
        }
    }
    return 0;
}
```

## Information

As typical, lets check out some generic information about the binary we will be inspecting. Alternatively, you can run ```rabin2 -I [path_to_binary]``` on the command line to get similar information. **Rabin2** is a binary information extractor based on Radare. Within Radare, you can use ```iI``` command to get this information.

```
[0x00000000]> iI
arch     x86
binsz    7946
bintype  elf
bits     64
canary   true
class    ELF64
crypto   false
endian   little
havecode true
intrp    /lib64/ld-linux-x86-64.so.2
lang     c
linenum  true
lsyms    true
machine  AMD x86-64 architecture
maxopsz  16
minopsz  1
nx       true
os       linux
pcalign  0
pic      true
relocs   true
relro    partial
rpath    NONE
static   false
stripped false
subsys   linux
va       true
```

This time, I'm going to attempt to explain further what the output of this command tells us about binaries. I didn't find any information what some of the abbreviations stand for so I'll try my best list them down based on sources I found.

* **arch**: Architecture for which the binary has been assembled for. 
* **binsz**: Size of the binary program in bits. 
* **bintype**: Type of the binary, e.g. an ```elf``` binary is an executable Linux binary. See [Executable and Linkable Format Wiki page] (https://en.wikipedia.org/wiki/Executable_and_Linkable_Format) for more details on linux binaries. Respectively on Windows, this could be Portable Executable (PE) and on OS X a Mach-O binary.
* **bits**: Bitness of the binary. Commonly 32/64 bit nowadays. 
* **canary**: Does the binary have stack canary protection enabled.
* **class**: Class of the binary
* **crypto**: Boolean flag to tell if the binary is encrypted. This is a method in the binary protection.[This article from Phrack](https://grugq.github.io/docs/phrack-58-05.txt) is a great source to understand binary encryption and its background in more detail.
* **endian**: Endianness of the binary. See [this Wiki page](https://en.wikipedia.org/wiki/Endianness) for more details, this is useful to understand later on when endianness can be reversed on some binaries.
* **havecode**: Probably tells if the binary has debug symbols. I compiled the example binary with debug symbols enabled and disabled and this flag changed depending if debug symbols were enabled or not. 
* **intrp**: No idea.
* **lang**: Language which the binary was developed in.
* **linenum**: No idea. 
* **lsyms**: Also no idea.
* **machine**: Machine and architecture the binary was compiled on.
* **maxopsz**: Maximum bit size of an operation the binary includes.
* **minopsz**: Minimum bit size of an operation the binary includes.
* **nx**: NX bit is related to executable space protection. This tells us if parts of the memory locations of the binary are marked as non-executable. Processor will then refuse to execute instructions in these memory locations.
* **os**: Operating system kernel for which the binary has been compiled for.
* **pcalign**:
* **pic**: Is the binary [position-independent code](https://en.wikipedia.org/wiki/Position-independent_code). This means that the machine-code can be placed anywhere in the memory and it would execute regardless of its absolute address. This is common e.g. for shared libraries. 
* **relocs**:
* **relro**:
* **rpath**:
* **static**: A binary can be static or a dynamically linked binary. This tells us which one the binary is.
* **stripped**: When a binary is stripped, it has the symbols table removed and results in a more compact binary. A non-stripped binary includes more information due to the included symbols table and possible also debug symbols as well.
* **subsys**: 
* **va**: 


## When software starts...

Lets see where the entry point of the application is and seek to it.

## Navigating around - Flags and strings in Radare

## Disassembled code

## Visual Graphs

## Function calls and flow

## Extra: Stack canaries?

## Conclusions

Well, there it is! Now you should have some basic understanding of basics of computer architectures, memory handling in assembly, and how to navigate around Radare, so that you can start doing reverse engineering on software binaries! Some things I have noticed though:

* Golang binaries are a swamp to start with as a beginner. This is due to that they include the whole Go runtime with the binary. Don't go there yet if you're a beginner - you'll be overwhelmed.
* Rust binaries seemed interesting and based on a quick look they can be readable with minor effort as well.
* Use your favourite search engine to look for capture-the-flag exercises and challenges, as well as Radare tutorials. CTF challenges are good way to start prepping your puzzle skills together with binary analysis and can really twist your brain around. 

I'll try to post more detailed findings here as well if they appear to be generic related to use of Radare.

Good hunting :-)
