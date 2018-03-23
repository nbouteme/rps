%ifndef client_private__
%define client_private__

%include "client.inc"

struc client_tcp_private
.sock: resd 1
.en: resb 1
.size:
endstruc

struc client_udp_private
.el: resq 1
.serv: resq 1
.size:
endstruc

%endif