CC=gcc
ASM=nasm
ARCH?=32
RESULT=result

ifeq ($(OS),Windows_NT)
RM_CMD=del
RM_RES=$(RESULT).exe
else
RM_CMD=rm
RM_RES=$(RESULT)
endif

ifeq ($(ARCH),64)
CFLAGS=
AFLAGS=-f elf64
else
CFLAGS=-m32
AFLAGS=-f elf32
endif


all:result

main.o: main.c
	$(CC) $(CFLAGS) -c main.c
func.o: func.asm
	$(ASM) $(AFLAGS) func.asm -o func.o
result: main.o func.o
	$(CC) $(CFLAGS) main.o func.o -o $(RESULT)
	$(RM_CMD) *.o
clean: 
	$(RM_CMD) *.o
	$(RM_CMD) $(RM_RES)
	
	
RESULT=result

