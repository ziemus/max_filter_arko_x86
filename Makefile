CC=gcc
ASM=nasm
RESULT=result

ifeq ($(OS),Windows_NT)
RM_CMD=del
RM_RES=$(RESULT).exe
else
RM_CMD=rm
RM_RES=$(RESULT)
endif

LFLAGS=-lmingw32 -lSDL2main -lSDL2 -lSDL2_image
CFLAGS=-m32
AFLAGS=-f elf32


all:result

main.o: main.c
	$(CC) $(CFLAGS) -c main.c
func.o: func.asm
	$(ASM) $(AFLAGS) func.asm -o func.o
result: main.o func.o
	$(CC) $(CFLAGS) main.o func.o -o $(RESULT) $(LFLAGS)
	$(RM_CMD) *.o
clean: 
	$(RM_CMD) *.o
	$(RM_CMD) $(RM_RES)
	
	
RESULT=result

