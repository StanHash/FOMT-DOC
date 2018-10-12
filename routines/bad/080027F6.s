	mov r0, r9 @ dest
	mov r1, r9 @ src (=dest?????)
	mov r2, #0x20
	bl  memcpy
