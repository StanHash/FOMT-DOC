	mov r0, #2

	mov r1, #1
	neg r1, r1

loop:
	@ do nothing?

	sub r0, #1

	cmp r0, r1
	bne loop
