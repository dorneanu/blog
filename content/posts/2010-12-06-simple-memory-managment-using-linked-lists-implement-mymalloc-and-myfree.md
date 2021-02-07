+++
title = "Simple memory managment using linked lists (implement my_malloc and my_free)"
author = "Victor"
date = "2010-12-06"
tags = ["coding", "c"]
category = "blog"
+++

Suppose you were a Linux developer and you're about to implement the well known system calls:  **malloc** and **free**. How would you start? Which (already implemented) functions would you use? How would you **organize** your (free) **memory**? Which information would you like to have about certain memory regions? Those are the minimal problems you're about to face with. What about **memory fragmentation**? Speaking of memory: How would you implement this thing called `memory`? And so on..

The same task caused me a few weeks ago a lot of head scratching. Although I had a framework I could work with, it was more sophisticated than I thought. But let's start with simple things and have a look at the memory I was supposed to use:

![Memory representation](http://dl.dornea.nu/img/2010/222/mm_char_memory.png)

So that's my memory: a simple char array of BUFFSIZE elements. My code is supposed to use this range of memory in an intelligent way. Therefore we'll have to split the memory into multiple **fragments**. Each fragment has a certain size (they don't have to be at the same size) and coresponds to memory that has been allocated to a variable.

~~~.c
int *a = (int*)my_malloc(sizeof(int));
*a = 5;

char* b = (char*)my_malloc(100);
status();
b[0] = 'c';
b[1] = 'o';
b[2] = 'o';
b[3] = 'l';
b[4] = '�';
~~~

**my_malloc(int size)** returns the address of the fragment that has been assigned to variable a or b. When there is no more space left on the memory, NULL will be returned. The same applies when free fragments can't be merged together to a bigger one - in this case we'll have to remap the fragments in order to have enough space for later memory allocations.  Furthermore you can tell* my_malloc* how much space to allocate.

So there must be a way how to organize our fragments inside the memory. By using only pointer to certain addresses within the memory space we have no information about its size, the data size it is storing or the next fragment. That's why a so called **memoryBlock** will be used to store this information. Given a **head** block a linked list should allow us to access all blocks in the memory.

~~~.c
enum memBlockState{not_allocated=0, allocated=1};

// memory block
typedef struct _memoryblock {
    void* data;                                       // points to the data
    int dataLength;                     
    enum memBlockState state;             // Is this Block free?
    struct _memoryblock * nextBlock;    // points to the next entry
} memoryBlock;

#define memoryBlockHeaderSize sizeof(memoryBlock)

// First block in the list
memoryBlock* head;
~~~

And this is the graphical representation:

![Memory Block(s) inside memory](http://dl.dornea.nu/img/2010/222/mm_head.png)

Now we'll have to inter-connect the memory blocks. Therefor we'll be using a **pointer** to next block. In that way we can iterate the blocks, (re)move them or find a suitable place where to place a new block.

![nextBlock pointer](http://dl.dornea.nu/img/2010/222/mm_head_nextblock.png)

So those are the most important programm structures. Let's have a look at the main function within the C-code (see appendix):

~~~.c
// my_alloc will try to allocate <byteCount> bytes within our char memory. 
// The function will return the address of the allocated memory.
void* my_malloc(int byteCount)
{
    memoryBlock *searchBlock = head, *tmp;
    if(!b_initialized)
        initialize();

    // If we don't have enough place to allocate then we give up and return NULL
    if(byteCount > get_free_space())
        return(NULL);

    // Search for the block whose dataLength >= byteCount
    while (searchBlock->dataLength < byteCount)
        searchBlock = searchBlock->nextBlock;

    // We have found an unused memory block. Now we split it. 
    tmp = splitBlock(searchBlock, byteCount);

    // Return the address of data (see memoryBlock structure)
    return tmp->data;
}
~~~

Before beeing able to allocate some memory, the **head** block must be initialized.

~~~.c
void initialize()
{
    if(!b_initialized)
    {
        b_initialized = 1;

        // head will point to the address of memory
        head = (memoryBlock*)memory;

        // The data offset is >beginning of memoryBlock> + memoryBlockHeaderSize
        head->data = head + memoryBlockHeaderSize;
        head->dataLength = sizeof(memory) - memoryBlockHeaderSize;

        // self-explanatory
        head->state = not_allocated;
        head->nextBlock = NULL;
    }
}
~~~

I think the most interesting part of the allocation process is the **splitBlock** function. It searches for the proper block that has to be splitted into 2 parts:

*   a smaller unused/unallocated memory block (new size = old size - byteCount)
*   an allocated memory block (size = byteCount)

~~~.c
memoryBlock *splitBlock(memoryBlock* block, int byteCount)
{
    memoryBlock *new_block;

    // When no enough space in the current block -> return NULL
    if (byteCount > block->dataLength)
        return NULL;

    // Update blocks dataLength
    block->dataLength -= (memoryBlockHeaderSize + byteCount);

    // Create new block
    new_block = (memoryBlock*)((char *)block + memoryBlockHeaderSize + block->dataLength);

    // ... set data pointer
    new_block->data = (void *)((char *)new_block + memoryBlockHeaderSize);

    new_block->dataLength = byteCount;
    new_block->state = allocated;

    // new_block.nextBlock will point to right neighbour of block
    new_block->nextBlock = block->nextBlock;

    block->nextBlock = new_block;

    return new_block;

}
~~~

After some dry runs - allocating memory for some integer/string variables (check out *test_mm.c*) - the memory could end up like this:

![Memory fragmentation](http://dl.dornea.nu/img/2010/222/mm_memory_fragmentation.png)

As you see we could re-arrange the allocated regions in order to get more unused/free memory space. Since this wasn't part of the task - although you could have a look at my_free() too -   I'll leave it to you to google for some dynamic memory allocation algorithms.

In the end I'd like to show you some debugging stuff I've made with **ddd**. As you see each (allocated) portion of memory has its memory header (consisting of the memoryBlock structure) plus a (void *) pointer  to an address inside the memory, where data is stored.

![Memory Block(s) inside memory](http://dl.dornea.nu/img/2010/222/mm_ddd_session.png)

Finally some output generated by the programm:

~~~.shell
Uebersicht des Speichers: 10216 / 10240 Speicher frei
------------------------------------------------
#  at            allocated       space   data                   next block
1  0x5024a0      FALSE           10216   [0x5026e0,0x504ec7]    0x0

[DEBUG] Split block at 0x5024a0

5
Uebersicht des Speichers: 10188 / 10240 Speicher frei
------------------------------------------------
#  at            allocated       space   data                   next block
1  0x5024a0      FALSE           10188   [0x5026e0,0x504eab]    0x504c84
2  0x504c84      TRUE            4       [0x504c9c,0x504c9f]    0x0

[DEBUG] Split block at 0x5024a0

Uebersicht des Speichers: 10064 / 10240 Speicher frei
------------------------------------------------
#  at            allocated       space   data                   next block
1  0x5024a0      FALSE           10064   [0x5026e0,0x504e2f]    0x504c08
2  0x504c08      TRUE            100     [0x504c20,0x504c83]    0x504c84
3  0x504c84      TRUE            4       [0x504c9c,0x504c9f]    0x0

cool

[DEBUG] Split block at 0x5024a0

Uebersicht des Speichers: 9960 / 10240 Speicher frei
------------------------------------------------
#  at            allocated       space   data                   next block
1  0x5024a0      FALSE           9960    [0x5026e0,0x504dc7]    0x504ba0
2  0x504ba0      TRUE            80      [0x504bb8,0x504c07]    0x504c08
3  0x504c08      TRUE            100     [0x504c20,0x504c83]    0x504c84
4  0x504c84      TRUE            4       [0x504c9c,0x504c9f]    0x0

Konnte kein Speicher allozieeren
Uebersicht des Speichers: 9960 / 10240 Speicher frei
------------------------------------------------
#  at            allocated       space   data                   next block
1  0x5024a0      FALSE           9960    [0x5026e0,0x504dc7]    0x504ba0
2  0x504ba0      TRUE            80      [0x504bb8,0x504c07]    0x504c08
3  0x504c08      TRUE            100     [0x504c20,0x504c83]    0x504c84
4  0x504c84      TRUE            4       [0x504c9c,0x504c9f]    0x0

[DEBUG] Free block at 0x504c08

Uebersicht des Speichers: 9960 / 10240 Speicher frei
------------------------------------------------
#  at            allocated       space   data                   next block
1  0x5024a0      FALSE           9960    [0x5026e0,0x504dc7]    0x504ba0
2  0x504ba0      TRUE            204     [0x504bb8,0x504c83]    0x504c84
3  0x504c84      TRUE            4       [0x504c9c,0x504c9f]    0x0

Uebersicht des Speichers: 9960 / 10240 Speicher frei
------------------------------------------------
#  at            allocated       space   data                   next block
1  0x5024a0      FALSE           9960    [0x5026e0,0x504dc7]    0x504ba0
2  0x504ba0      TRUE            204     [0x504bb8,0x504c83]    0x504c84
3  0x504c84      TRUE            4       [0x504c9c,0x504c9f]    0x0

[DEBUG] Split block at 0x5024a0

Uebersicht des Speichers: 9856 / 10240 Speicher frei
------------------------------------------------
#  at            allocated       space   data                   next block
1  0x5024a0      FALSE           9856    [0x5026e0,0x504d5f]    0x504b38
2  0x504b38      TRUE            80      [0x504b50,0x504b9f]    0x504ba0
3  0x504ba0      TRUE            204     [0x504bb8,0x504c83]    0x504c84
4  0x504c84      TRUE            4       [0x504c9c,0x504c9f]    0x0

[DEBUG] Free block at 0x504ba0

Uebersicht des Speichers: 9856 / 10240 Speicher frei
------------------------------------------------
#  at            allocated       space   data                   next block
1  0x5024a0      FALSE           9856    [0x5026e0,0x504d5f]    0x504b38
2  0x504b38      TRUE            308     [0x504b50,0x504c83]    0x504c84
3  0x504c84      TRUE            4       [0x504c9c,0x504c9f]    0x0

[DEBUG] Free block at 0x504c84

Uebersicht des Speichers: 9856 / 10240 Speicher frei
------------------------------------------------
#  at            allocated       space   data                   next block
1  0x5024a0      FALSE           9856    [0x5026e0,0x504d5f]    0x504b38
2  0x504b38      TRUE            336     [0x504b50,0x504c9f]    0x0

[DEBUG] Free block at 0x504b38

Uebersicht des Speichers: 10216 / 10240 Speicher frei
------------------------------------------------
#  at            allocated       space   data                   next block
1  0x5024a0      FALSE           10216   [0x5026e0,0x504ec7]    0x0

Press any key to continue...(Where's the 'any' key btw?)
~~~

**Download material:**

<table style="width: 100%;" border="1" cellspacing="1" cellpadding="1">
  <tr>
    <td class="rtecenter" style="background-color: #9999ff;" colspan="2">
      <strong>mm.c</strong>
    </td>
    
    <td style="border-color: #000000;">
      <a href="http://git.dornea.nu/studium/raw/master/wise2010-2011/ti3/exercises/0x4/Aufgabe_4/mm.c">http://git.dornea.nu/studium/raw/master/wise2010-2011/ti3/exercises/0x4/Aufgabe_4/mm.c</a>
    </td>
  </tr>
  
  <tr>
    <td class="rtecenter" style="background-color: #9999ff;" colspan="2">
      <strong>mm.h</strong>
    </td>
    
    <td style="border-color: #000000;">
      <a href="http://git.dornea.nu/studium/raw/master/wise2010-2011/ti3/exercises/0x4/Aufgabe_4/mm.h">http://git.dornea.nu/studium/raw/master/wise2010-2011/ti3/exercises/0x4/Aufgabe_4/mm.h</a>
    </td>
  </tr>
  
  <tr>
    <td class="rtecenter" style="background-color: #9999ff;" colspan="2">
      <strong>test_mm.c</strong>
    </td>
    
    <td style="border-color: #000000;">
      <a href="http://git.dornea.nu/studium/raw/master/wise2010-2011/ti3/exercises/0x4/Aufgabe_4/test_mm.c">http://git.dornea.nu/studium/raw/master/wise2010-2011/ti3/exercises/0x4/Aufgabe_4/test_mm.c</a>
    </td>
  </tr>
</table>
