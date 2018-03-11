---
title: "Reverse Engineering With Radare - Binary internals"
date: 2018-03-11
draft: false
---

In the [previous post](./2018-01-22-reverse-engineering-basics-with-radare-fundamentals-and-basics), basics and fundamentals for reverse engineering software were discussed. This time I thought about writing a bit more about getting a bit further in inspecting and understanding software binaries. In this post, we'll take a look at one password guess reverse engineering challenge using Radare.

## Goals

The goal is to reverse engineer a simple binary and understanding of the flow of disassembled code, how to read it, and understand how it works. We'll take a look at concepts such as:

* The execution of a program: What happens when software is run?
* A brief look at what are symbols, sections, and segments
* Checking flags and strings in Radare
* Understanding program flow and disassembled code
* Visual graphs
* Extra: What are stack canaries on Linux?

## Setup

The C code of this exercise is [available on Gist](https://gist.github.com/anerani/4dc0d684d2f22939eb63bc76cf591e49). You can go and compile it yourself 
or you can download the provided binary first which I have included to this post. This exercise is actually based on one [Lab exercise I found from Github](https://github.com/s4n7h0/Practical-Reverse-Engineering-using-Radare2/). 
I decided to do a quick copy and a bit of rewriting of the Lab task as I wanted to avoid sploiling the 
original Lab exercise. So after reading, you can also check them out as well. :-) But for now, I'll focus on keeping the binary as black box'ish.

[Download the binary](/examples/exercise.bin)

## Information - ra2bin and iI output

As usual, let's check out some generic information about the binary we will be inspecting. Alternatively, you can run ```rabin2 -I [path_to_binary]``` on the command line to get similar information. **Rabin2** is a binary information extractor based on Radare. Within Radare, you can use ```iI``` command to get this information.

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

This time though, I'm going to attempt to explain further what the output of this command tells us about binaries. I'll try my best list them down based on sources I found.

|Term|Explanation|
|:--:|-----------|
|**arch**       |Architecture for which the binary has been assembled for.|
|**binsz**      | Size of the binary program in bits.|
|**bintype**    |Type of the binary, e.g. an ```elf``` binary is an executable Linux binary. See [Executable and Linkable Format Wiki page](https://en.wikipedia.org/wiki/Executable_and_Linkable_Format) for more details on linux binaries. Respectively on Windows, this could be Portable Executable (PE) and on OS X a Mach-O binary.|
|**bits**       |Bitness of the binary. Commonly 32/64 bit nowadays.|
|**canary**     |Does the binary have stack canary protection enabled.|
|**class**      |Class of the binary|
|**crypto**     | Boolean flag to tell if the binary is encrypted. This is a method in the binary protection. [This article from Phrack](https://grugq.github.io/docs/phrack-58-05.txt) is a great source to understand binary encryption and its background in more detail.|
|**endian**     |Endianness of the binary. See [this Wiki page](https://en.wikipedia.org/wiki/Endianness) for more details, this is useful to understand later on when endianness can be reversed on some binaries.|
|**havecode**   |Probably tells if the binary has debug symbols. I compiled the example binary with debug symbols enabled and disabled and this flag changed depending if debug symbols were enabled or not.|
|**intrp**      |Some sources say this as ```INTERP```, file name of the dynamic linker - the interpreter of the program.|
|**lang**       |Language which the binary was developed in.|
|**linenum**    |This indicates the availability of a [line number section](http://www.vxdev.com/docs/vx55man/diab5.0ppc/x-elf_fo.htm#3001084) that allows mapping from source line numbers to machine code addresses.|
|**lsyms**      |This indicates the availability of symbols list of a binary.|
|**machine**    |Machine and architecture the binary was compiled on.|
|**maxopsz**    |Maximum bit size of an operation the binary includes. (?)|
|**minopsz**    |Minimum bit size of an operation the binary includes. (?)|
|**nx**         |NX bit is related to executable space protection. This tells us if parts of the memory locations of the binary are marked as non-executable. Processor will then refuse to execute instructions in these memory locations.|
|**os**         |Operating system kernel for which the binary has been compiled for.|
|**pcalign**    |This is related to [data structure alignment](https://en.wikipedia.org/wiki/Data_structure_alignment). |
|**pic**        |Is the binary [position-independent code](https://en.wikipedia.org/wiki/Position-independent_code). This means that the machine-code can be placed anywhere in the memory and it would execute regardless of its absolute address. This is common e.g. for shared libraries.|
|**relocs**     |Possibly related to concept of [relocatable binary](https://en.wikipedia.org/wiki/Relocation_(computing)). Quite new concept for me. This is related to linking and loading, but how I understood this is that if the binary contains relocation section directives. A dynamically linked binary refers to functions that are located in shared library binaries for instance. Definitely needs further studying before I make too concrete much assumptions :P|
|**relro**      |Now continuing the previous topic, this might be related to relocation read-only property of a binary file. This way linker resolves dynamically linked functions at the beginning of execution.|
|**rpath**      |[Rpath](https://en.wikipedia.org/wiki/Rpath) can be a hard-coded value in binary headers that tell the path to find the required linked libraries, overriding or supplementing the system default paths.|
|**static**     |A binary can be static or a dynamically linked binary. This tells us which one the binary is.|
|**stripped**   |When a binary is stripped, it has the symbols table removed and results in a more compact binary. A non-stripped binary includes more information due to the included symbols table and possible also debug symbols as well.|
|**subsys**     |Subsystem to be invoked for this executable.|
|**va**         |Might be virtual address as a boolean? This could then mean that the binary includes or supports virtual addressing.|

This was a section that single-handedly took most of the time of this post - studying binary headers. I feel like I have not even barely scratched the surface of things to come. I don't understand in depth how linkers and compilers work to safely assume all of these are correct. So, if there is any feedback related to these, I'd gladly fix my understanding of these.

I also put this one available to Gist as a cheat sheet: https://gist.github.com/anerani/38fbb33edff32027ebabdda83a089769

## Symbols, sections, and segments

When you write software and compile it to a binary, the compiler assigns labels to parts of the code you have written. For instance, your functions are labeled. For instance, ```main``` is a label assigned to the binary representation of the code. These labels are called *symbols*. When these functions are called or being referenced to, they need to be looked up by the linker either by static linking (compile-time linking) or dynamic linking (while running the software). Symbols are needed for the linker to know where the code can be found.

With ```iS``` command you can print the sections of the binary. Try it out! There are a handful of sections in the binary but let's list down some of the useful ones to understand to begin with:

* **.interp**: The name of the linker.
* **.text**: Code of the software is in this segment.
* **.rodata**: Read-only data (e.g. initialized hard-coded variables)
* **.data**: Initialized data, including variables that have pre-defined values and that can be modified.
* **.bss**: Uninitialized data, including global and static variables that are initialized to zero or don't have explicit initialization.

The key difference between a section and a segment is, that a section is used at link-time of the program and a section is used at run-time.

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

The base pointer register is zeroed at the initialization. This is the point where the outermost frame of the application is marked. Performing a XOR operation with the same value sets the value to zero. If you don't know what is happening at this point, it might be better to read some boolean algebra before continuing forward!

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

This section will be strongly focused on Linux-spesific startup of a software. [This website](http://dbp-consulting.com/tutorials/debugging/linuxProgramStartup.html) by Patrick Horgan is a great source to study more about the beginning of software execution.

In this phase, data is first initialized to registers. Then, the value from the top of the stack, which is ```argc``` (argument count), is popped to ```rsi``` register. Binaries also have argument values. As the argument count was popped from the stop of the stack, the stack pointer is pointing to ```argv``` (argument vector). The address of these is moved to ```rdx``` data register and ```rsp``` is not moved. Remember how stack works? If you need to fresh your memory, check the [previous post](./2018-01-22-reverse-engineering-basics-with-radare-fundamentals-and-basics)!

Next, the stack pointer is masked with a long mask, clearing the lowest 4 bits. This is done to align the stack pointer for memory and cache efficiency, and certain operations.

Then, couple of pushes. The values from the ```rax``` is pushed to the stack along with the stack pointer ```rsp``` to store the return address after the main function is executed.

```__libc_csu_fini``` is the destructor of the application. ```__libc_csu_init``` is the constructor of our application. These are C-level constructor and destructor, to be exact. These are methods that are executed both before and after the our application finishes after the ```__libc_start_main``` which will come next.  

```
|           0x0040056d      48c7c7510640.  mov rdi, sym.main           ; 0x400651
\           0x00400574      e897ffffff     call sym.imp.__libc_start_main ; int __libc_start_main(func main, int argc, char **ubp_av, func init, func fini, func rtld_fini, void *stack_end)
```

Here, the address of the main function is moved to ```rdi```. Based on this, the ```__libc_start_main``` will load the arguments for it - destructor, constructor, aligned stack pointer, and main function - from the registers. Like it was explained before, it depends e.g. on the architecture if function arguments are passed using the stack or the registers.

Finally, the ```__libc_start_main``` is called and our main function will be executed. This low-level C function handles things such as:

* Registering constructor and destructor for the application
* Calls the ```main()``` with the corresponding arguments
* Calls exit when the main function returns

What next? Lets check out how we can navigate further in the disassembled codespace.

## Navigating around

### Flags and info in Radare

The previously presented entrypoint is rather common for ELF binaries. Next steps would be to analyze a bit what our binary has eaten. There are various commands where to start from, and here we'll go through only couple of them.

* ```ih```: Print info about file headers
* ```is```: List symbols of the binary.
* ```il```: List libraries used by the binary.
* ```ii```: List imports of the binary.

Go ahead: Try them out, and check out ```i?``` in your terminal as well!

Now, after the analysis of the binary, Radare associates names to offsets in the binary. These can be sections, functions, symbols, etc. and are referred to as "flags".

You can list the so called flag space with ```fs```

```
> fs
0    4 * strings
1   34 * symbols
2   82 * sections
3    6 * relocs
4    6 * imports
```

In Radare, semi-colon ```;``` can be used to combine multiple commands to same line. Now we can pick a flag space and use plain ```f``` to list the flag in that specified flag space:

```
> fs imports; f
0x004004f0 16 sym.imp.puts
0x00400500 16 sym.imp.__stack_chk_fail
0x00400510 16 sym.imp.__libc_start_main
0x00400520 16 sym.imp.strcmp
0x00400000 16 loc.imp.__gmon_start
0x00400530 16 sym.imp.__isoc99_scanf
```

Now, one cool command also I learned from [Megabeets blog](https://www.megabeets.net/a-journey-into-radare-2-part-1/) was ```axt```:

> | axt [addr]      find data/code references to this address

Radare also has a ```@``` syntax to refer to a variable, and ```@@``` allows to iterate through the variables given by the second command. These can now be combined to tell us where these imports are being used:

```
> > axt @@ sym
sym.main 0x40066d [call] call sym.imp.puts
sym.main 0x4006d3 [call] call sym.imp.puts
sym.main 0x4006b2 [call] call sym.imp.puts
sym.main 0x4006da [call] call sym.imp.__stack_chk_fail
entry0 0x400574 [call] call sym.imp.__libc_start_main
sym.main 0x40069f [call] call sym.imp.strcmp
sym.main 0x400683 [call] call sym.imp.__isoc99_scanf
```

Here we can see that the main function is handling pretty much all that have been imported to the application.

### Visual Graphs

Radare has a visual mode ```VV``` and ```V```, which are user-friendlier ways of exploring the binary data. It uses ```HJKL``` keys for navigation in the data and code. If you have used Vim, you'll be comfortable with the key bindings. You can always exit back to command line using ```q``` key. To navigate between different visual views, use ```p/P``` keys to go to the next/previous view. In one view, you can also have an ASCII flowchart of the binary logic showing also conditional branching logic between different sections of the code.

![](/img/Vflow1.PNG)
![](/img/Vflow2.PNG)
![](/img/VVflow1.PNG)

## Disassembled main function

Time to dive into the main function! Lets seek to it and print its disassembled form.

```asm
> s main
...
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

Lets break it down to steps:

```asm
            ;-- main:
/ (fcn) sym.main 144
|   sym.main ();
|           ; var int local_24h @ rbp-0x24
|           ; var int local_20h @ rbp-0x20
|           ; var int local_8h @ rbp-0x8
|              ; DATA XREF from 0x0040056d (entry0)
```

This comment section in the beginning of the disassembled main function tells us that the function has three local variables that are in the scope of the function, indicated by the ```local_``` prefix. They are located in the offset of ```rbp-0x[hexvalue]```. Also the ```DATA XREF``` tell that the function was cross referenced from the given address. 

```
> pdf @ 0x0040056d
``` 

which outputs the entrypoint function we analyzed earlier. You can read more about cross references from [here](http://resources.infosecinstitute.com/ida-cross-references-xrefs/). With **a**nalyze **f**unction **v**ariable **d**isplay command, we could check out the values of the local variables e.g. when debugging the application and setting breakpoints during the process.

```asm
> afvd
var local_8h = 0xfffffffffffffff8  0xffffffffffffffff   ........
var local_20h = 0xffffffffffffffe0  0xffffffffffffffff   ........
var local_24h = 0xffffffffffffffdc  0xffffffffffffffff   ........
```

Alright, onwards.

```asm
|           0x00400651      55             push rbp
|           0x00400652      4889e5         mov rbp, rsp
|           0x00400655      4883ec30       sub rsp, 0x30               ; '0'
|           0x00400659      64488b042528.  mov rax, qword fs:[0x28]    ; [0x28:8]=-1 ; '(' ; 40
|           0x00400662      488945f8       mov qword [local_8h], rax
|           0x00400666      31c0           xor eax, eax
```

Base pointer is pushed to the stack to store the point where to resume the execution from and previous stack pointer value is put into to the base pointer register. Then, stack pointer is moved to reserve space for the upcoming variables (remember, stack "grows" downwards in the address space - hence the reduction). This is common way of function "prologues" in assembly.

Also it seems that a value from ```fs``` offset ```0x28``` is moved to ```rax```. ```qword``` means that this operand has a size of a quad-word (word is 2 bytes = 8 bytes long). Then, the value at ```rax``` is loaded to local variable. What do the brackets mean? Effectively with ```mov``` opcodes, brackets mean that "dereference the value at the given address". Finally, the ```eax``` register is zeroed.

```asm
|       .-> 0x00400668      bf83074000     mov edi, str.Enter_password: ; 0x400783 ; "Enter password: "
|       :   0x0040066d      e87efeffff     call sym.imp.puts           ; int puts(const char *s)
|       :   0x00400672      488d45e0       lea rax, [local_20h]
|       :   0x00400676      4889c6         mov rsi, rax
|       :   0x00400679      bf94074000     mov edi, 0x400794
|       :   0x0040067e      b800000000     mov eax, 0
|       :   0x00400683      e8a8feffff     call sym.imp.__isoc99_scanf
|       :   0x00400688      b800000000     mov eax, 0
|       :   0x0040068d      e8b4ffffff     call sym.get_secret
```

The string "Enter password: " is moved to ```edi``` and an imported function puts is called, which outputs the string to the ```stdout```. Then, the computed address of a local variable is set in ```rax```. ```lea```, **l**oad **e**ffective **a**ddress works pretty much similarly as ```mov``` but instead of loading or moving the value, the calculated effective address is moved to the target register instead, which can be dereferenced or moved later.

At the end, ```scanf``` is called for user input. After that, ```get_secret``` is called, which seems to be interesting based on its name. 


```asm
|       :   0x00400692      4889c2         mov rdx, rax
|       :   0x00400695      488d45e0       lea rax, [local_20h]
|       :   0x00400699      4889d6         mov rsi, rdx
|       :   0x0040069c      4889c7         mov rdi, rax
|       :   0x0040069f      e87cfeffff     call sym.imp.strcmp         ; int strcmp(const char *s1, const char *s2)
|       :   0x004006a4      8945dc         mov dword [local_24h], eax
|       :   0x004006a7      837ddc00       cmp dword [local_24h], 0
|      ,==< 0x004006ab      7521           jne 0x4006ce
```

Based on the four following instructions before ```strcmp``` call, seems like the value of the function ```get_secret``` is stored in ```rax``` and is moved to ```rdx```. The value of the user input on the other hand is stored in the local variable and its effective address is loaded to ```rax```. Then, the values to be compared are loaded to ```rsi``` and ```rdi``` respectively and ```strcmp``` is called to compare them. Result of this function call is stored in ```eax``` and then it is compared. Values of these comparisons are stored in flag registers that were discussed in the previous post. If the comparison failed, jne jumps to the specified memory address and following sequence is executed:

```
|    ||`--> 0x004006ce      bfa0074000     mov edi, str.Wrong          ; 0x4007a0 ; "Wrong!"
|    || :   0x004006d3      e818feffff     call sym.imp.puts           ; int puts(const char *s)
|    || `=< 0x004006d8      eb8e           jmp 0x400668
```

So a string "Wrong!" is printed to stdout and execution flow jumps to the given address, which is in the beginning of the main function.

```asm
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

Rest of the code should be now quite understandable based on some of the basic principles we learned on our way here. The left side arrows indicate the flow within the main function and ```je``` and ```jmp``` opcodes are defining the execution flow. When the user gives the correct string, the function leaves the loop and returns, effectively ending our main loop.

## Finding the secret

Now we have seen the main function and know how to navigate around a bit. There are multiple ways of doing this of course, but for practice lets check out what the ```get_secret()``` function does as it sounds interesting.

```asm
> s sym.get_secret
[0x00400646]> pdf
/ (fcn) sym.get_secret 11
|   sym.get_secret ();
|              ; CALL XREF from 0x0040068d (sym.main)
|           0x00400646      55             push rbp
|           0x00400647      4889e5         mov rbp, rsp
|           0x0040064a      b874074000     mov eax, str.s3cr37p455w0rd ; 0x400774 ; "s3cr37p455w0rd"
|           0x0040064f      5d             pop rbp
\           0x00400650      c3             ret
```

Seems like this function is quite simple: Base pointer is pushed to the stack to store the return address where the execution of the program will continue, stack pointer is moved to point to the current frame and a quite distinguishing string variable is moved to the ```eax``` register. Finally the base pointer is popped back from the stack and function returns, resuming the execution of our application.

Lets try this password out:

```
$ ./a.out
Enter password:
s3cr37p455w0rd
Correct!
```

## Alternative ways: File info revisited

I intentionally skipped one useful info command: ```iz```. This prints information about the strings located in the binary itself. This though reveals also the answer to our top-secret exercise. Whoops! Why? Well, it's stored hard-coded as a variable within the binary itself.

```
> iz
000 0x00000774 0x00400774  14  15 (.rodata) ascii s3cr37p455w0rd
001 0x00000783 0x00400783  16  17 (.rodata) ascii Enter password:
002 0x00000797 0x00400797   8   9 (.rodata) ascii Correct!
003 0x000007a0 0x004007a0   6   7 (.rodata) ascii Wrong!
```

Still, this can be a very useful command to remember as well when debugging or reversing software. Also if you explored the flag more earlier, you might have done:

```
> fs strings; f
0x00400774 15 str.s3cr37p455w0rd
0x00400783 17 str.Enter_password:
0x00400797 9 str.Correct
0x004007a0 7 str.Wrong
```

## Extra: Stack canaries?

In the original lab exercise, one thing caught my eye: it was compiled with stack protection enabled, which is used by e.g. as a gcc flag ```-fstack-protect-all```. This resulted in an interesting program initialization assembly:

```asm
|    `----> 0x004006da      e821feffff     call sym.imp.__stack_chk_fail ; void __stack_chk_fail(void)
```

What are stack canaries? [This blog post](https://xorl.wordpress.com/2010/10/14/linux-glibc-stack-canary-values/) was an excellent wrap-up of the topic. In short, a stack canary is a feature in binaries to protect from malicious buffer overflows on variables that have been allocated in stack.

## Conclusions

Well, there it is! Understanding of basics of computer architectures, memory handling in assembly were visited, and how to navigate and use basic functionalities of Radare. Time to dive into reverse engineering on real-world software binaries or write some own to practice with!

One options would be to look with a search engine for capture-the-flag exercises and challenges, as well as excellent Radare tutorials out there. CTF challenges are good way to start prepping puzzle skills hand-in-hand with binary analysis and can really twist your brains.

## References

* [Github Project - Practical Reverse Engineering using Radare2](https://github.com/s4n7h0/Practical-Reverse-Engineering-using-Radare2/)
* [Phrack: Armouring the ELF: Binary encryption on the UNIX platform](https://grugq.github.io/docs/phrack-58-05.txt)
* [Executable and Linking Format (ELF)](http://www.vxdev.com/docs/vx55man/diab5.0ppc/x-elf_fo.htm#3001084)
* [Wikipedia: Data structure alignment](https://en.wikipedia.org/wiki/Data_structure_alignment)
* [Wikipedia: Position-independent code](https://en.wikipedia.org/wiki/Position-independent_code)
* [Wikipedia: Relocatable binary](https://en.wikipedia.org/wiki/Relocation_(computing))
* [Wikipedia: Rpath](https://en.wikipedia.org/wiki/Rpath)
* [Wikipedia: Endianness](https://en.wikipedia.org/wiki/Endianness)
* [Wikipedia: Executable and Linkable Format](https://en.wikipedia.org/wiki/Executable_and_Linkable_Format)
* [Patric Horgan: Linux x86 Program Start Up or - How the heck do we get to main()?](http://dbp-consulting.com/tutorials/debugging/linuxProgramStartup.html)
* [Megabeets: A Journey Into Radare2 Part 1](https://www.megabeets.net/a-journey-into-radare-2-part-1/)
* [xorl %eax, %eax: Linux Glibc - Stack Canary Values](https://xorl.wordpress.com/2010/10/14/linux-glibc-stack-canary-values/)