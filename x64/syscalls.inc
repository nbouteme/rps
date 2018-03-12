%ifndef syscalls__
%define syscalls__

%define READ		  0
%define WRITE		  1
%define OPEN		  2
%define CLOSE		  3
%define POLL		  7
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

%endif