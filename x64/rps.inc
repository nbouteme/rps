%ifndef rps__
%define rps__

%include "source.inc"

struc rps_game
.base: resb source.size
.el: resq 1
.fds: resd 256
.nplayers: resb 1
.maxplayers: resb 1
.points: resb 256
.mypoints: resb 1
.ready: resb 1
.size:
endstruc

%endif