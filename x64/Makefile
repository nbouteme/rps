SRC = event_loop.s hash_data.s main.s sig.s undef.s
OBJ = $(SRC:.s=.o)
NAME = rpsm

all: $(NAME)

$(NAME): $(OBJ)
	ld $(OBJ) -o $@ -e _start

%.o: %.s
	nasm -f elf64 $^ -o $@
