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

%endif