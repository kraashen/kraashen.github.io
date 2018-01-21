---
title: "Reverse Engineering With Radare from Software Engineering perspective - Fundamentals and Basics"
date: 2018-01-22
draft: true
---

Some time ago, I got more and more curious on how software works on low level. I felt it essential for software and system engineers to understand software internals so I thought more about diving into the topic of reverse engineering from software development perspective. I found lots of Radare tutorials on reverse engineering and finding examples such as hidden passwords and injection techniques, but not so many on just general how to analyse binaries and understand the software internals and more importantly: Why things work as they just do.

It's been almost 10 years from my computer architecture classes! I tried to dive into radare quite straightforwardly with some hands-on examples but I repeatedly hit walls when it came to things such as how memory management works, how assembly code is read, how registers are used (and what they even where), and so forth. I was successful though in reverse engineering a simple application in one password hunting exercise before I decided to go back to basics, yay!

So, couple of steps back, and back to some basic stuff on computer architectures. Hopefully it will help understanding low-level code and how to analyze it better. 

In this post, I'll go through some of the very basic things in computer architectures that I had to revise myself a bit. I hope will help you also understand assembly as well. Also, we'll take a look on how to disassemble a very simple binary using [Radare](https://www.radare.org/r/). The goal is to get familiar with understanding Assembly and how software internals work together with computer architecture fundamentals.

# Reverse Engineering

Wikipedia defines reverse engineering in general as:

> - - the processes of extracting knowledge or design information from a product and reproducing it or reproducing anything based on the extracted information.[1]:3 The process often involves disassembling something (a mechanical device, electronic component, computer program, or biological, chemical, or organic matter) and analyzing its components and workings in detail.

When it comes to software engineering, the meaning may vary. There are flexible taxonomies that attempt to define reverse engineering as simply rebuilding or understanding the system logic from the end to the beginning. 

However, there can be different types of systems to analyze: some of them can be black boxes when there is no source code availble, they can be obfuscated, and documented or not documented at all. Reverse engineering of software may also have different kind of goals: dissecting (aka. disassemblying) the software binary in raw machine language to understand how it works and what it does (which is what Radare does, for instance), analysing the information exchange of the software e.g. in network traffic when it comes to protocol reverse engineering, and decompiling the software, which is a technique to attempt to create a high-level representation of the original binary and it's contents.

In this post I will be focusing on reverse engineering software binary.

## Assembly, Assembling, and Disassembling

Assembly (ASM, aka. Assembler) language is a low-level programming language. It is very close to the machine code instructions of the hardware, and is dependent to the architectures it has been developed for. Assembly uses mnemonics - short textual and easily rememberable statements - that represent low-level machine instructions (code) which are referred to as opcodes, registers, and flags.  Assembly is converted to machine code using a so called assembler. There are multiple types of assemblers, which allow things such as cross-compilation of existing ASM code to other systems.

```asm
# some example 
```

There are different types of binary files. However, a file that is not a text file (binary) and that is treated as an executable (!) and ran by the system, is interpreted as a representation of a software in machine code. Binaries may include information such as headers and other metadata which the system uses how to interpret the file when executed. Binaries without headers and metadata is called a flat binary.

Exploring hex dumps of the machine code of a software to understand the internals of it may be tedious, so this is where disassemblying comes to play. 

Disassembler is a program (hello, Radare) that translates the compiled machine code representation to assembly language. The output of the program aims for readability, making it eventually a reverse-engineering tool. While disassembler produces an assembly output of the original software, an interactive disassembler allows examination of the software that shows the changes made by the user. Software such as Radare in this case work greatly as a debugger as well, so it is also possible to interact and examine the software while running and debugging it.

### Opcodes

Opcode stands for operation code. It is a part of a machine language instruction that tells the operation to be performed. Opcodes also may include operands that act as the data to be processed by the operation. They can be represented in a short textual form - mnemonic - that tell the programmer what operation is being performed in an easily memorable and understandable form.

```asm
PUSH ebp     ; <- Here, PUSH is an opcode and ebp is the operand
MOV ebp, esp ; <- Same rules apply

...

SUB ebp, 0x04h 

; and so forth
```

Opcodes are different depending across various processor architectures, and some architectures support different types of operands to these opcodes. Operands may be e.g. memory addresses and values in the stack. All opcodes together form the instruction set of the processor. To understand the opcodes supported by your architecture or the architecture of the software you are reverse engineering, you'll have to look for reference manuals of that specific architecture.

### Registers

In assembly language and reverse engineering, we'll be talking about processor registeries. There are other types of memory registers as well when it comes to [hardware registers](https://en.wikipedia.org/wiki/Hardware_register) in general, but in CPU, processor registers are the real deal. 

The operations described earlier process data. This data is stored in memory. It can be volatile memory (RAM) or non-volatile memory (disk). The data is faster to handle in the processor itself instead of doing operations directly in the memory. Processors have **registeries** that act as a temporary and quickly available location for data to be processed.

Registeries vary between different architectures as well. In this blog post, focus will be on [x86 architecture](https://en.wikibooks.org/wiki/X86_Assembly/X86_Architecture) to take a brief look on some basics. Registers are classified according to the instructions that operate on them.

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

Flags themselves are rarely visible from the assembly itself, but it is useful to understand how they work as the register values can be analysed while debugging.

### Heap & Stack

Still hanging along? Great! Before going into actual reverse engineering example, let's take a quick look at how heap and stack memory works in assembly. This is essential to help understanding what is happening in the assembly code and why. I won't dive into too much details so I recommend also checking out more detailed sources on memory management as well in the end of this post.

When a software is executed, memory is reverved in RAM for the application. Part of this memory is allocated for stack and the size of it is usually fixed. Part of the memory is reserved for heap.

How does the stack memory work? It is fairly simple on high-level. Stack size is fixed from the start of the application or thread. If there are multiple threads, they will have their own memory stack. When the stack is reserved, the stack pointer ```RSP``` (64-bit system) will point to the top of the stack. The stack grows downwards in size from the top to the bottom. If the pointer runs out of memory past the bottom, a [stack buffer overflow](https://en.wikipedia.org/wiki/Stack_buffer_overflow) will occur.

Stack works pretty much similarly like a [stack data type](https://en.wikipedia.org/wiki/Stack_(abstract_data_type)), where values are pushed on top of the stack and popped out in the reverse order they were inserted for use. Stack contains e.g.:

* Local variables of functions that will go out of scope after executing them
* Return address of the function, i.e. where will the processor continue after the function returns
* Function arguments before calling them
 * NOTE! There are also system and architecture conventions to use registers for function arguments instead of the stack

Following picture shows an example of a layout of a stack

[picture here]

How about heap? In contrast to stack, heap is more flexible and more unorganized. It is completely separate memory from the stack without a specific layout. A programmer can define variables that are out of scope of a function which are then placed on heap. Programmer will then have the responsibility of releasing this memory manually. In some languages, this is done by garbage collector when the variables are not used anymore. 

While stack memory is fixed, memory on the heap is allocated in run-time of an application. When a software runs out of heap memory, a [heap overflow](https://en.wikipedia.org/wiki/Heap_overflow) will occur, which can have destructive properties on the data that is processed. Without memory protection on the systems, even data outside the scope of the software could be affected.

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

# Conclusions and follow-up



# Sources to study

* [Wikipedia: Integer overflow](https://en.wikipedia.org/wiki/Integer_overflow)
* [Wikipedia: Computer architecture](https://en.wikipedia.org/wiki/Computer_architecture)
* [Studytonight: Architecture of computer system](https://www.studytonight.com/computer-architecture/architecture-of-computer-system.php)
* [Wikibooks: X86 Architecture](https://en.wikibooks.org/wiki/X86_Assembly/X86_Architecture#EFLAGS_Register)
* [X86 Opcode and Instruction Reference](http://ref.x86asm.net/)
* [Wikipedia: Memory management](https://en.wikipedia.org/wiki/Memory_management)