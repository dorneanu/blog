+++
title = "ringzer0 CTF - Binaries - Heap Allocator"
author = "Victor Dorneanu"
date = "2016-11-30"
tags = ["ringzer0", "ctf", "wargames", "asm", "x86", "sploitfun"]
category = "blog"
+++

First let's collect some information about the binary itself:

```.shell
$ readelf IntelligenSoftware -h
ELF Header:
  Magic:   7f 45 4c 46 02 01 01 00 00 00 00 00 00 00 00 00
  Class:                             ELF64
  Data:                              2's complement, little endian
  Version:                           1 (current)
  OS/ABI:                            UNIX - System V
  ABI Version:                       0
  Type:                              EXEC (Executable file)
  Machine:                           Advanced Micro Devices X86-64
  Version:                           0x1
  Entry point address:               0x400688
  Start of program headers:          64 (bytes into file)
  Start of section headers:          4608 (bytes into file)
  Flags:                             0x0
  Size of this header:               64 (bytes)
  Size of program headers:           56 (bytes)
  Number of program headers:         9
  Size of section headers:           64 (bytes)
  Number of section headers:         30
  Section header string table index: 27

```

Let's see some code:

```.assembler
$ objdump -d IntelligentSoftware -j .text 
...
0000000000400660 <main>:
  400660:       48 83 ec 08             sub    $0x8,%rsp
  400664:       ba a0 10 60 00          mov    $0x6010a0,%edx
  400669:       be 87 08 40 00          mov    $0x400887,%esi
  40066e:       bf 01 00 00 00          mov    $0x1,%edi
  400673:       31 c0                   xor    %eax,%eax
  400675:       e8 26 ff ff ff          callq  4005a0 <__printf_chk@plt>
  40067a:       31 c0                   xor    %eax,%eax
  40067c:       e8 ff 00 00 00          callq  400780 <get_flag>
  400681:       31 c0                   xor    %eax,%eax
  400683:       48 83 c4 08             add    $0x8,%rsp
  400687:       c3                      retq
```

Nothing interesting here. But there is a `call` to `get_flag`:

```.assembler
0000000000400780 <get_flag>:
  400780:       53                      push   %rbx
  400781:       bf 00 04 00 00          mov    $0x400,%edi
  400786:       e8 05 fe ff ff          callq  400590 <malloc@plt>
  40078b:       be 54 08 40 00          mov    $0x400854,%esi
  400790:       48 89 c3                mov    %rax,%rbx
  400793:       48 89 c2                mov    %rax,%rdx
  400651:       eb d0                   jmp    400623 <__libc_csu_ctor+0x73>
  400653:       66 a5                   movsw  %ds:(%rsi),%es:(%rdi)
  400655:       83 e8 02                sub    $0x2,%eax
  400658:       eb cf                   jmp    400629 <__libc_csu_ctor+0x79>
  40065a:       e8 01 ff ff ff          callq  400560 <__stack_chk_fail@plt>
  40065f:       90                      nop
```

