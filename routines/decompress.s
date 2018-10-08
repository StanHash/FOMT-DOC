@ Note: this research done with the FOMTU version of the decompressor (so the offsets will correspond to there)
@ afaik it didn't change for MFOMTU except for the fact that it was relocated.

@ arguments:
@     r0 = source
@     r1 = target
@
@ returns:
@     r0 = size

.thumb

.global decompress

decompress:
	push  {r4-r7, lr}
	mov	  r4, r8
	mov	  r5, r9
	mov	  r6, r10
	mov	  r7, r11
	push  {r4-r7}
	ldr	  r2, =-0x420
	add	  sp, r2
	
	@ sp = -0x420
	@ r7 = {-0x420}
	
	mov	  r7, sp
	ldmia r0!, {r4} @ r4 = header (8 bits =	0x70; 24 bits =	size?)
	lsr   r4, r4, #8	@ r4 = size
	
	@ sp = -0x424
	@ [-0x424] = size
	
	push  {r4}   @ [-0x424] = size
	mov   r8, r4 @ r8 = size?
	sub   r1, #2 @ r1 = target - 2
	add   r8, r1 @ r8 = target + size - 2?
	mov   r2, #0 @ r2 = 0 @ DATA
	mov   r3, r2 @ r3 = 0 @ CURRENT BIT (?)
	mov   r4, #8 @ r4 = 8 @ BITS TO READ (?)

	bl    decomp_read_bits	@ (r0 =	source + 4)

	str   r4, [r7]	@ [-0x420] = r4
	mov   r6, r4
	
	lsl   r4, #27
	lsr   r4, #30 @ r4 = bits 3-4 (huffman type identifier)
	
	@ TYPES:
	@ 0/3 = not huffman (raw data)
	@ 1   = 4bit tree
	@ 2   = 8bit tree
	
	sub   r4, #1
	beq   huff_code_1

	subs  r4, #1
	beq   huff_code_2

	ldr   r5, =(decomp_readbyte_raw+1)
	b     huff_ready

huff_code_1:
	mov   r4, #4
	ldr   r5, =(decomp_readbyte_huff4+1)
	b     huff_common

huff_code_2:
	mov   r4, #8
	ldr   r5, =(decomp_readbyte_huff8+1)

huff_common:
	bl    decomp_read_huffman_tree @ build/read huffman tree

huff_ready:
	@ r9 = Read Byte Function
	mov   r9, r5
	
	@ r1 = target
	push  {r1}
	
	@ r6 = bits 0-2
	lsl   r6, r6, #29
	lsr   r6, r6, #29
	
	sub   r6, #1
	beq   pass1_code1

	sub   r6, #1
	beq   pass1_code2

	sub   r6, #1
	beq   pass1_code3

	sub   r6, #1
	beq   pass1_code4

	bl    decomp_pass1_default
	b     pass1_end

pass1_code1:
	bl    decomp_pass1_type1
	b     pass1_end

pass1_code2:
	bl    decomp_pass1_type2
	b     pass1_end

pass1_code3:
	bl    decomp_pass1_type3
	b     pass1_end

pass1_code4:
	bl    decomp_pass1_type4

pass1_end:
	pop   {r0}
	
	ldr   r4, [r7]
	
	@ r4 = bits 5-7
	lsl   r4, r4, #24 @ 18
	lsr   r4, r4, #29 @ 1D
	
	sub   r4, #1
	beq   loc_80D10C4

	sub   r4, #1
	beq   loc_80D10CA

	sub   r4, #1
	beq   loc_80D10D0

	sub   r4, #1
	beq   loc_80D10D6

	b     end

loc_80D10C4:
	bl    decomp_pass2_type1
	b     end

loc_80D10CA:
	bl    decomp_pass2_type2
	b     end

loc_80D10D0:
	bl    decomp_pass2_type3
	b     end

loc_80D10D6:
	bl    decomp_pass2_type4

end:
	pop   {r0}

	ldr   r2, =0x420
	add   sp, r2

	pop   {r4-r7}
	mov   r8, r4
	mov   r9, r5
	mov   r10, r6
	mov   r11, r7
	pop   {r4-r7}
	pop   {r1}
	bx    r1

@ End of function SomeDecompMaybe

decomp_read_huffman_tree: @ Build huffman tree

