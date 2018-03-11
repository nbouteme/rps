%ifndef event_loop__
%define event_loop__

struc event_loop
.sources:	resq 1
.fds:		resq 1
.nsources:	resd 1
.running:	resd 1
.current:	resd 1
.size:
endstruc

extern init_event_loop
extern add_source
extern remove_source
extern run_event_loop

%endif