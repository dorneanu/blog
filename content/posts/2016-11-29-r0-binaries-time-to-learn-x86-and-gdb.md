+++
title = "ringzer0 CTF - Binaries - Time to learn x86 ASM and gdb"
author = "Victor Dorneanu"
date = "2016-11-29"
tags = ["ringzer0", "ctf", "wargames", "asm", "x86", "sploitfun"]
category = "blog"
+++


This one was a quite easy one. Using radare let's find more information about the binary:

```.shell
$ r2 -AA 88eb31060c4abd0931878bf7d2dd8c1a

[0x08048380]> iI
havecode true
pic      false
canary   false
nx       true
crypto   false
va       true
intrp    /lib/ld-linux.so.2
bintype  elf
class    ELF32
lang     c
arch     x86
bits     32
machine  Intel 80386
os       linux
minopsz  1
maxopsz  16
pcalign  0
subsys   linux
endian   little
stripped false
static   false
linenum  true
lsyms    true
relocs   true
rpath    NONE
binsz    7450
```

Ok, now let's have a look at the **entry point**:

```.assembler
[0x08048380]> pdf @ sym.main
;-- main:
/ (fcn) sym.main 231
   sym.main ();
           ; var int local_4h_2 @ ebp-0x4
           ; var int local_4h @ esp+0x4
           ; var int local_8h @ esp+0x8
           ; var int local_1ch @ esp+0x1c
           ; arg int arg_2ch @ esp+0x2c
           ; JMP XREF from 0x08048397 (entry0)
           ; DATA XREF from 0x08048397 (entry0)
           0x0804846c      55             push ebp
           0x0804846d      89e5           mov ebp, esp
           0x0804846f      57             push edi
           0x08048470      83e4f0         and esp, 0xfffffff0
           0x08048473      83ec30         sub esp, 0x30               ; '0'
           0x08048476      c744242c0000.  mov dword [esp + arg_2ch], 0
           0x0804847e      c70424180000.  mov dword [esp], 0x18       ; [0x18:4]=0x8048380 sym._start
           0x08048485      e8a6feffff     call sym.imp.malloc        ;  void *malloc(size_t size);
           0x0804848a      8944242c       mov dword [esp + arg_2ch], eax
           0x0804848e      c74424081800.  mov dword [esp + local_8h], 0x18 ; [0x18:4]=0x8048380 sym._start
           0x08048496      c74424040000.  mov dword [esp + local_4h], 0
           0x0804849e      8b44242c       mov eax, dword [esp + arg_2ch] ; [0x2c:4]=0x280009 ; ','
           0x080484a2      890424         mov dword [esp], eax
           0x080484a5      e8c6feffff     call sym.imp.memset
           0x080484aa      8b44242c       mov eax, dword [esp + arg_2ch] ; [0x2c:4]=0x280009 ; ','
           0x080484ae      c700464c4147   mov dword [eax], 0x47414c46 ; [0x47414c46:4]=-1
           0x080484b4      c740042d3430.  mov dword [eax + 4], 0x3930342d ; [0x3930342d:4]=-1
           0x080484bb      66c740083200   mov word [eax + 8], 0x32    ; '2' ; [0x32:2]=27 ; '2'
           0x080484c1      8b44242c       mov eax, dword [esp + arg_2ch] ; [0x2c:4]=0x280009 ; ','
           0x080484c5      c744241cffff.  mov dword [esp + local_1ch], 0xffffffff ; [0xffffffff:4]=-1 LEA edi ; edi
           0x080484cd      89c2           mov edx, eax
           0x080484cf      b800000000     mov eax, 0
           0x080484d4      8b4c241c       mov ecx, dword [esp + local_1ch] ; [0x1c:4]=52
           0x080484d8      89d7           mov edi, edx
           0x080484da      f2ae           repne scasb al, byte es:[edi]
           0x080484dc      89c8           mov eax, ecx
           0x080484de      f7d0           not eax
           0x080484e0      8d50ff         lea edx, [eax - 1]
           0x080484e3      8b44242c       mov eax, dword [esp + arg_2ch] ; [0x2c:4]=0x280009 ; ','
           0x080484e7      01d0           add eax, edx
           0x080484e9      c70038343975   mov dword [eax], 0x75393438 ; [0x75393438:4]=-1
           0x080484ef      c74004696f32.  mov dword [eax + 4], 0x6a326f69 ; [0x6a326f69:4]=-1
           0x080484f6      66c740086600   mov word [eax + 8], 0x66    ; 'f' ; [0x66:2]=0 ; 'f'
           0x080484fc      c70424f88504.  mov dword [esp], str.Loading... ; [0x80485f8:4]=0x64616f4c LEA str.Loading... ; "Loading..." @ 0x80485f8
           0x08048503      e838feffff     call sym.imp.puts
           0x08048508      8b44242c       mov eax, dword [esp + arg_2ch] ; [0x2c:4]=0x280009 ; ','
           0x0804850c      c744241cffff.  mov dword [esp + local_1ch], 0xffffffff ; [0xffffffff:4]=-1 LEA edi ; edi
           0x08048514      89c2           mov edx, eax
           0x08048516      b800000000     mov eax, 0
           0x0804851b      8b4c241c       mov ecx, dword [esp + local_1ch] ; [0x1c:4]=52
           0x0804851f      89d7           mov edi, edx
           0x08048521      f2ae           repne scasb al, byte es:[edi]
           0x08048523      89c8           mov eax, ecx
           0x08048525      f7d0           not eax
           0x08048527      8d50ff         lea edx, [eax - 1]
           0x0804852a      8b44242c       mov eax, dword [esp + arg_2ch] ; [0x2c:4]=0x280009 ; ','
           0x0804852e      01d0           add eax, edx
           0x08048530      c7006b6c736a   mov dword [eax], 0x6a736c6b ; [0x6a736c6b:4]=-1
           0x08048536      c74004346b6c.  mov dword [eax + 4], 0x6c6b34 ; [0x6c6b34:4]=-1
           0x0804853d      c70424038604.  mov dword [esp], str.Where_is_the_flag_ ; [0x8048603:4]=0x72656857 LEA str.Where_is_the_flag_ ; "Where is the flag?" @ 0x8048603
           0x08048544      e8f7fdffff     call sym.imp.puts
           0x08048549      b800000000     mov eax, 0
           0x0804854e      8b7dfc         mov edi, dword [ebp - local_4h_2]
           0x08048551      c9             leave
           0x08048552      c3             ret

```

