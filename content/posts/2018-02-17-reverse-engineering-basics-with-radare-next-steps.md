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

Lets see where the entry point of the application is and seek to it. Entrypoints can be listed with command ```ie```. (```i```= get info from opened file -> entrypoint)

```
> aaa
[x] Analyze all flags starting with sym. and entry0 (aa)
[x] Analyze len bytes of instructions for references (aar)
[x] Analyze function calls (aac)
[x] Use -AA or aaaa to perform additional experimental analysis.
[x] Constructing a function name for fcn.* and sym.func.* functions (aan)

> ie
[Entrypoints]
vaddr=0x00400550 paddr=0x00000550 baddr=0x00400000 laddr=0x00000000 haddr=0x00000018 type=program

1 entrypoints
```

So our entrypoint is at address ```vaddr=0x00400550```, lets seek to it as the main function should be disassembled as well. Lets check it out

```
> s 0x400550 (leading zeros can be excluded when defining addresses in hexadecimals, as it does not change the address really)
> pdf
            ;-- section..text:
            ;-- rip:
/ (fcn) entry0 41
|   entry0 ();
|           0x00400550      31ed           xor ebp, ebp                
|           0x00400552      4989d1         mov r9, rdx
|           0x00400555      5e             pop rsi
|           0x00400556      4889e2         mov rdx, rsp
|           0x00400559      4883e4f0       and rsp, 0xfffffffffffffff0
|           0x0040055d      50             push rax
|           0x0040055e      54             push rsp
|           0x0040055f      49c7c0600740.  mov r8, sym.__libc_csu_fini ; 0x400760
|           0x00400566      48c7c1f00640.  mov rcx, sym.__libc_csu_init ; 0x4006f0 ; "AWAVA\x89\xffAUATL\x8d%\x0e\x07 "
|           0x0040056d      48c7c7510640.  mov rdi, sym.main           ; 0x400651
\           0x00400574      e897ffffff     call sym.imp.__libc_start_main ; int __libc_start_main(func main, int argc, char **ubp_av, func init, func fini, func rtld_fini, void *stack_end)
```

Okay, so here we seem to have some brand new information. Lets go through this and see what is happening within an application entrypoint.

```
|           0x00400550      31ed           xor ebp, ebp
```

The base pointer register is zeroed at the initialization. Performing a XOR operation with the same value sets the value to zero. If you don't know what is happening at this point, it might be better to read some boolean algebra before continuing forward!

```
|           0x00400552      4989d1         mov r9, rdx
|           0x00400555      5e             pop rsi
|           0x00400556      4889e2         mov rdx, rsp
|           0x00400559      4883e4f0       and rsp, 0xfffffffffffffff0
|           0x0040055d      50             push rax
|           0x0040055e      54             push rsp
|           0x0040055f      49c7c0600740.  mov r8, sym.__libc_csu_fini ; 0x400760
|           0x00400566      48c7c1f00640.  mov rcx, sym.__libc_csu_init ; 0x4006f0 ; "AWAVA\x89\xffAUATL\x8d%\x0e\x07 "
```

Descriptions, descriptions...
* Register values moved around
* Source index register popped. Why? And where did the value come from? Probably some architecture related stuff.
* Stack pointer value, uh, put to the... top. Yes.
* rax and rsp pushed to the initialized stack.

```
|           0x0040056d      48c7c7510640.  mov rdi, sym.main           ; 0x400651
\           0x00400574      e897ffffff     call sym.imp.__libc_start_main ; int __libc_start_main(func main, int argc, char **ubp_av, func init, func fini, func rtld_fini, void *stack_end)
```

Here, the address of our main function is loaded to the destination index register, which is picked by this function ```__libc_start_main```. 


## Navigating around - Flags and strings in Radare

* iz
* ih
* is
* ic
* ii

## Disassembled code

