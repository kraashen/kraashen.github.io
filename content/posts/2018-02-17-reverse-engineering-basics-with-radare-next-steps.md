---
title: "Reverse Engineering With Radare - Basic Steps Continued"
date: 2018-02-17
draft: true
---

In my [previous post](./2018-01-22-reverse-engineering-basics-with-radare-fundamentals-and-basics), basics and fundamentals for reverse engineering software were discussed. This time I thought about writing a bit more about getting a bit further in inspecting and understanding software binaries. In this post, we'll take a look at one password guess reverse engineering challenge.

## Goals

The aim of this post is to reverse engineer yet again a simple binary and get going with understanding the flow of disassembled code and how to read it and understand how it works. We'll take a look at concepts such as:

* The beginning of a program
* Flags, strings in Radare
* Understanding program flow and disassembled code
* Visual graphs
* Function calls and flow
* Extra: What are stack canaries on Linux?

## Setup

I put the C code of this exercise to Gist. You can  it yourself to check it out or you can check the binary first which I have included to this post. This is actually based on one [Lab exercise I found from Github](https://github.com/s4n7h0/Practical-Reverse-Engineering-using-Radare2/). I decided to do a quick rewrite of the Lab task as I wanted to avoid sploiling the original Lab exercise. So after reading, you can also check them out as well. :-)

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

## When software starts...

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