Indeed, this is a lot of information. Let's dissect the programm's flow:

```.assembler
           0x0804846c      55             push ebp
           0x0804846d      89e5           mov ebp, esp
           0x0804846f      57             push edi
           0x08048470      83e4f0         and esp, 0xfffffff0
           0x08048473      83ec30         sub esp, 0x30               ; '0'
```

This looks like a function **prologue**: Save the **stack base pointer**, allocate additional stack place (0x30). 

```.assembler
           0x08048476      c744242c0000.  mov dword [esp + arg_2ch], 0
           0x0804847e      c70424180000.  mov dword [esp], 0x18       ; [0x18:4]=0x8048380 sym._start
           0x08048485      e8a6feffff     call sym.imp.malloc        ;  void *malloc(size_t size);
```

Allocate some heap using `malloc` ...

```.assembler
           0x0804848a      8944242c       mov dword [esp + arg_2ch], eax
           0x0804848e      c74424081800.  mov dword [esp + local_8h], 0x18 ; [0x18:4]=0x8048380 sym._start
           0x08048496      c74424040000.  mov dword [esp + local_4h], 0
           0x0804849e      8b44242c       mov eax, dword [esp + arg_2ch] ; [0x2c:4]=0x280009 ; ','
           0x080484a2      890424         mov dword [esp], eax
           0x080484a5      e8c6feffff     call sym.imp.memset
```

The syntax for `memset` looks like this:

```.c
SYNOPSIS
    void *memset(void *s, int c, size_t n);

DESCRIPTION
   The memset() function fills the first n bytes of the memory area pointed to by s with the constant byte c.

RETURN VALUE
  The memset() function returns a pointer to the memory area s.
```

Since we're dealing with `x86` ([this site](http://wiki.osdev.org/Calling_Conventions) is very good) the
arguments for `memset` are being pushed into the stack:

{{< expand "Graphviz code" >}}
    dot {
		digraph G {
		 
			// Define layout
			graph [pad=".75", ranksep="0.95", nodesep="0.05"];
			rankdir=LR;
			node [shape="record"];
			rank=same;
		 
			// Define pointers
			rsp [
				label="<p> $rsp \l", height="0.1",
				color=white, fontcolor=black,fontsize=9,style=filled, fillcolor=white
			];
			rbp [
				label="<p> $rbp \l", height="0.1",
				color=white, fontcolor=black,fontsize=9,style=filled, fillcolor=white
			];
		 
			rsp_4 [
				label="<p> $rsp + 4 \l", height="0.01",
				color=white, fontcolor=black,fontsize=9,style=filled, fillcolor=white
			];
		 
		 
			rsp_8 [
				label="<p> $rsp + 8 \l", height="0.01",
				color=white, fontcolor=black,fontsize=9,style=filled, fillcolor=white,
			];
		 
			// rsp_12 [
			// 	label="<p> $rsp + 12 \l", height="0.01",
			// 	color=white, fontcolor=black,fontsize=9,style=filled, fillcolor=white,
			// ];
		 
			// Define stack
			stack [
				width="3",
				label="<p>\nStack\n\n | <bp>\n...\n\n | <8>0x8 \l | <4>0x0  \l | <0>pointer to memory allocated by malloc() \l"
			];
		   
		   
			// Pointer -> Stack edges
			rbp:p -> stack:bp [style=dotted];
			rsp:p -> stack:0 [style=dotted];
			rsp_4:p -> stack:4 [style=invis];
			rsp_8:p -> stack:8 [style=invis];
		}
    }
{{< /expand >}}

