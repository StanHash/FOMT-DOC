	mov r0, #3
	and r2, r0 @ r2 can only be 0, 1, 2, or 3

	cmp r2, #3
	bhi skip @ this will never happen?

	@ ...

skip:
	@ ...
