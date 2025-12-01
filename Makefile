SRC := $(wildcard *.asm)
LIB_SRC := $(wildcard lib/*.asm)
OBJ := $(SRC:.asm=.o)
LIB_OBJ := $(LIB_SRC:.asm=.o)
BIN := $(SRC:.asm=)

all: $(BIN)

# Assemble main and lib files
%.o: %.asm
	nasm -g -f elf64 $< -o $@

# Link using ld, include lib objects
%: %.o $(LIB_OBJ)
	ld $^ -o $@

clean:
	rm -f $(OBJ) $(LIB_OBJ) $(BIN)