![stack](/posts/img/2016/r0-binaries/stack.dot.png)

So `memset` will set the value "0" 8 times at the address pointed by `eax`. Afterwards
some values will be `mov`ed into the previously allocated memory range:


```.assembler
           0x080484aa      8b44242c       mov eax, dword [esp + arg_2ch] ; [0x2c:4]=0x280009 ; ','
           0x080484ae      c700464c4147   mov dword [eax], 0x47414c46 ; [0x47414c46:4]=-1
           0x080484b4      c740042d3430.  mov dword [eax + 4], 0x3930342d ; [0x3930342d:4]=-1
           0x080484bb      66c740083200   mov word [eax + 8], 0x32    ; '2' ; [0x32:2]=27 ; '2'
           0x080484c1      8b44242c       mov eax, dword [esp + arg_2ch] ; [0x2c:4]=0x280009 ; ','
           0x080484c5      c744241cffff.  mov dword [esp + local_1ch], 0xffffffff ; [0xffffffff:4]=-1 LEA edi ; edi
           0x080484cd      89c2           mov edx, eax
           0x080484cf      b800000000     mov eax, 0
           0x080484d4      8b4c241c       mov ecx, dword [esp + local_1ch] ; [0x1c:4]=52
           0x080484d8      89d7           mov edi, edx
           0x080484da      f2ae           repne scasb al, byte es:[edi]
           0x080484dc      89c8           mov eax, ecx
           0x080484de      f7d0           not eax
           0x080484e0      8d50ff         lea edx, [eax - 1]
           0x080484e3      8b44242c       mov eax, dword [esp + arg_2ch] ; [0x2c:4]=0x280009 ; ','
           0x080484e7      01d0           add eax, edx
           0x080484e9      c70038343975   mov dword [eax], 0x75393438 ; [0x75393438:4]=-1
           0x080484ef      c74004696f32.  mov dword [eax + 4], 0x6a326f69 ; [0x6a326f69:4]=-1
           0x080484f6      66c740086600   mov word [eax + 8], 0x66    ; 'f' ; [0x66:2]=0 ; 'f'
           0x080484fc      c70424f88504.  mov dword [esp], str.Loading... ; [0x80485f8:4]=0x64616f4c LEA str.Loading... ; "Loading..." @ 0x80485f8
```  
At this point I'll switch to **dynamic analysis** and therefore **run** the code:

```
$ gdb 88eb31060c4abd0931878bf7d2dd8c1a
...
gef> b *0x080484aa
gef> r
```

Now from `0x080484aa` through `0x080484fc` you can `s` (step) the opcodes. Then pay attention to the stack. You
should have sth like:
 
{{< expand "Graphviz code" >}}
    dot {
		digraph G {
		 
			// Define layout
			graph [pad=".75", ranksep="0.95", nodesep="0.05"];
			rankdir=LR;
			node [shape="record"];
			rank=same;
		 
			// Define pointers
			rsp [
				label="<p> $rsp \l", height="0.1",
				color=white, fontcolor=black,fontsize=9,style=filled, fillcolor=white
			];
			rbp [
				label="<p> $rbp \l", height="0.1",
				color=white, fontcolor=black,fontsize=9,style=filled, fillcolor=white
			];
		 
			rsp_4 [
				label="<p> $rsp + 4 \l", height="0.01",
				color=white, fontcolor=black,fontsize=9,style=filled, fillcolor=white
			];
		 
		 
			rsp_8 [
				label="<p> $rsp + 8 \l", height="0.01",
				color=white, fontcolor=black,fontsize=9,style=filled, fillcolor=white,
			];
		 
			rsp_12 [
				label="<p> $rsp + 12 \l", height="0.01",
				color=white, fontcolor=black,fontsize=9,style=filled, fillcolor=white,
			];
		 
			// Define stack
			stack [
				width="3",
				label="<p>\nStack\n\n | <bp>\n...\n\n | <12>0x080485b2  \l | <8>0x18 \l | <4>0x0  \l | <0>0x0804b008 \l"
			];
		   
			// Define values
			val [
				width="5",color=blue,
				label="<p>\nValues\n\n | \n...\n\n | <1>FLAG-4092849uio2jf \l | <2>(__libc_csu_init+82): add esi,0x1 \l"
			];
		   
		   
			// Pointer -> Stack edges
			rbp:p -> stack:bp [style=dotted];
			rsp:p -> stack:0 [style=dotted];
			rsp_4:p -> stack:4 [style=invis];
			rsp_8:p -> stack:8 [style=invis];
			rsp_12:p -> stack:12 [style=invis];
		 
			// Trick to have everything horizontally aligned
			stack:p -> val:p [style=invis];
		   
			// Stack -> Values edges
			edge[style=dotted];
			stack:0 -> val:1 [color=red];
			stack:12 -> val:2;
		}
{{< /expand >}}

![stack](/posts/img/2016/r0-binaries/stack-values.dot.png)

Bingo. So the flag is `FLAG-4092849uio2jf`. 
