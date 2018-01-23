---
title: "Reverse Engineering With Radare - Fundamentals and Basics"
date: 2018-01-22
draft: false
---

As I got more and more curious on how software works, I felt it essential as a software and systems engineer to start understanding deeper low-level internals of software. So I thought about diving more into the topic of reverse engineering from software developer's perspective using an open source tool called Radare. There are plenty of extremely well written Radare tutorials on reverse engineering which may include topics such as finding hidden passwords and injection techniques. However, I did not find so many articles on how to analyze binaries in general and at the same time understand it together with the knowledge of computer architectures and their murky innards.

So eventually, reality hit me: It's been almost 10 years from my computer architecture classes! I had no prior experience in reverse engineering besides the recent online examples. I tried to dive into Radare in straightforward manner with some hands-on examples, but I repeatedly came to wonder how memory management works, how assembly code should be read *properly*, how registers are used (and what they even where), and so forth. Well, I was still successful though in reverse engineering some simple applications related to password hunting exercises, but then I decided to go back to basics.

So, couple of steps back, and back to studying some computer architectures. Hopefully it will help understanding low-level code and how to analyze it better.

In this post, I'll go through some of the very basic things in reverse engineering and computer architectures that I had to study and revise a bit. Also, a look will be taken on how to disassemble a very simple Hello World binary using [Radare](https://www.radare.org/r/). I will explain the software at the later part of this post. 

The goal is to get familiar with understanding assembly and how software internals work. These will be combined together with some topics that I felt essential in starting a journey in reverse engineering and understanding software internals without prior knowledge of any kind of reverse engineering.

# Reverse Engineering

Wikipedia defines reverse engineering in general as:

> -- the processes of extracting knowledge or design information from a product and reproducing it or reproducing anything based on the extracted information.[1]:3 The process often involves disassembling something (a mechanical device, electronic component, computer program, or biological, chemical, or organic matter) and analyzing its components and workings in detail.

When it comes to software, the meaning may vary. There are taxonomies that define reverse engineering as rebuilding or understanding the system logic from the end to the beginning (or vice versa). 

However, there can be different types of systems to analyze: some of them can be black boxes where there is no source code availble, they can be obfuscated, and some may be commented or documented or not neither at all. Reverse engineering of software may also have different kind of goals: dissecting, also known as disassemblying, the software binary in raw machine language to understand how it works and what it does (which is what Radare does, for instance), analysing the information exchange of the software e.g. in network traffic when it comes to protocol reverse engineering, and decompiling the software, which is a technique to attempt to create a high-level representation of the original binary and it's contents.

In this post, focus will be on reverse engineering software binaries.

## Assembly, Assembling, and Disassembling

Assembly (ASM, aka. Assembler) language is a low-level programming language. It is very close to the machine code instructions of the hardware, and is dependent to the architectures it has been developed for. Assembly uses mnemonics - short textual and easily rememberable statements - that represent low-level machine instructions (code) which are referred to as opcodes, registers, and flags. Assembly is converted to machine code using an assembler. There are also multiple types of assemblers, which allow e.g. cross-compilation of existing ASM code to other systems.

Lets take a look at a simple "Hello World w/ assembly" program:

```c
#include <stdio.h>

int main(void) {
    printf("Hello World w/ Assembly!\n");
    return 0;
}
```

This compiled on Windows platform with WSL into following bytecode

```
$ hexdump -C | head
00000000  7f 45 4c 46 02 01 01 00  00 00 00 00 00 00 00 00  |.ELF............|
00000010  02 00 3e 00 01 00 00 00  30 04 40 00 00 00 00 00  |..>.....0.@.....|
00000020  40 00 00 00 00 00 00 00  d8 19 00 00 00 00 00 00  |@...............|
00000030  00 00 00 00 40 00 38 00  09 00 40 00 1f 00 1c 00  |....@.8...@.....|
00000040  06 00 00 00 05 00 00 00  40 00 00 00 00 00 00 00  |........@.......|
00000050  40 00 40 00 00 00 00 00  40 00 40 00 00 00 00 00  |@.@.....@.@.....|
00000060  f8 01 00 00 00 00 00 00  f8 01 00 00 00 00 00 00  |................|
00000070  08 00 00 00 00 00 00 00  03 00 00 00 04 00 00 00  |................|
00000080  38 02 00 00 00 00 00 00  38 02 40 00 00 00 00 00  |8.......8.@.....|
00000090  38 02 40 00 00 00 00 00  1c 00 00 00 00 00 00 00  |8.@.............|
...
```

