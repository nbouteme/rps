%ifndef __termios
%define __termios

%define NCCS 32

struc termios
.iflag: resd 1
.oflag: resd 1
.cflag: resd 1
.lflag: resd 1
.line:  resb 1
.cc:    resb NCCS
.ispeed: resd 1
.ospeed: resd 1
.size:
endstruc

%define ECHO 0000010
%define ICANON	0000002

%define TCGETS 0x5401
%define TCSETSF	0x5404

%endif