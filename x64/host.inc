%ifndef host__
%define host__

%include "source.inc"

struc host_tcp_server
.base: resb source.size
.priv: resq 1
.size:
endstruc

struc host_udp_emitter
.base: resb source.size
.priv: resq 1
.size:
endstruc

extern init_host_udp_emitter
extern init_host_tcp_server

%endif