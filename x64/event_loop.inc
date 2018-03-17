%ifndef event_loop__
%define event_loop__

struc pollfd
.fd:      resd 1
.events:  resw 1
.revents: resw 1
.size:
endstruc

struc event_loop
.sources:	resq 10
.fds:		resb pollfd.size * 10
.nsources:	resd 1
.running:	resd 1
.current:	resd 1
.size:
endstruc

%endif