Which shown in disassembled form in Radare as

```assembly
> s main
> pdf
|           0x00400526    55           push rbp
|           0x00400527    4889e5       mov rbp, rsp
|           0x0040052a    bfc4054000   mov edi, str.HelloWorld
|           0x0040052f    e8ccfeffff   call sym.imp.puts
|              sym.imp.puts(unk)
|           0x00400534    b800000000   mov eax, 0x0
|           0x00400539    5d           pop rbp
\           0x0040053a    c3           ret
```

#### Binaries

A binary file is essentially a sequence of bytes. There are different types of binary files, which may include e.g. images and audio files. However, a software binary can be defined as:

> A file is interpreted as a representation of a software in machine code when it is a not a text file (binary) and is treated as an executable and ran by the system. 

Binaries may include information such as headers and other metadata which the system uses how to interpret the file when executed. Binaries without headers and metadata is called a flat binary. Exploring hex dumps of the machine code to understand the internals of it may be tedious, so this is where disassemblying comes to play.

#### Disassemblers

Disassembler is a program that translates the compiled machine code representation to assembly language. The output of the program aims for readability, making it eventually a reverse-engineering tool. While disassembler produces an assembly output of the original software, an interactive disassembler allows examination of the software that shows the changes made by the user. Software such as Radare in this case work greatly as a debugger as well, so it is also possible to interact and examine the software while running and debugging it.

### Opcodes and instructions

Opcode stands for operation code. All opcodes together form the instruction set of the processor. An instruction set is a specified set of commands a processor can execute. Opcodes are a part of these machine language that tells the processor what operation to be performed. Opcodes also may include operands that act as the data to be processed by the operation. They can be represented in a short textual form called instructions that are mnemonics which tell the programmer what operation is being performed in an easily memorable and understandable form.

```assembly
PUSH ebp     ; <- Here, PUSH is an instruction and ebp is the operand
MOV ebp, esp ; <- Same rules apply

...

SUB ebp, 0x04h 

; and so forth
```

Opcodes and instruction sets are different depending across various processor architectures, and some architectures support different types of instructions. Operands may be e.g. memory addresses and values in the stack. To understand the instructions supported by your architecture or the architecture of the software you are reverse engineering, you'll have to look for reference manuals of that specific architecture.

### Registers