And there is some `jmp` to a **libc constructor** (`__libc_csu_ctor').

### Libc constructors / destructors

If you don't have a clue what **libc** constructors/destructors are, make sure
you have a look at:

* [Linux x86 Program Start Up](http://dbp-consulting.com/tutorials/debugging/linuxProgramStartup.html)
* [Starting a process](http://bottomupcs.sourceforge.net/csbu/x3564.htm)
* [How statically linked programs run on Linux](http://eli.thegreenplace.net/2012/08/13/how-statically-linked-programs-run-on-linux) 
* [C Run-time for ELF Executables](http://nairobi-embedded.org/070_elf_c_runtime.html)

### Dynamic analysis

Again using `radare` I'll disassemble `get_flag`:

```.assembler
[0x00400688]> pdf @ sym.get_flag
/ (fcn) sym.get_flag 73
|   sym.get_flag ();
|       |   ; CALL XREF from 0x0040067c (sym.main)
|       |   0x00400780      53             push rbx
|       |   0x00400781      bf00040000     mov edi, 0x400
|       |   0x00400786      e805feffff     call sym.imp.malloc        ;  void *malloc(size_t size);
|       |   0x0040078b      be54084000     mov esi, str.Allocating_1024_bytes__p..._n ; "Allocating 1024 bytes %p...." @ 0x400854
|       |   0x00400790      4889c3         mov rbx, rax
|       |   0x00400793      4889c2         mov rdx, rax
|       |   0x00400796      bf01000000     mov edi, 1
|       |   0x0040079b      31c0           xor eax, eax
|       |   0x0040079d      e8fefdffff     call sym.imp.__printf_chk
|       |   0x004007a2      4889df         mov rdi, rbx
|       |   0x004007a5      e896fdffff     call sym.imp.free          ; void free(void *ptr);
|       |   0x004007aa      4889da         mov rdx, rbx
|       |   0x004007ad      bf01000000     mov edi, 1
|       |   0x004007b2      be71084000     mov esi, str.Freeing_buffer__p..._n ; "Freeing buffer %p...." @ 0x400871
|       |   0x004007b7      31c0           xor eax, eax
|       |   0x004007b9      e8e2fdffff     call sym.imp.__printf_chk
|       |   0x004007be      5b             pop rbx
|       |   0x004007bf      bf90084000     mov edi, str.Heap_is_working_perfectly__No_Flag_then ; "Heap is working perfectly! No Flag then" @ 0x400890
\       `=< 0x004007c4      e987fdffff     jmp sym.imp.puts
```

Nothing suspicious about it: `malloc` is being called and then `free`. Now let's have a look at the constructors, which are usually
called before `main`:

```.assembler
[0x00400688]> pdf @ entry0
            ;-- _start:
/ (fcn) entry0 41
|   entry0 ();
|           ; UNKNOWN XREF from 0x00400018 (unk)
|           0x00400688      31ed           xor ebp, ebp
|           0x0040068a      4989d1         mov r9, rdx
|           0x0040068d      5e             pop rsi
|           0x0040068e      4889e2         mov rdx, rsp
|           0x00400691      4883e4f0       and rsp, 0xfffffffffffffff0
|           0x00400695      50             push rax
|           0x00400696      54             push rsp
|           0x00400697      49c7c0400840.  mov r8, sym.__libc_csu_fini ; sym.__libc_csu_fini
|           0x0040069e      48c7c1d00740.  mov rcx, sym.__libc_csu_init ; "AWA..AVI..AUI..ATL.% . " @ 0x4007d0
|           0x004006a5      48c7c7600640.  mov rdi, sym.main           ; "H......`" @ 0x400660
\           0x004006ac      e8bffeffff     call sym.imp.__libc_start_main; int __libc_start_main(func main, int argc, char **ubp_av, func init, func fini, func rtld_fini, void *stack_end);
```

Ahh, there we go. From the links mentioned before we know that `__libc_start_main` has following syntax:

```.c
int __libc_start_main( 
	int (*main) (int, char * *, char * *), 
	int argc, 
	char * * ubp_av, 
	void (*init) (void), 
	void (*fini) (void), 
	void (*rtld_fini) (void), 
	void (* stack_end)
);
```

So before calling `main` its arguments are copied to the corresponding registers. Since we're dealing with `x86-64`
the **ABI** requires that registers are used instead of the stack. On Linux we have the [System V AMD64 ABI](https://en.wikipedia.org/wiki/X86_calling_conventions#System_V_AMD64_ABI) calling convention which uses following registers for the parameters:

* RDI
* RSI
* RDX
* RCX
* R8
* R9 

Additional arguments can be passed on the stack. In our case we have:

{{gravizo background-color="#fff" title="Deployment scheme" alt="Deployment scheme" }}
    digraph G {
        // Define layout
        graph [pad=".75", ranksep="0.95", nodesep="0.05"];
        rankdir=LR;
        node [shape="record"];
        rank=same;
     
        // Define pointers
        rsp [
            label="<p> $rdi \l", height="0.1",
            color=white, fontcolor=black,fontsize=9,style=filled, fillcolor=white
        ];
        
        // rbp [
        // 	label="<p> $rbp \l", height="0.1",
        // 	color=white, fontcolor=black,fontsize=9,style=filled, fillcolor=white
        // ];
     
        rsp_4 [
            label="<p> $rsi \l", height="0.01",
            color=white, fontcolor=black,fontsize=9,style=filled, fillcolor=white
        ];
     
     
        rsp_8 [
            label="<p> $rdx \l", height="0.01",
            color=white, fontcolor=black,fontsize=9,style=filled, fillcolor=white,
        ];
     
        rsp_12 [
            label="<p> $rcx \l", height="0.01",
            color=white, fontcolor=black,fontsize=9,style=filled, fillcolor=white,
        ];
        
        rsp_16 [
            label="<p> $r8 \l", height="0.01",
            color=white, fontcolor=black,fontsize=9,style=filled, fillcolor=white,
        ];
        
        rsp_20 [
            label="<p> $r9 \l", height="0.01",
            color=white, fontcolor=black,fontsize=9,style=filled, fillcolor=white,
        ];
     
        // Define stack
        stack [
            width="3",
            label="<p>\nArguments\n\n | <bp>\n...\n\n | <20>0x7ffff7de9900 (_dl_fini) \l| <16>0x00400840 (sym.__libc_csu_fini) \l| <12>0x4007d0 (sym.__libc_csu_init)  \l | <8>(char **ubp_av = $rsp) \l | <4>(int argc = pop)  \l | <0>0x400660 (sym.main) \l"
        ];
       
       
        // Pointer -> Stack edges
        //rbp:p -> stack:bp [style=invis];
        rsp:p -> stack:0 [style=invis];
        rsp_4:p -> stack:4 [style=invis];
        rsp_8:p -> stack:8 [style=invis];
        rsp_12:p -> stack:12 [style=invis];
        rsp_16:p -> stack:16 [style=invis];
        rsp_20:p -> stack:20 [style=invis];
    }
{{/gravizo}}

As stated [here](http://dbp-consulting.com/tutorials/debugging/linuxProgramStartup.html) `__libc_start_main` does
the following:


* Takes care of some security problems with setuid setgid programs
* Starts up threading
* Registers the fini (our program), and rtld_fini (run-time loader) arguments to get run by at_exit to run the program's and the loader's cleanup routines
* Calls the init argument
* Calls the main with the argc and argv arguments passed to it and with the global __environ argument as detailed above.
* Calls exit with the return value of main

The `init` argument is set to `__libc_csu_init`. In the **glibc** source tree you will find `csu/elf-init.c` which contains `__libc_csu_init`:

```.c
void __libc_csu_init (int argc, char **argv, char **envp) {
	 _init (); 
	
	const size_t size = __init_array_end - __init_array_start; 
	for (size_t i = 0; i < size; i++) 
		(*__init_array_start [i]) (argc, argv, envp); 
}
```

Let's have a look at the disassembly:

```.assembler
[0x00400688]> pdf @ sym.__libc_csu_init
/ (fcn) sym.__libc_csu_init 101
|   sym.__libc_csu_init ();
|           ; DATA XREF from 0x0040069e (entry0)
|           ; DATA XREF from 0x004005c4 (sym.__libc_csu_ctor)
|           ; DATA XREF from 0x004005c9 (sym.__libc_csu_ctor)
|           0x004007d0      4157           push r15
|           0x004007d2      4189ff         mov r15d, edi
|           ; DATA XREF from 0x004005d2 (sym.__libc_csu_ctor)
|           0x004007d5      4156           push r14
|           0x004007d7      4989f6         mov r14, rsi
|           0x004007da      4155           push r13
|           0x004007dc      4989d5         mov r13, rdx
|           0x004007df      4154           push r12
|           0x004007e1      4c8d25200620.  lea r12, qword obj.__frame_dummy_init_array_entry ; 0x600e08 ; loc.__init_array_start ; "P.@" @ 0x600e08
|           0x004007e8      55             push rbp
|           0x004007e9      488d2d280620.  lea rbp, qword obj.__do_global_dtors_aux_fini_array_entry ; 0x600e18 ; loc.__init_array_end ; "0.@" @ 0x600e18
|           0x004007f0      53             push rbx
|           0x004007f1      4c29e5         sub rbp, r12
|           0x004007f4      31db           xor ebx, ebx
|           0x004007f6      48c1fd03       sar rbp, 3
|           0x004007fa      4883ec08       sub rsp, 8
|           0x004007fe      e805fdffff     call sym._init
|           0x00400803      4885ed         test rbp, rbp
|       ,=< 0x00400806      741e           je 0x400826
|       |   0x00400808      0f1f84000000.  nop dword [rax + rax]
|      .--> 0x00400810      4c89ea         mov rdx, r13
|      ||   0x00400813      4c89f6         mov rsi, r14
|      ||   0x00400816      4489ff         mov edi, r15d
|      ||   0x00400819      41ff14dc       call qword [r12 + rbx*8]
|      ||   0x0040081d      4883c301       add rbx, 1
|      ||   0x00400821      4839eb         cmp rbx, rbp
|      `==< 0x00400824      75ea           jne 0x400810
|       `-> 0x00400826      4883c408       add rsp, 8
|           0x0040082a      5b             pop rbx
|           0x0040082b      5d             pop rbp
|           0x0040082c      415c           pop r12
|           0x0040082e      415d           pop r13
|           0x00400830      415e           pop r14
|           0x00400832      415f           pop r15
\           0x00400834      c3             ret
```

You can definitely see the call to `_init()`. The loop inside looks very interesting:

```.assembler
|       |   0x08048592      8db600000000   lea esi, [esi]
|      .--> 0x08048598      8b442438       mov eax, dword [esp + arg_38h] ; [0x38:4]=52 ; '8'
|      ||   0x0804859c      892c24         mov dword [esp], ebp
|      ||   0x0804859f      89442408       mov dword [esp + local_8h], eax
|      ||   0x080485a3      8b442434       mov eax, dword [esp + arg_34h] ; [0x34:4]=6 ; '4'
|      ||   0x080485a7      89442404       mov dword [esp + local_4h], eax
|      ||   0x080485ab      ff94b308ffff.  call dword [ebx + esi*4 - 0xf8]
|      ||   0x080485b2      83c601         add esi, 1
|      ||   0x080485b5      39fe           cmp esi, edi
|      `==< 0x080485b7      75df           jne 0x8048598
```

Let's have a look what's happening inside this loop:

```.shell
gef> b *0x0000000000400803
gef> r
gef> 
0x0000000000400819    <__libc_csu_init+73>     call   QWORD PTR [r12+rbx*8]   <- $pc

gef> x/x $r12
0x600e08:       0x00400750
gef> x/x $rbx
0x0:    Cannot access memory at address 0x0
```

As you can see the address at `$r12 + rbx*8` will be called. Since `$rbx` is null the programm
execution will jump to the address `0x00400750`. But where does this address come from?

### Constructors

As you have seen previously an `init_array` is used to call some functions. In C you'd usually 
implement some constructors using `__attribute__`:

```.c
void init(int argc, char **argv, char **envp) { 
	printf("INIT!"); 
}
__attribute__((section(".init_array"))) typeof(init) *__init = init;
``` 

This whole information is stored inside the ELF binary at a section called `init_array`. Let's
see what it contains:

```.shell
$ objdump -d -j .init_array IntelligentSoftware

IntelligentSoftware:     file format elf64-x86-64


Disassembly of section .init_array:

0000000000600e08 <__frame_dummy_init_array_entry>:
  600e08:       50 07 40 00 00 00 00 00 b0 05 40 00 00 00 00 00     P.@.......@.....
```

Did you recognize the address `0x600e08` and the value `0x00400750`? Let's go back to `radare`:

```.assembler
[0x00400688]> pxr @ obj.__frame_dummy_init_array_entry
0x00600e08  0x0000000000400750   P.@..... (.text) sym.frame_dummy sym.frame_dummy R X 'cmp qword [rip + 0x2006c8], 0'
0x00600e10  0x00000000004005b0   ..@..... (.text) sym.__libc_csu_ctor sym.__libc_csu_ctor R X 'sub rsp, 0x48'
0x00600e18  0x0000000000400730   0.@..... (.text) sym.__do_global_dtors_aux sym.__do_global_dtors_aux R X 'cmp byte [rip + 0x200998], 0'
0x00600e20  0x0000000000000000   ........ section_end.GNU_STACK
...
```

Let's have a look at the **2nd**  constructor/entry:

```.assembler
/ (fcn) sym.__libc_csu_ctor 216
|   sym.__libc_csu_ctor ();
|           ; var int local_8h @ rsp+0x8
|           ; var int local_10h @ rsp+0x10
|           ; var int local_11h @ rsp+0x11
|           ; var int local_12h @ rsp+0x12
|           ; var int local_14h @ rsp+0x14
|           ; var int local_18h @ rsp+0x18
|           ; var int local_38h @ rsp+0x38
|           ; UNKNOWN XREF from 0x00400e10 (unk)
|           ; CALL XREF from 0x004005b0 (sym.__libc_csu_ctor)
|           0x004005b0      4883ec48       sub rsp, 0x48               ; 'H' ; [13] va=0x004005b0 pa=0x000005b0 sz=658 vsz=658 rwx=--r-x .text
|           0x004005b4      64488b042528.  mov rax, qword fs:[0x28]    ; [0x28:8]=0x1200 ; '('
|           0x004005bd      4889442438     mov qword [rsp + local_38h], rax
|           0x004005c2      31c0           xor eax, eax
|           0x004005c4      b8d0074000     mov eax, sym.__libc_csu_init ; "AWA..AVI..AUI..ATL.% . " @ 0x4007d0
|           0x004005c9      48c7442408d0.  mov qword [rsp + local_8h], sym.__libc_csu_init ; [0x4007d0:8]=0x495641ff89415741 LEA sym.__libc_csu_init ; "AWA..AVI..AUI..ATL.% . " @ 0x4007d0
|           0x004005d2      678b4005       mov eax, dword [eax + 5]    ; [0x5:4]=257
|           0x004005d6      3ccc           cmp al, 0xcc
|       ,=< 0x004005d8      7415           je 0x4005ef
|       |   ; JMP XREF from 0x0040064c (sym.__libc_csu_ctor)
|       |   0x004005da      488b442438     mov rax, qword [rsp + local_38h] ; [0x38:8]=0x1b001e00400009 ; '8'
|       |   0x004005df      644833042528.  xor rax, qword fs:[0x28]
|      ,==< 0x004005e8      7570           jne 0x40065a
|      ||   0x004005ea      4883c448       add rsp, 0x48               ; 'H'
|      ||   0x004005ee      c3             ret
|      |`-> 0x004005ef      488b3d8a0a20.  mov rdi, qword [obj.__libc_ptr] ; [0x601080:8]=0x6010a0 obj.banner LEA obj.__libc_ptr ; obj.__libc_ptr
|      |    0x004005f6      c644241046     mov byte [rsp + local_10h], 0x46 ; 'F' ; [0x46:1]=0 ; 'F'
|      |    0x004005fb      488d742410     lea rsi, qword [rsp + local_10h] ; 0x10
|      |    0x00400600      c64424114c     mov byte [rsp + local_11h], 0x4c ; 'L' ; [0x4c:1]=0 ; 'L'
|      |    0x00400605      66c744241833.  mov word [rsp + local_18h], 0x3933 ; [0x3933:2]=0xffff
|      |    0x0040060c      b828000000     mov eax, 0x28               ; '('
|      |    0x00400611      66c744241241.  mov word [rsp + local_12h], 0x4741 ; [0x4741:2]=0xffff
|      |    0x00400618      c64424142d     mov byte [rsp + local_14h], 0x2d ; '-' ; [0x2d:1]=0 ; '-'
|      |    0x0040061d      40f6c701       test dil, 1
|      |,=< 0x00400621      752b           jne 0x40064e
|      ||   ; JMP XREF from 0x00400651 (sym.__libc_csu_ctor)
|      ||   0x00400623      40f6c702       test dil, 2
|     ,===< 0x00400627      752a           jne 0x400653
|     |||   ; JMP XREF from 0x00400658 (sym.__libc_csu_ctor)
|     |||   0x00400629      89c1           mov ecx, eax
|     |||   0x0040062b      31d2           xor edx, edx
|     |||   0x0040062d      c1e902         shr ecx, 2
|     |||   0x00400630      a802           test al, 2

```

Do you see how the string `FLAG-` is being concatenated? Let's `seek` to that address and let `radare` give us some 
graphics:

```.assembler
[0x00400688]> s 0x00000000004005b
[0x004005b0]> VV

                                                         =---------------------------------=
                                                         | [0x4005b0]                      |
                                                         | 0x004005c4 sym.__libc_csu_init  |
                                                         | 0x004005c9 sym.__libc_csu_init  |
                                                         =---------------------------------=
                                                               t f
                                                             .-' '-----------------.
                                                             |                     |
                                                             |                     |
                                                       =--------------------=      |
                                                       |  0x4005ef          |      |
                                                       =--------------------=      |
                                                             t f                   |
                                                       .-----' '-------------.     |
                                                       |                     |     |
                                                       |                     |     |
                                                 =--------------------=      |     |
                                                 |  0x40064e          |      |     |
                                                 =--------------------=      |     |
                                                     v                       |     |
                                                     '-----.   .-------------'     |
                                                           |   |                   |
                                                           |   |                   |
                                                       =--------------------=      |
                                                       |  0x400623          |      |
                                                       =--------------------=      |
                                                             t f                   |
                                                       .-----' '-------------.     |
                                                       |                     |     |
                                                       |                     |     |
                                                 =--------------------=      |     |
                                                 |  0x400653          |      |     |
                                                 =--------------------=      |     |
                                                     v                       |     |
                                                     '-----.   .-------------'     |
                                                           |   |                   |
                                                           |   |                   |
                                                       =--------------------=      |
                                                       |  0x400629          |      |
                                                       =--------------------=      |
                                                               f t                 |
                                                         .-----' '-----------.     |
                                                         |                   |     |
                                                         |                   |     |
                                                 =--------------------=      |     |
                                                 |  0x400636          |      |     |
                                                 =--------------------=      |     |
                                                     v                       |     |
                                                     '-----.     .-----------'     |
                                                           |     |                 |
                                                           |     |                 |
                                                       =--------------------=      |
                                                       |  0x400641          |      |
                                                       =--------------------=      |
                                                               f t                 |
                                                         .-----' '-----------.     |
                                                         |                   |     |
                                                         |                   |     |
                                                 =--------------------=      |     |
                                                 |  0x400645          |      |     |
                                                 =--------------------=      |     |
                                                     v                       |     |
                                                     '------------.   .-.----'-----'
                                                                  |   | |
                                                                  |   | |
                                                              =--------------------=
                                                              |  0x4005da          |
                                                              =--------------------=
                                                                    t f
                                      .-----------------------------' '-------------------.
                                      |                                                   |
                                      |                                                   |
                                =------------------------------------------=      =--------------------=
                                |  0x40065a                                |      |  0x4005ea          |
                                | 0x0040065a call sym.imp.__stack_chk_fail |      =--------------------=
                                | 0x00400675 call sym.imp.__printf_chk     |
                                | 0x0040067c call sym.get_flag             |
                                =------------------------------------------=

```

As you can see there is one execution path which will directly lead to `0x4005da` and then either 
to `0x4005ea` or `sym.imp.__stack_chk_fail` if sth was wrong with the stack (this function 
wil be called if the stack canaries were modified). Now let's have a look what happens inside
the first block:

```.assembler
                =----------------------------------------------------------------------------=
                | [0x4005b0]                                                                 |
                |   ;-- section_end..plt:                                                    |
                |   ;-- section..text:                                                       |
                | (fcn) sym.__libc_csu_ctor 216                                              |
                |   sym.__libc_csu_ctor ();                                                  |
                | ; var int local_8h @ rsp+0x8                                               |
                | ; var int local_10h @ rsp+0x10                                             |
                | ; var int local_11h @ rsp+0x11                                             |
                | ; var int local_12h @ rsp+0x12                                             |
                | ; var int local_14h @ rsp+0x14                                             |
                | ; var int local_18h @ rsp+0x18                                             |
                | ; var int local_38h @ rsp+0x38                                             |
                | 0x004005b0 4883ec48       sub rsp, 0x48                                    |
                | 0x004005b4 64488b042528.  mov rax, qword fs:[0x28]                         |
                | 0x004005bd 4889442438     mov qword [rsp + local_38h], rax                 |
                | 0x004005c2 31c0           xor eax, eax                                     |
                | 0x004005c4 b8d0074000     mov eax, sym.__libc_csu_init                     |
                | 0x004005c9 48c7442408d0.  mov qword [rsp + local_8h], sym.__libc_csu_init  |
                | 0x004005d2 678b4005       mov eax, dword [eax + 5]                         |
                | 0x004005d6 3ccc           cmp al, 0xcc                                     |
                | 0x004005d8 7415           je 0x4005ef ;[a]                                 |
                =----------------------------------------------------------------------------=
                      t f
          .-----------' '-------------------------------------------------.
          |                                                               |
          |                                                               |
    =---------------------------------------------------------------=     |
    |  0x4005ef                                                     |     |
    | 0x004005ef 488b3d8a0a20.  mov rdi, qword [obj.__libc_ptr]     |     |
    | 0x004005f6 c644241046     mov byte [rsp + local_10h], 0x46    |     |
    | 0x004005fb 488d742410     lea rsi, qword [rsp + local_10h]    |     |
    | 0x00400600 c64424114c     mov byte [rsp + local_11h], 0x4c    |     |
    | 0x00400605 66c744241833.  mov word [rsp + local_18h], 0x3933  |     |
    | 0x0040060c b828000000     mov eax, 0x28                       |     |
    | 0x00400611 66c744241241.  mov word [rsp + local_12h], 0x4741  |     |
    | 0x00400618 c64424142d     mov byte [rsp + local_14h], 0x2d    |     |
    | 0x0040061d 40f6c701       test dil, 1                         |     |
    | 0x00400621 752b           jne 0x40064e ;[b]                   |     |
    =---------------------------------------------------------------=     |

```

Apparently the programm will jump to `0x4005ef` only if `$al = 0xcc`:

```.assembler
|           0x004005d6      3ccc           cmp al, 0xcc
|       ,=< 0x004005d8      7415           je 0x4005ef
``` 

Let's debug the binary and see what happens:

```.shell
gef>  b *0x004005d6
Breakpoint 1 at 0x4005d6
gef>  r
gef>  set $al=0xcc
gef>  c
Continuing.
FLAG-Allocating 1024 bytes 0x602420...
Freeing buffer 0x602420...
Heap is working perfectly! No Flag then
[Inferior 1 (process 1745) exited normally]
```

Well `FLAG-Allocating` looks like a flag! ;) 
