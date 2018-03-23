%ifndef client__
%define client__

%include "source.inc"

struc client_tcp_server
.base: resb source.size
.priv: resq 1
.size:
endstruc

struc client_udp_listener
.base: resb source.size
.priv: resq 1
.size:
endstruc

struc client_host_connection
.base: resb source.size
.rps: resq 1
.parent: resq 1
.host: resd 1
.size:
endstruc

%endif