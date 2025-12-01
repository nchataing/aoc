SRC := $(wildcard *.asm)
OBJ := $(SRC:.asm=.o)
BIN := $(SRC:.asm=)

all: $(BIN)

%.o: %.asm
	nasm -g -felf64 $< -o $@

%: %.o
	gcc -g -no-pie $< -o $@

clean:
	rm -f $(OBJ) $(BIN)
