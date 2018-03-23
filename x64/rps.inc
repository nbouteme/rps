%ifndef rps__
%define rps__

%include "source.inc"

struc rps_game
.base: resb source
.el: resq 1
.fds: resd 256
.nplayers: resb 1
.maxplayers: resb 1
.points: resd 256
.mypoints: resd 1
.ready: resb 1
.size:
endstruc

%endif