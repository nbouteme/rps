%ifndef host_private__
%define host_private__

%include "host.inc"

struc addr_inet4
.family: resw 1
.port: resw 1
.addr: resd 1
.pad: resb 8
.size:
endstruc

struc tcp_client
.sock: resd 1
.lport: resw 1
.addr: resb addr_inet4.size
.size:
endstruc

struc host_tcp_private
.el: resq 1
.sock: resd 1
.allocated: resb 1
.left: resb 1
.places: resb 256 * tcp_client.size							; haha lol
.size:
endstruc

struc host_udp_private
.el: resq 1
.serv: resq 1
.sock: resd 1
.size:
endstruc

%endif
