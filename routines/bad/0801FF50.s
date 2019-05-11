
	mov r6, #0 @ <---

	ldr r1, [r4, #0x10]

	cmp r6, r1
	beq skip

	cmp r1, #0
	beq skip

	@ ...

skip:
	@ ...
