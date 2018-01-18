---
title: "Reverse Engineering Basics with Radare from Software Engineer perspective"
date: 2018-01-xx
draft: true
---

Some time ago I got more and more curious on how software works on low level. I felt it essential for software and system engineers to understand software internals so I thought more about diving into the topic of reverse engineering from software development perspective. I found lots of Radare tutorials on reverse engineering and finding examples such as hidden passwords and injection techniques, but not so many on just general how to analyse binaries and understand the software internals and more importantly: Why things work as they just do.

In this post, I'll go through some of the very basic things I had to revise myself a bit, since it's been almost 10 years from my computer architecture classes, and how to disassemble a very simple binary using [Radare](https://www.radare.org/r/). The goal is to get familiar with understanding Assembly and how software internals work.

# Reverse Engineering

Wikipedia defines reverse engineering in general as:

> - - the processes of extracting knowledge or design information from a product and reproducing it or reproducing anything based on the extracted information.[1]:3 The process often involves disassembling something (a mechanical device, electronic component, computer program, or biological, chemical, or organic matter) and analyzing its components and workings in detail.

When it comes to software engineering, the meaning may vary. There are flexible taxonomies that attempt to define reverse engineering as simply rebuilding or understanding the system logic from the end to the beginning. 

However, there can be different types of systems to analyze: some of them can be black boxes when there is no source code availble, they can be obfuscated, and documented or not documented at all. Reverse engineering of software may also have different kind of goals: dissecting (aka. disassemblying) the software binary in raw machine language to understand how it works and what it does (which is what Radare does, for instance), analysing the information exchange of the software e.g. in network traffic when it comes to protocol reverse engineering, and decompiling the software, which is a technique to attempt to create a high-level representation of the original binary and it's contents.

In this post I will be focusing on reverse engineering software binary.

## Assembly, Assemblying, and Disassemblying

Assembly (ASM, aka. Assembler) language is a low-level programming language. It is very close to the machine code instructions of the hardware, and is dependent to the architectures it has been developed for. Assembly uses mnemonics - short textual and easily rememberable statements - that represent low-level machine instructions (code) which are referred to as opcodes, registers, and flags.  Assembly is converted to machine code using a so called assembler. There are multiple types of assemblers, which allow things such as cross-compilation of existing ASM code to other systems.

```asm
# some example 
```

There are different types of binary files. However, a file that is not a text file (binary) and that is treated as an executable (!) and ran by the system, is interpreted as a representation of a software in machine code. Binaries may include information such as headers and other metadata which the system uses how to interpret the file when executed. Binaries without headers and metadata is called a flat binary.

Exploring hex dumps of the machine code of a software to understand the internals of it may be tedious, so this is where disassemblying comes to play. 

Disassembler is a program (hello, Radare) that translates the compiled machine code representation to assembly language. The output of the program aims for readability, making it eventually a reverse-engineering tool. While disassembler produces an assembly output of the original software, an interactive disassembler allows examination of the software that shows the changes made by the user. Software such as Radare in this case work greatly as a debugger as well, so it is also possible to interact and examine the software while running and debugging it.

### Opcodes

Opcode stands for operation code. It is a part of a machine language instruction that tells the operation to be performed. Opcodes also may include operands that act as the data to be processed by the operation.

```asm
PUSH ebp     ; <- Here, PUSH is an opcode and ebp is the operand
MOV ebp, esp ; <- Same rules apply

...

SUB ebp, 0x04h 

; and so forth
```

Opcodes are different depending across various processor architectures, and some architectures support different types of operands to these opcodes. Operands may be e.g. memory addresses and values in the stack. All opcodes together form the instruction set of the processor.

### Registers

In assembly language, we'll be talking about processor registeries. There are other types of memory registers as well when it comes to [hardware registers](https://en.wikipedia.org/wiki/Hardware_register) in general, but in CPU, processor registers are the real deal. 

The operations described earlier require processing data. This data is stored in memory. It can be volatile memory (RAM) or non-volatile memory (disk). The data is faster to handle in the processor itself instead of doing operations directly in the memory. Processors have **registeries** that act as a temporary and quickly available location for data to be processed.

Registeries vary between different architectures as well. In this blog post, focus will be on [x86 architecture](https://en.wikibooks.org/wiki/X86_Assembly/X86_Architecture) to take a brief look on some basics. Registers are classified according to the instructions that operate on them.

#### General-purpose registers

As the name implies, general-purpose registers (GPR) can hold data or a memory location in a form of an address. They can be used quite freely by the programmer with opcodes without too much limitations.

x86 architecture GPRs are:

* AX (Accumulator register).
* CX (Counter register).
* DX (Data Register).
* BX (Base register).
* SP (Stack Pointer register).
* BP (Stack Base Pointer register).
* SI (Source Index register).
* DI (Destination Index register).

These are all by default 16-bit registers. Registers are categorized to 8, 16, 32, and 64 -bit register based on their prefixes and suffixes:

* With E appended (E = extended), means a 32-bit register.
* With R appended, means a 64-bit register.
* Accumulator, counter, data, and base registers with either H or L suffix mean 8-bit register.
 * H-suffix means the most-significant byte, higher half of the 16 bits.
 * L-suffix means the least-significant byte, lower half of the 16 bits.

Let's take a look at a table to get a better look:

{{insert_pic_here}}

... hmm more descriptions ...

Whoa! This may be already quite a lot of stuff to take. Let's go through them all to understand what they are.

#### Segment registers

#### Flags

#### 64-bit conventions

### Heap & Stack

### Architectures

## 

# Radare?

Enter Radare! It is a cross-platform open source tool and framework for binary analysis that was discussed earlier. In this blog post, I'm talking mainly about Radare2 which is a rewritten project based on the original Radare project. Commonly it seems that people refer to it also just as Radare.

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

# Hello World revisited

## ??

# Basic password reverse engineering

# Conclusions