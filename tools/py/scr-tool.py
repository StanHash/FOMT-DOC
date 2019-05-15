#!/usr/bin/python3

import sys, os

def read_int(input, byteCount, signed = False):
	return int.from_bytes(input.read(byteCount), byteorder = 'little', signed = signed)

CODE_NAME_TABLE = {
	0x00: "nop",
	0x01: "store",
	0x02: "addm",
	0x03: "subm",
	0x04: "mulm",
	0x05: "divm",
	0x06: "modm",
	0x07: "add",
	0x08: "sub",
	0x09: "mul",
	0x0A: "div",
	0x0B: "mod",
	0x0C: "land",
	0x0D: "lorr",
	0x0E: "inc",
	0x0F: "dec",
	0x10: "neg",
	0x11: "lnot",
	0x12: "cmp",
	0x13: "pushm",
	0x14: "popm",
	0x15: "dupe",
	0x16: "pop",
	0x17: "push",
	0x18: "b",
	0x19: "blt",
	0x1A: "ble",
	0x1B: "beq",
	0x1C: "bne",
	0x1D: "bge",
	0x1E: "bgt",
	0x1F: "bi",
	0x20: "end",
	0x21: "sys",
	0x22: "push16",
	0x23: "push8",
	0x24: "switch"
}

CODE_IMM_SIZE_TABLE = {
	0x13: 4, # push indirect
	0x14: 4, # pop
	0x17: 4, # push imm32
	0x22: 2, # push imm16
	0x23: 1, # push imm8
	0x18: 4, # b
	0x19: 4, # blt
	0x1A: 4, # ble
	0x1B: 4, # beq
	0x1C: 4, # bne
	0x1D: 4, # bge
	0x1E: 4, # bgt
	0x21: 4, # user
	0x24: 4, # switch
}

def main(args):
	romFile   = ''
	romOffset = 0

	try:
		romFile   = args[1]
		romOffset = int(args[2], base = 0) & 0x1FFFFFF

	except IndexError:
		sys.exit("usage: [python3] {} <rom file> <offset>".format(args[0]))

	with open(romFile, 'rb') as f:
		f.seek(romOffset)

		riff = read_int(f, 4)
		size = read_int(f, 4)
		name = read_int(f, 4)

		offset = 4

		while offset < size:
			chunk = f.read(4)
			cSize = read_int(f, 4)

			offset = offset + 8

			print('CHUNK {:04X} {}'.format(cSize, chunk))

			if chunk == b"CODE":
				i = 4
				read_int(f, 4) # we don't care

				while i < cSize:
					pc   = i - 4
					code = read_int(f, 1)

					i = i + 1

					cId = code & 0x7F
					cAd = (code & 0x80) != 0

					imm = None

					if cId in CODE_IMM_SIZE_TABLE:
						imm = read_int(f, CODE_IMM_SIZE_TABLE[cId])
						i = i + CODE_IMM_SIZE_TABLE[cId]

					print("{:04X} {} {}{}".format(
						pc,
						CODE_NAME_TABLE[cId] if cId in CODE_NAME_TABLE else 'err',
						'Y+' if cAd and imm != None else '',
						'${:X}'.format(imm) if imm != None else ''))

			offset = offset + cSize
			f.seek(romOffset + offset + 8)

if __name__ == '__main__':
	main(sys.argv)