There are many register types, especially when it comes to [hardware registers](https://en.wikipedia.org/wiki/Hardware_register). In assembly language and reverse engineering, we'll be talking mostly about processor registeries. These are the real deal in this case.

The operations described earlier process data. This data is stored in memory. It can be volatile memory (RAM) or non-volatile memory (disk). The data is faster to handle in the processor itself instead of doing operations in the memory. Processors have a set of registers that act as a temporary and quickly available location for data to be processed.

Registeries vary between different architectures as well. Here, focus will be on [x86 architecture](https://en.wikibooks.org/wiki/X86_Assembly/X86_Architecture) to take a brief look on some basics. Registers are categorized according to the instructions that operate on them.

#### General-purpose registers

As the name implies, general-purpose registers (GPR) can hold data or a memory location in a form of an address. They can be used quite freely by the programmer with opcodes without too much limitations. GPRs have conventions based on their naming, but modern CPUs can use them quite freely for storing data, and different environments have different conventions. Even compilers exploit this freedom of conventions on different platforms.

x86 architecture GPRs are:

* **AX** (Accumulator register).
* **CX** (Counter register).
* **DX** (Data Register).
* **BX** (Base register).
* **SP** (Stack Pointer register).
* **BP** (Stack Base Pointer register).
* **SI** (Source Index register).
* **DI** (Destination Index register). 

These listed are all by default 16-bit registers. Registers are categorized to 8, 16, 32, and 64 -bit register based on their prefixes and suffixes:

* ```E``` appended to the register abbreviation (E = extended), means a 32-bit register.
 * ```EAX```, ```ECX```...
* ```R``` appended, means a 64-bit register.
 * ```RAX```, ```RCX```...
* Accumulator, counter, data, and base registers with either ```H``` or ```L``` suffix mean 8-bit register.
 * ```H``` as suffix means the most-significant byte, higher half of the 16 bits.
 * ```L``` as suffix means the least-significant byte, lower half of the 16 bits.

Let's take a look at a table to get a better look:

| Register bits | AX | CX | DX | BX |
| ------------- |-------------| -----|---|---|
| 64-bit      | RAX | RCX | RDX | RBX |
| 32-bit      | EAX | ECX | EDX | EBX |
| 16-bit | AX | CX | DX | BX |
| 8-bit | AH/AL | CH/CL | DH/DL | BH/BL |

Similarly this works for stack pointer, base pointer, source index, and destination index registers, but they don't have 8-bit correspondents.

#### Flags

In processors, there is [a long list of so called flags](https://en.wikibooks.org/wiki/X86_Assembly/X86_Architecture#EFLAGS_Register) that exist within the 32-bit register. What are they for? 

The results of certain operations or state are stored to these flags with either bit value set to 0 or 1. From this flag register, the processor will understand what operation will be executed next and how. For instance, opcode ```JNE``` (jump to memory location if operands are not equal) uses flag ```ZF```, which is a flag to indicate whether result of an operation is zero. Similarly, when doing calculation with large integers, which can [overflow](https://en.wikipedia.org/wiki/Integer_overflow), an overflow flag ```OF``` is used to indicate if the result is too large for the register to contain.

Flags themselves are rarely visible from the assembly itself, but it is useful to understand how they work.

### Heap & Stack - high level look

Still hanging along? Great! Before going into actual reverse engineering example, a quick look will be taken at how heap and stack memory works in assembly. This is essential to help understanding what is happening in the assembly code and why. I won't dive into too much details here, so I recommend also checking out more detailed sources on memory management as well in the end of this post.

When a software is executed, memory is reverved for the application. Part of this memory is allocated for stack and the maximum size of it is usually fixed by the operating system. Part of the memory is reserved for heap.

How does the stack memory work? It is fairly simple. It's pretty much similar to the [stack data type](https://en.wikipedia.org/wiki/Stack_(abstract_data_type)), where values are pushed on top of the stack and popped out in the reverse order to be used as. Like a LIFO queue. It's like blazing-fast bookkeeping and putting stuff aside while doing something else.

Stack size is fixed from the start of the application or thread. If there are multiple threads, they will have their own memory stack. When the stack is reserved, the stack pointer ```ESP``` (32-bit system) will point to the top of the stack. The stack grows downwards from the top to the bottom and stack pointer address follows on the top of the stack. If the pointer runs out of memory address scope and therefore past the top, a [stack buffer overflow](https://en.wikipedia.org/wiki/Stack_buffer_overflow) will occur.

Stack contains e.g.:

* Local variables of functions that will go out of scope after executing them.
* Return address of the function, i.e. where will the processor continue after the function returns
* Function arguments before calling them
 * NOTE! There are also conventions to use registers for function arguments instead of the stack. For instance, 64-bit Windows systems do this, which I learned the hard way.

How about heap? In contrast to stack, heap is more flexible and more unorganized. It is separate memory from the stack without a specific layout. A programmer can define and manipulate variables which are placed on heap. Programmer will then have the responsibility of releasing this memory manually. In some languages, this is done by garbage collector when the variables are not used anymore. 

While stack memory is fixed, memory on the heap is allocated and deallocated dynamically during the run-time of an application. When a software runs out of heap memory, a [heap overflow](https://en.wikipedia.org/wiki/Heap_overflow) will occur. Without memory protection on the systems, even data outside the scope of the software could be affected.

Following picture shows an example of a layout of a stack and heap within the memory allocated to an application. ([Source](https://en.wikipedia.org/wiki/Data_segment))

![](/img/memorylayout.png)

So, some key differences:

#### Stack

* Managed by compiler (mostly, of course programmer has the power which are local variables in functions)
* Last-in-first-out (LIFO) -principle
* Contains local variables, return addresses of functions
* Grows from the top to bottom
* Fixed in size (usually)
* Variables are deallocated automatically when they go out of scope
* Threads have own stacks

#### Heap

* Managed by programmer
* Contains variables that are out of local scope
* Programmer or garbage collector is responsible in freeing the memory
* Grows from the bottom to the top
* Allocated in run-time
* More heap can be allocated by the operating system if the amount of memory is not sufficient
* Threads share the heap

# Radare?

Enter Radare! It is a cross-platform open source tool and swiss army knife for binary analysis. In this blog post, I'm talking mainly about Radare2 which is a rewritten project based on the original Radare project. Commonly people refer to it also just as Radare. 

Radare has a **really** steep learning curve for reverse engineering, at least for a newbie like me, so I'll break down some basic commands that might be useful to get started tweaking around. I'm still studying it more myself as well, so I'll also try to break down the analysis into understandable chunks.

Based on Github:

> Radare project started as a forensics tool, a scriptable commandline hexadecimal editor able to open disk files, but later support for analyzing binaries, disassembling code, debugging programs, attaching to remote gdb servers, ..

The user interface is Vim-like by default, but nowadays there are also GUIs available to get more IDA-kind of feeling and which have been quite active recently.

Here are some of the features of Radare and what is can do at the time of writing:

* Disassemblying and assemblying
* Debugging
* Hex editing
* Injection
* Emulator
* Binary diffing

## Hello World revisited

So having just installed and fired up Radare with the compiled binary and you land on an empty terminal. What now? It works like a shell. In fact - it is a shell.

* If you type ```?``` after a command and hit return, you'll get help texts related to that command or subcommand.
* ```ie``` lists the entrypoints of the binary. Handy for pinpointing where the application logic starts.
* ```iz``` lists strings of the binary.
* ```iI``` tells information about the binary, related to the headers that were discussed briefly in the binary section
* ```V``` toggles visual mode
* ```VV``` toggles visual mode with graph
 * ```p``` is used for navigating between different views in the visual mode. Use ```hjkl``` to navigate around.
* ```s``` short for "seek". Takes a variable, address or function name as an argument to seek within the address space of the application.
* ```~``` is used for grepping something from the output of previous command. Think: ```iz~Hello```
* ```p``` print command
 * ```pdf``` print disassembled function
* ```aa(a)```, this is your trusted companion to start analyzing. ``aa`` stands for analyze all, but does not really do all it could do (huh?). The newer ```aaa``` does a bit more extensive analysis
 * You can also start Radare using ```r2 -A[A]``` command line flags to do initial analysis.

So what has a simple Hello World eaten? Let's check out the file information:

```
> iI
file    [snip]
type    EXEC (Executable file)
pic     false
has_va  true
root    elf
class   ELF64
lang    c
arch    x86
bits    64
machine AMD x86-64 architecture
os      linux
subsys  linux
endian  little
...
```

So here we can see plenty of information: The file is a Linux (ELF) executable developed in C (duh?) on x86 64-bit architecture, and it's little endian. Now let's analyze the binary and check out its internals:

```asm
; what 'aa' does
> aa
[x] Analyze all flags starting with sym. and entry0 (aa)

; what 'aaa' does
> aaa
[x] Analyze all flags starting with sym. and entry0 (aa)
[x] Analyze len bytes of instructions for references (aar)
[x] Analyze function calls (aac)
[x] Use -AA or aaaa to perform additional experimental analysis.
[x] Constructing a function name for fcn.* and sym.func.* functions (aan)

; 'aaaa' mentioned? we must go deeper...
> aaaa
[x] Analyze all flags starting with sym. and entry0 (aa)
[x] Analyze len bytes of instructions for references (aar)
[x] Analyze function calls (aac)
[x] Emulate code to find computed references (aae)
[x] Analyze consecutive function (aat)
[x] Constructing a function name for fcn.* and sym.func.* functions (aan)
[x] Type matching analysis for all functions (afta)

; lets seek to the main function
> s main 

; ...and check out the main function with print disassemble function command
> pdf
/ (fcn) sym.main 21
|           0x00400526    55           push rbp
|           0x00400527    4889e5       mov rbp, rsp
|           0x0040052a    bfc4054000   mov edi, str.HelloWorldwassembly
|           0x0040052f    e8ccfeffff   call sym.imp.puts
|              sym.imp.puts(unk)
|           0x00400534    b800000000   mov eax, 0x0
|           0x00400539    5d           pop rbp
\           0x0040053a    c3           ret
```

Alright, great! Now we are ended up in the main function of the application. So let's break this down and use our knowledge from earlier to see what's going on. Layout of the pdf output is following:

```
memory address    opcodes in hex    instruction and operands    
0x00400526        55                push rbp
```

So lets break it down line by line what happens here:

```asm
; the base pointer, where the execution currently is, is pushed to the stack
; the program will later know that it will return the execution here
           0x00400526    55           push rbp

; move current stack pointer to the base pointer register
           0x00400527    4889e5       mov rbp, rsp

; move our Hello World! string to the edi register
           0x0040052a    bfc4054000   mov edi, str.HelloWorldwassembly

; call the puts function to print the string from the register
; the function will pick up the parameter as an argument from the edi register
           0x0040052f    e8ccfeffff   call sym.imp.puts
              sym.imp.puts(unk)

; set eax register value to zero, which is our set return value
           0x00400534    b800000000   mov eax, 0x0

; pop the value we put to the stack earlier back to the base pointer register
           0x00400539    5d           pop rbp

; finally, return
           0x0040053a    c3           ret
```

# Conclusions

This was quite a journey. Here, basics of computer architectures were revisited and reverse engineering principles were studied without too much prior knowledge of them using Radare. It felt a bit silly having a Hello World example here, but I found it still useful to understand and combine system fundamentals together with the syntax and basics of assembly, how Radare is used, and it gave a basic toolset to start diving a bit more deeper from now on.

Radare has also a nice list of other tools that come in handy for binary analysis. These include binary diffing, binary inspection, command line parameters for analyze-all during startup, debugging... But they will be topics for other posts later on.

[Megabeets: A journey into Radare2](https://www.megabeets.net/a-journey-into-radare-2-part-1/) is really good blog post to read through as a next step and I highly recommend it. That post and Disobey event in Finland both inspired me a lot to start studying the topic more. The Megabeets post goes a bit more deep into analysis of a binary and shows more features of Radare that can be used to reverse engineer binaries and explains them in a very good way.

# Sources to study

* [Wikipedia: Integer overflow](https://en.wikipedia.org/wiki/Integer_overflow)
* [Wikipedia: Computer architecture](https://en.wikipedia.org/wiki/Computer_architecture)
* [Studytonight: Architecture of computer system](https://www.studytonight.com/computer-architecture/architecture-of-computer-system.php)
* [Wikibooks: X86 Architecture](https://en.wikibooks.org/wiki/X86_Assembly/X86_Architecture#EFLAGS_Register)
* [X86 Opcode and Instruction Reference](http://ref.x86asm.net/)
* [Wikipedia: Memory management](https://en.wikipedia.org/wiki/Memory_management)