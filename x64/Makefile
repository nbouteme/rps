SRC =	event_loop.s hash_data.s host.s \
		main.s sig.s undef.s utils.s client_udp.s\
		client_tcp.s rps.s

OBJ = $(SRC:.s=.o)
NAME = rpsm

all: $(NAME)

$(NAME): $(OBJ)
	ld $(OBJ) -o $@ -e _start

%.o: %.s
	nasm -f elf64 $^ -o $@
