%ifndef syscalls__
%define syscalls__

%define READ		  0
%define WRITE		  1
%define OPEN		  2
%define CLOSE		  3
%define POLL		  7

; noté ici parce que l'utilisation de l'appel système est différent
; des parametres de la glibc
; rdi: how	rsi: sigset_t * rdx: sigset_t *oset	r10: size_t sigsetsize
%define SIGPROCMASK	 14
%define IOCTL		 16
%define ALARM		 37
%define GETPID		 39
%define SOCKET		 41
%define CONNECT		 42
%define ACCEPT		 43
%define SENDTO		 44
%define RECVFROM	 45
%define SHUTDOWN	 48
%define BIND		 49
%define LISTEN		 50
%define GETSOCKNAME  51
%define SETSOCKOPT	 54
%define EXIT		 60
%define KILL		 62
%define SIGNALFD	282
%define GETRANDOM	318

%define POLLIN		0x0001
%define POLLPRI		0x0002
%define POLLOUT		0x0004
%define POLLERR		0x0008
%define POLLHUP		0x0010
%define POLLNVAL	0x0020

%define AF_INET		2

%define SOCK_STREAM 1
%define SOCK_DGRAM  2

%define SOL_SOCKET  1

%define SO_REUSEADDR 2
%define SO_BROADCAST 6
%define SO_REUSEPORT 15

%define UDP_PORT 0xAE1E
%define TCP_PORT 0xAD1E

%define SIG_BLOCK 0

%define SIGALRM 14

%endif