@ input:
	@ r0-r3: DECOMP STATE
	@ r4:    bit count per node value

	push  {r1, r5-r6, lr}
	
	@ r10 = argument
	mov   r10, r4
	
	@ r6 = 1
	mov   r6, #1
	
	@ r5 = -1 (?)
	sub   r5, r6, #2
	
	@ r6 = 1 << argument
	lsl   r6, r4
	
	@ r4 = -1
	mov   r4, r5
	
	@ r1 = {-0x400}; Some array buffer thing
	mov   r1, r7
	add   r1, #0x20

	@ do { *buf++ = -1; *buf++ = -1; } while ((count -= 2) > 0);
loc_80D1100:
	@ [r1] = { 0xFFFFFFFF, 0xFFFFFFFF } (8 times 0xFF)
	@ r1  += 8
	stmia r1!, {r4, r5}
	sub   r6, #2
	bgt   loc_80D1100
	
	@ r11 = 0x20
	mov   r4, #0x20
	mov   r11, r4
	
	@ r5  = 0
	@ r12 = 0
	mov   r5, #0
	mov   r12, r5

	@ r6 = argument * 2
	mov   r6, r10
	lsl   r6, r6, #1

	@ do {
loc_80D1112:
	@ r5 *= 2
	lsls  r5, r5, #1
	
	@ unsigned readCount = decomp_read(state, argument);
	mov   r4, r10
	bl    decomp_read_bits

	@ if (!readCount) continue;
	tst   r4, r4
	beq   loc_80D1160

	push  {r6}
	
	@ r6 is temp here

	@ do {
loc_80D1120:
	@ r9 = readCount
	mov   r9, r4
	
	@ r1 = 0x20
	mov   r1, #0x20
	
	@ r6 = mainLoopCounter (r12)
	mov   r6, r12
	
	@ while (mainLoopCounter != 0) {
	tst   r6, r6
	beq   loc_80D1146

loc_80D112A:
	@ r4 = (r5 >> mainLoopCounter) (% 2 * 2 ?) + r1
	mov   r4, r5
	lsr   r4, r6
	lsl   r4, r4, #31
	lsr   r4, r4, #30
	add   r4, r4, r1
	
	@ short r1 = buf[(r5 >> mainLoopCounter) % 2]
	ldsh  r1, [r7, r4]
	tst   r1, r1
	bpl   loc_80D1142

	@ r1 = r11 += 4
	mov   r1, r11
	add   r1, #4
	mov   r11, r1
	strh  r1, [r7, r4]

loc_80D1142:
	@ mainLoopCounter--;
	sub   r6, #1
	bne   loc_80D112A

	@ }
loc_80D1146:
	lsl   r6, r5, #31
	lsr   r6, r6, #30
	add   r6, r6, r1
	
	@ read = decomp_read(state, argument);
	mov   r4, r10
	bl    decomp_read_bits

	@ read = ~read
	mvn   r4, r4
	strh  r4, [r7, r6]
	@ r5++
	add   r5, #1

	@ readCount--
	mov   r4, r9
	sub   r4, #1
	bne   loc_80d1120

	pop   {r6}
	
	@ r6 isn't temp here

loc_80D1160:
	@ while (r12++, (--r6 != 0));
	movs  r1, #1
	add   r12, r1
	subs  r6, #1
	bne   loc_80D1112

	pop   {r1, r5-r6, pc}


decomp_readbyte_raw: @ Read byte directly from source
	movs	r4, #8
	b	decomp_read_bits


decomp_readbyte_huff4: @ Read byte from huffman encoded source (4bit tree)
	push {r5-r6, lr}
	bl   decomp_read_huffman

	lsl  r6, r4, #4
	bl   decomp_read_huffman

	orr  r4, r6
	pop  {r5-r6, pc}


decomp_readbyte_huff8: @ Read byte from huffman encoded source (8bit tree)
	push {r5, lr}
	
	bl   decomp_read_huffman
	
	pop  {r5, pc}


decomp_read_huffman: @ Read from huffman tree
	mov   r4, #0x20

loc_80D1188:
	sub   r3, #1
	bmi	  loc_80D119E

loc_80D118C:
	lsr   r5, r2, #31
	lsl   r2, r2, #1
	lsl   r5, r5, #1
	add   r5, r5, r4
	ldsh  r4, [r7, r5]
	tst	  r4, r4
	bpl	  loc_80D1188

	mvn   r4, r4
	bx    lr

loc_80D119E:
	ldmia r0!, {r2}
	add   r3, #32
	b     loc_80D118C

@ input:
@     r0 = SOURCE
@     r1 = (unused)
@     r2 = QUEUED DATA
@     r3 = QUEUED BIT COUNT
@     r4 = BITS TO READ
@
@ output:
@     r0 = SOURCE (advanced)
@     r1 = unchanged
@     r2 = QUEUED DATA
@     r3 = QUEUED BIT COUNT
@     r4 = READ DATA

decomp_read_bits:
	push  {r5-r6, lr}

	@ r5 and r6 are temp
	
	@ r5 = 32 - BIT READ COUNT (24?)
	mov   r5, #32
	sub   r5, r4     @ r5 = 32 - r4
	
	@ r6 = CURRENT DATA >> 
	mov   r6, r2
	lsr   r6, r5     @ r6 = data >> (32 - bit count)
	
	@ r3 = - bit overflow count (positive = no overflow)
	sub   r3, r4     @ r3 = r3 - r4 = bits left - bit count
	bmi   need_to_read_more

	lsl   r2, r4     @ r2 = data << bit count
	mov   r4, r6     @ r4 = data >> (32 - bit count)
	
	pop   {r5-r6, pc}

need_to_read_more:
	ldmia r0!, {r2}  @ r2 = next word
	
	neg   r5, r3     @ r5 = bit overflow count
	
	mov   r4, r2     @ r4 = next word
	lsl   r2, r5     @ r2 = next word << bit overflow count
	
	add   r3, #32    @ r3 = 32 - bit overflow count
	
	lsr   r4, r3     @ r4 = prev data >> (32 - bit overflow count)
	orr   r4, r6     @ r4 = data?
	
	pop   {r5-r6, pc}

.pool

@ This is just srand and rand... Why is that even here?

srand:
	ldr	r1, rand_constants+0x00
	str	r0, [r1]

	bx	lr

	.align 4

rand:
	adr   r0, rand_constants
	ldmia r0!, {r1-r3}
	
	@ r1 = gRandPrev address
	@ r2 = 1103515245
	@ r3 = 12345

	@ gRandPrev = gRandPrev * 1103515245 + 12345;
	ldr   r0, [r1]
	mul   r0, r2
	add   r0, r3
	str   r0, [r1]

	@ return gRandPrev & 0x7FFFFFFF
	lsl   r0, r0, #1
	lsr   r0, r0, #1

	bx    lr

.align 4

rand_constants:
	.long gRandPrev
	.long 1103515245
	.long 12345

decomp_pass1_type4:
	push {lr}
	mov  r6, r8 @ r6 = target + size - 2
	sub  r6, r1 @ r6 = size - 2

decomp_pass1_type4_loop:
	@ readbyte
	mov  lr, pc
	bx   r9
	
	@ r4 = byte read
	
	add  r1, #1
	
	@ Branch if odd
	lsl  r5, r1, #31
	bmi  decomp_pass1_type4_nowrite
	
	lsl  r4, #8
	add  r4, r10
	strh r4, [r1]

decomp_pass1_type4_nowrite:
	@ r10 = previous byte or halfword

	mov  r10, r4
	sub  r6, #1
	bne  decomp_pass1_type4_loop

	pop  {r4}
	bx   r4


decomp_pass1_default:
	push  {lr}
	mov   r5, #2
	bl    decomp_read_lz_readref @ does things to data at r7+4

	ldr   r4, =decomp_pass1_default_continue
	mov   r12, r4

decomp_pass1_default_loop:
	mov   r4, #2
	bl    decomp_read_bits

	cmp   r4, #2
	blo   loc_80D125C @ r4 = 0 or 1

	beq   loc_80D1274 @ r4 = 2

	@ r4 = 3

	mov   r4, #6
	bl    decomp_read_bits

	@ r4 = next 6 bits
	add   r6, r4, #1
	mov   r4, #8
	bl    decomp_read_bits

	add   r1, #1
	lsl   r5, r1, #31
	bmi   loc_80D1256

	@ this is a write
	lsls  r4, r4, #8
	add   r4, r10
	strh  r4, [r1]

loc_80D1256:
	mov   r10, r4
	movs  r5, #1
	b     decomp_apply_lz
	@ b decomp_pass1_default_continue

loc_80D125C: @ r4 = 0 or 1
	lsl   r5, r4, #2
	add   r5, r5, r7
	ldrb  r4, [r5, #6]
	bl    decomp_read_bits

	ldrh  r5, [r5,#4]
	add   r5, r5, r4
	
	@ read 6 bits
	mov   r4, #6
	bl    decomp_read_bits

	@ arg r6 = size
	add   r6, r4, #3
	b     decomp_apply_lz
	@ b decomp_pass1_default_continue

loc_80D1274: @ r4 = 2
	mov   r4, #6
	bl    decomp_read_bits

	add   r6, r4, #1

loc_80D127C:
	@ ReadByte
	mov   lr, pc
	bx    r9

	add   r1, #1
	lsl   r5, r1, #31
	bmi   loc_80D128C

	lsl   r4, r4, #8
	add   r4, r10
	strh  r4, [r1]

loc_80D128C:
	mov   r10, r4
	sub   r6, #1
	bne   loc_80D127C

decomp_pass1_default_continue:
	cmp   r1, r8
	blo   decomp_pass1_default_loop

	pop   {r4}
	bx    r4


decomp_pass1_type1:
	push  {lr}
	movs  r5, #4
	bl    decomp_read_lz_readref

	ldr   r4, =loc_80D12DE
	mov   r12, r4

loc_80D12A6:
	sub   r3, #1
	bmi   loc_80D12E6

loc_80D12AA:
	lsls  r2, r2, #1
	bcc   loc_80D12CC
	
	@ read bit is set
	
	@ read lz ref index
	movs  r4, #2
	bl    decomp_read_bits

	lsls  r5, r4, #2
	adds  r5, r5, r7
	
	@ read distance addition
	ldrb  r4, [r5,#6]
	bl    decomp_read_bits

	ldrh  r5, [r5,#4]
	adds  r5, r5, r4
	
	@ read size
	movs  r4, #4
	bl    decomp_read_bits

	adds  r6, r4, #3
	b     decomp_apply_lz

loc_80D12CC:
	@ read bit is cleared
	
	mov   lr, pc
	bx    r9

	adds  r1, #1
	lsls  r6, r1, #31
	
	bmi   loc_80D12DC
	lsls  r4, r4, #8
	add   r4, r10
	strh  r4, [r1]

loc_80D12DC:
	mov   r10, r4

loc_80D12DE:
	cmp   r1, r8
	blo   loc_80D12A6
	
	pop   {r4}
	bx    r4

loc_80D12E6:
	ldmia r0!, {r2}
	adds  r3, #0x20
	b     loc_80D12AA


decomp_pass1_type2:
	push  {lr}

	@ read 7 (!) lz read refs
	movs  r5, #7
	bl    decomp_read_lz_readref

	@ r12 = return address for lz application
	ldr   r4, =loc_80D1388
	mov   r12, r4

	@ BIT ADV BEGIN
loc_080D12F8:
	subs  r3, #1
	bmi   loc_80D1390

loc_80D12FC:
	lsls  r2, r2, #1
	bcc   loc_80D1376
	@ BIT ADV END
	
	@ bit was set

	movs  r4, #3
	bl    decomp_read_bits

	cmp   r4, #7
	beq   loc_80D1322

	lsls  r5, r4, #2
	adds  r5, r5, r7
	ldrb  r4, [r5, #6]
	bl    decomp_read_bits

	ldrh  r5, [r5, #4]
	adds  r5, r5, r4
	movs  r4, #4
	bl    decomp_read_bits

	adds  r6, r4, #3
	b     decomp_apply_lz

loc_80D1322:
	@ ref index was 7

	movs  r6, #0

loc_80D1324:
	movs  r4, #4
	bl    decomp_read_bits

	lsls  r6, r6, #4
	adds  r6, r6, r4
	lsrs  r6, r6, #1
	bcs   loc_80D1324

	@ BIT ADV START
	subs  r3, #1
	bmi   loc_80D1396

loc_80D1336:
	lsls  r2, r2, #1
	bcc   loc_80D135C
	@ BIT ADV END
	
	@ bit was set
	
	movs  r4, #3
	bl    decomp_read_bits

	lsls  r5, r4, #2
	adds  r5, r5, r7
	ldrb  r4, [r5, #6]
	bl    decomp_read_bits

	ldrh  r5, [r5, #4]
	adds  r5, r5, r4
	movs  r4, #4
	bl    decomp_read_bits

	lsls  r6, r6, #4
	adds  r6, r6, r4
	adds  r6, #3
	b     decomp_apply_lz

loc_80D135C:
	@ bit was cleared

	adds  r6, #1
	
loc_80D135E:
	mov   lr, pc
	bx    r9

	adds  r1, #1
	lsls  r5, r1, #31
	bmi   loc_80D136E

	lsls  r4, r4, #8
	add   r4, r10
	strh  r4, [r1]

loc_80D136E:
	mov   r10, r4
	subs  r6, #1
	bne   loc_80D135E

	b     loc_80D1388

loc_80D1376:
	@ bit was cleared

	mov   lr, pc
	bx    r9

	adds  r1, #1
	lsls  r5, r1, #31
	bmi   loc_80D1386

	lsls  r4, r4, #8
	add   r4, r10
	strh  r4, [r1]

loc_80D1386:
	mov   r10, r4

loc_80D1388:
	cmp   r1, r8
	blo   loc_080D12F8

	pop   {r4}
	bx    r4

loc_80D1390:
	ldmia r0!, {r2}
	add   r3, #0x20
	b     loc_80D12FC

loc_80D1396:
	ldmia r0!, {r2}
	add   r3, #0x20
	b     loc_80D1336


decomp_pass1_type3:
	push  {lr}

	@ read 3 ref things
	
	mov   r5, #3
	bl    decomp_read_lz_readref

loc_80D13A4:
	@ read a bit
	sub   r3, #1
	bmi   loc_80D1450

loc_80D13A8:
	lsl   r2, r2, #1
	bcs   loc_80D13C0
	@ end read a bit
	
	@ bit was clear

	mov   lr, pc
	bx    r9

	add   r5, r4, #0
	
	mov   lr, pc
	bx    r9
	
	lsl   r4, r4, #8
	orr   r4, r5
	add   r1, #2
	strh  r4, [r1]
	b     decomp_pass1_type3_continue

loc_80D13C0:
	@ bit was set
	mov   r4, #2
	bl    decomp_read_bits

	cmp   r4, #3
	beq   loc_80D13E4

	lsl   r5, r4, #2
	add   r5, r5, r7
	ldrb  r4, [r5,#6]
	bl    decomp_read_bits

	ldrh  r5, [r5, #4]
	add   r5, r5, r4
	lsl   r5, r5, #1
	mov   r4, #3
	bl    decomp_read_bits

	add   r6, r4, #2
	b     decomp_pass1_type3_hword_lz

loc_80D13E4:
	mov   r6, #0

loc_80D13E6:
	mov   r4, #3
	bl    decomp_read_bits

	lsl   r6, r6, #3
	add   r6, r6, r4
	lsr   r6, r6, #1
	bcs   loc_80D13E6

	@ read bit
	sub   r3, #1
	bmi   loc_80D1456

loc_80D13F8:
	lsl   r2, r2, #1
	bcc   loc_80D1420
	@ end read bit
	
	@ bit is set

	movs  r4, #2
	bl    decomp_read_bits

	lsl   r5, r4, #2
	add   r5, r5, r7
	ldrb  r4, [r5, #6]
	bl    decomp_read_bits

	ldrh  r5, [r5, #4]
	add   r5, r5, r4
	lsl   r5, r5, #1
	mov   r4, #3
	bl    decomp_read_bits

	lsl   r6, r6, #3
	add   r6, r6, r4
	add   r6, #2
	b     decomp_pass1_type3_hword_lz

loc_80D1420:
	@ bit is cleared
	add   r6, #1

loc_80D1422:
	mov   lr, pc
	bx    r9

	add   r5, r4, #0
	
	mov   lr, pc
	bx    r9
	
	lsl   r4, r4, #8
	add   r4, r4, r5
	add   r1, #2
	strh  r4, [r1]
	
	sub   r6, #1
	bne   loc_80D1422
	
	b     decomp_pass1_type3_continue

decomp_pass1_type3_hword_lz:
	sub   r5, r1, r5

loc_80D143C:
	add   r5, #2
	ldrh  r4, [r5]
	add   r1, #2
	strh  r4, [r1]
	sub   r6, #1
	bne   loc_80D143C

decomp_pass1_type3_continue:
	cmp   r1, r8
	bcc   loc_80D13A4

	pop   {r4}
	bx    r4

loc_80D1450:
	ldmia r0!, {r2}
	add   r3, #32
	b     loc_80D13A8

loc_80D1456:
	ldmia r0!, {r2}
	add   r3, #32
	b     loc_80D13F8


decomp_apply_lz:
	mov   lr, r12 @ ugh (return value in r12)

	push  {r2, lr}
	
	@ r2 is previous byte (?)
	mov   r2, r10
	cmp   r5, #1
	beq   loc_80D14C6

	lsl   r4, r5, #31
	bne   loc_80D1498

	@ r5 is even
	
	sub   r5, r1, r5
	lsl   r4, r5, #31
	beq   loc_80D1482

	add   r5, #1
	ldrh  r4, [r5]
	lsr   r4, r4, #8
	lsl   r4, r4, #8
	orr   r4, r2
	add   r1, #1
	strh  r4, [r1]
	sub   r6, #1
	beq   loc_80D1494

loc_80D1482:
	add   r5, #2
	ldrh  r4, [r5]
	add   r1, #2
	strh  r4, [r1]
	sub   r6, #2
	bgt   loc_80D1482

	lsl   r4, r4, #0x18
	lsr   r2, r4, #0x18
	add   r1, r1, r6

loc_80D1494:
	mov   r10, r2
	pop   {r2, pc}

loc_80D1498:
	@ r5 is odd
	
	sub   r5, r1, r5
	lsl   r4, r5, #31
	beq   loc_80D14AA

	@ r1 was even
	
	add   r5, #1
	ldrh  r2, [r5]
	lsr   r2, r2, #8
	add   r1, #1
	sub   r6, #1
	beq   loc_80D14C2

loc_80D14AA:
	sub   r1, #1

loc_80D14AC:
	add   r5, #2
	ldrh  r4, [r5]
	lsl   r4, r4, #8
	orr   r4, r2
	add   r1, #2
	strh  r4, [r1]
	lsr   r2, r4, #0x10
	sub   r6, #2
	bgt   loc_80D14AC

	add   r6, #1
	add   r1, r1, r6

loc_80D14C2:
	mov   r10, r2
	pop   {r2, pc}

loc_80D14C6:
	@ r5 = 1
	
	lsl   r4, r1, #31
	bpl   loc_80D14D4
	
	@ r1 is odd

	@ r4 = last byte twice
	lsl   r4, r2, #8
	orr   r4, r2
	
	@ r1++
	add   r1, #1
	
	@ r6++
	add   r6, #1
	b     loc_80D14DE

loc_80D14D4:
	@ r1 is even

	ldrh  r4, [r1]
	lsr   r4, r4,	#8
	lsl   r2, r4,	#8
	orr   r4, r2

loc_80D14DC:
	add   r1, #2

loc_80D14DE:
	strh  r4, [r1]
	sub   r6, #2
	bgt   loc_80D14DC

	lsr   r2, r4, #8
	add   r1, r1, r6

	mov   r10, r2
	pop   {r2, pc}

decomp_read_lz_readref:
	push  {r1, r7, lr}
	mov   r6, #1

loc_80D14F0:
	mov   r4, #4
	bl    decomp_read_bits

	add   r4, #1
	strb  r4, [r7, #6]
	strh  r6, [r7, #4]
	add   r7, #4
	mov   r1, #1
	lsl   r1, r4
	add   r6, r6, r1
	sub   r5, #1
	bne   loc_80D14F0

	pop   {r1, r7, pc}

.pool

decomp_pass2_type1:
	mov   r6, #0xF
	mov   r5, #0

	@ acc = 0
	@ while not at_end() do
	@ 	a, b, c, d = read_4_nibbles() -- a is 0-3, b is 4-7, c is 8-11, d is 12-15
	@	
	@	acc = b = b + acc
	@	acc = a = a + acc
	@	acc = d = d + acc
	@	acc = c = c + acc
	@	
	@	write_4_nibbles(a, b, c, d)
	@ end
	
	@ per byte equivalent:

	@ acc = 0
	@ while not at_end() do
	@	a, b = read_2_nibbles() -- a is 0-3, b is 4-7
	@	
	@	acc = b = b + acc
	@	acc = a = a + acc
	@	
	@	write_2_nibbles(a, b)
	@ end

decomp_pass2_type1_loop:
	ldrh  r2, [r0, #2]
	
	lsr   r1, r2, #4  @ r1 = word >> 4
	lsr   r3, r2, #12 @ r3 = word >> 12
	lsr   r4, r2, #8  @ r4 = word >> 8
	
	add   r1, r5      @ r1 = (word >> 4) + acc
	add   r2, r1      @ r2 = word + (word >> 4) + acc
	add   r3, r2      @ r3 = (word >> 12) + word + (word >> 4) + acc
	
	add   r5, r4, r3  @ acc = (word >> 8) + (word >> 12) + word + (word >> 4) + acc
	
	and   r1, r6      @ r1 = ((word >> 4) + acc) & 0xF
	and   r2, r6      @ r2 = (word + (word >> 4) + acc) & 0xF
	and   r5, r6      @ acc = ((word >> 8) + (word >> 12) + word + (word >> 4) + acc) & 0xF
	
	lsl   r1, #4      @ r1 = (((word >> 4) + acc) & 0xF) << 4
	lsl   r3, #12     @ r3 = ((word >> 12) + word + (word >> 4) + acc) << 12
	lsl   r4, r5, #8  @ r4 = (acc = ((word >> 8) + (word >> 12) + word + (word >> 4) + acc) & 0xF) << 8
	
	orr   r1, r2      @ r1 = (nibble0 | nibble4)
	orr   r1, r3      @ r1 = (nibble0 | nibble4 | nibble12)
	orr   r1, r4      @ r1 = (nibble0 | nibble4 | nibble12 | nibble8)
	
	strh  r1, [r0, #2]
	add   r0, #2
	
	cmp   r0, r8
	bcc   decomp_pass2_type1_loop

	bx	  lr


decomp_pass2_type2:
	mov   r5, #0xFF @ mask
	mov   r4, #0    @ acc

	@ acc = 0
	@ while not at_end() do
	@	a, b = read_2_bytes() -- a is [0-7], b is [8-15]
	@	
	@	acc = a = a + acc
	@	acc = b = b + acc
	@	
	@	write_2_bytes(a, b)
	@ end

decomp_pass2_type2_loop:
	ldrh  r2, [r0, #2]
	
	lsr   r3, r2, #8
	
	@ [0-7] += acc
	add   r2, r4
	
	@ [0-7] &= 0xFF
	and   r2, r5
	
	@ acc = [8-15] += [0-7]
	add   r4, r3, r2
	
	@ r1 = [0-7]:[8-15]
	lsl   r1, r4, #8
	orr   r1, r2
	
	@ *it++ = value
	strh  r1, [r0, #2]
	add   r0, #2

	cmp   r0, r8
	bcc   decomp_pass2_type2_loop

	bx	  lr


decomp_pass2_type3:
	mov   r4, #0 @ acc

	@ this one's easy
	
	@ acc = 0
	@ while not at_end() do
	@	a = read_hword()
	@	acc = a = a + acc
	@	write_hword(a)
	@ end

decomp_pass2_type3_loop:
	ldrh  r2, [r0, #2]
	
	add   r4, r2
	
	strh  r4, [r0, #2]
	add   r0, #2

	cmp	  r0, r8
	bcc	  decomp_pass2_type3_loop

	bx	  lr


decomp_pass2_type4:
	mov   r3, #0xFF  @ r3 = 00FF
	lsl   r6, r3, #8 @ r6 = FF00

	mov   r4, #0 @ loAcc
	mov   r5, #0 @ hiAcc
	
	@ loAcc = 0
	@ hiAcc = 0
	@ while not at_end() do
	@	a, b = read_2_bytes() -- a is [0-7], b is [8-15]
	@	
	@	loAcc = a = a + loAcc
	@	hiAcc = b = b + hiAcc
	@	
	@	write_2_bytes(a, b)
	@ end

decomp_pass2_type4_loop:
	ldrh  r2, [r0, #2]
	
	@ loAcc = (value + loAcc) & 00FF
	add   r4, r4, r2
	and   r4, r3
	
	@ hiAcc = (value + hiAcc) & FF00
	add   r5, r5, r2
	and   r5, r6
	
	@ value = loAcc | hiAcc
	mov   r1, r5
	orr   r1, r4
	
	@ store
	strh  r1, [r0, #2]
	add   r0, #2

	cmp  r0, r8
	bcc  decomp_pass2_type4_loop

	bx   lr