```
> pdf
            ;-- main:
/ (fcn) sym.main 144
|   sym.main ();
|           ; var int local_24h @ rbp-0x24
|           ; var int local_20h @ rbp-0x20
|           ; var int local_8h @ rbp-0x8
|              ; DATA XREF from 0x0040056d (entry0)
|           0x00400651      55             push rbp
|           0x00400652      4889e5         mov rbp, rsp
|           0x00400655      4883ec30       sub rsp, 0x30               ; '0'
|           0x00400659      64488b042528.  mov rax, qword fs:[0x28]    ; [0x28:8]=-1 ; '(' ; 40
|           0x00400662      488945f8       mov qword [local_8h], rax
|           0x00400666      31c0           xor eax, eax
|              ; JMP XREF from 0x004006d8 (sym.main)
|       .-> 0x00400668      bf83074000     mov edi, str.Enter_password: ; 0x400783 ; "Enter password: "
|       :   0x0040066d      e87efeffff     call sym.imp.puts           ; int puts(const char *s)
|       :   0x00400672      488d45e0       lea rax, [local_20h]
|       :   0x00400676      4889c6         mov rsi, rax
|       :   0x00400679      bf94074000     mov edi, 0x400794
|       :   0x0040067e      b800000000     mov eax, 0
|       :   0x00400683      e8a8feffff     call sym.imp.__isoc99_scanf
|       :   0x00400688      b800000000     mov eax, 0
|       :   0x0040068d      e8b4ffffff     call sym.get_secret
|       :   0x00400692      4889c2         mov rdx, rax
|       :   0x00400695      488d45e0       lea rax, [local_20h]
|       :   0x00400699      4889d6         mov rsi, rdx
|       :   0x0040069c      4889c7         mov rdi, rax
|       :   0x0040069f      e87cfeffff     call sym.imp.strcmp         ; int strcmp(const char *s1, const char *s2)
|       :   0x004006a4      8945dc         mov dword [local_24h], eax
|       :   0x004006a7      837ddc00       cmp dword [local_24h], 0
|      ,==< 0x004006ab      7521           jne 0x4006ce
|      |:   0x004006ad      bf97074000     mov edi, str.Correct        ; 0x400797 ; "Correct!"
|      |:   0x004006b2      e839feffff     call sym.imp.puts           ; int puts(const char *s)
|      |:   0x004006b7      90             nop
|      |:   0x004006b8      b800000000     mov eax, 0
|      |:   0x004006bd      488b4df8       mov rcx, qword [local_8h]
|      |:   0x004006c1      6448330c2528.  xor rcx, qword fs:[0x28]
|     ,===< 0x004006ca      7413           je 0x4006df
|    ,====< 0x004006cc      eb0c           jmp 0x4006da
|    |||:      ; JMP XREF from 0x004006ab (sym.main)
|    ||`--> 0x004006ce      bfa0074000     mov edi, str.Wrong          ; 0x4007a0 ; "Wrong!"
|    || :   0x004006d3      e818feffff     call sym.imp.puts           ; int puts(const char *s)
|    || `=< 0x004006d8      eb8e           jmp 0x400668
|    ||        ; JMP XREF from 0x004006cc (sym.main)
|    `----> 0x004006da      e821feffff     call sym.imp.__stack_chk_fail ; void __stack_chk_fail(void)
|     |        ; JMP XREF from 0x004006ca (sym.main)
|     `---> 0x004006df      c9             leave
\           0x004006e0      c3             ret
```

## Visual Graphs

* VV

## Function calls and flow

* VV examples
* how functions were called and why in this case

## Extra: Stack canaries?

In the original lab exercise, one thing caughy my eye: it was compiled with stack protection enabled, which is used by e.g. as a gcc flag ```-fstack-protect-all```. What are stack canaries? [This blog post](https://xorl.wordpress.com/2010/10/14/linux-glibc-stack-canary-values/) was an excellent wrap-up of the topic.

## Conclusions

Well, there it is! Now you should have some basic understanding of basics of computer architectures, memory handling in assembly, and how to navigate around Radare, so that you can start doing reverse engineering on software binaries! Some things I have noticed though:

* Golang binaries are a swamp to start with as a beginner. One reason to this is that they include the Go runtime with the binary. Don't go there yet if you're a beginner - you'll be overwhelmed.
* Rust binaries seemed interesting and based on a quick look they can be readable with minor effort as well.
* Use your favourite search engine to look for capture-the-flag exercises and challenges, as well as Radare tutorials. CTF challenges are good way to start prepping your puzzle skills together with binary analysis and can really twist your brain around. 

I'll try to post more detailed findings here as well if they appear to be generic related to use of Radare.

Good hunting :-)
