#!/usr/bin/python3

import sys, os

def read_int(input, byteCount, signed = False):
	return int.from_bytes(input.read(byteCount), byteorder = 'little', signed = signed)

CODE_NAME_TABLE = {
	0x00: "nop",
	0x01: "equ",
	0x02: "addequ",
	0x03: "subequ",
	0x04: "mulequ",
	0x05: "divequ",
	0x06: "modequ",
	0x07: "add",
	0x08: "sub",
	0x09: "mul",
	0x0A: "div",
	0x0B: "mod",
	0x0C: "and",
	0x0D: "or",
	0x0E: "inc",
	0x0F: "dec",
	0x10: "neg",
	0x11: "not",
	0x12: "cmp",
	0x13: "pushm",
	0x14: "popm",
	0x15: "dup",
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
	0x21: "call",
	0x22: "push16",
	0x23: "push8",
	0x24: "switch"
}

CODE_IMM_SIZE_TABLE = {
	0x13: 4, # push [A]
	0x14: 4, # pop [A]
	0x17: 4, # push imm32
	0x22: 2, # push imm16
	0x23: 1, # push imm8
	0x18: 4, # b label
	0x19: 4, # blt label
	0x1A: 4, # ble label
	0x1B: 4, # beq label
	0x1C: 4, # bne label
	0x1D: 4, # bge label
	0x1E: 4, # bgt label
	0x21: 4, # call id
	0x24: 4, # switch id
}

def script_ops(file, baseOffset):
	file.seek(baseOffset)

	riff = read_int(file, 4)
	size = read_int(file, 4)
	name = read_int(file, 4)

	offset = 4

	while offset < size:
		chunk = file.read(4)
		cSize = read_int(file, 4)

		offset = offset + 8

		if chunk == b"CODE":
			i = 4
			read_int(file, 4) # we don't care

			while i < cSize:
				pc   = i - 4
				code = read_int(file, 1)

				i = i + 1

				cId = code & 0x7F
				cAd = (code & 0x80) != 0

				imm = None

				if cId in CODE_IMM_SIZE_TABLE:
					imm = read_int(file, CODE_IMM_SIZE_TABLE[cId])
					i = i + CODE_IMM_SIZE_TABLE[cId]

				yield (cId, cAd, imm, pc)

		offset = offset + cSize
		file.seek(baseOffset + offset + 8)

def script_lines(file, baseOffset):
	file.seek(baseOffset)

	riff = read_int(file, 4)
	size = read_int(file, 4)
	name = read_int(file, 4)

	offset = 4

	while offset < size:
		chunk = file.read(4)
		cSize = read_int(file, 4)

		offset = offset + 8

		if chunk == b"CODE":
			i = 4
			read_int(file, 4) # we don't care

			while i < cSize:
				pc   = i - 4
				code = read_int(file, 1)

				i = i + 1

				cId = code & 0x7F
				cAd = (code & 0x80) != 0

				imm = None

				if cId in CODE_IMM_SIZE_TABLE:
					imm = read_int(file, CODE_IMM_SIZE_TABLE[cId])
					i = i + CODE_IMM_SIZE_TABLE[cId]

				yield "{:04X} {} {}{}".format(
					pc,
					CODE_NAME_TABLE[cId] if cId in CODE_NAME_TABLE else 'err',
					'X+' if cAd and imm != None else '',
					'0x{:X}'.format(imm) if imm != None else '')

		offset = offset + cSize
		file.seek(baseOffset + offset + 8)

def main(args):
	romFile   = ''
	romOffset = 0
	scrEntry  = 0

	try:
		romFile   = args[1]
		romOffset = int(args[2], base = 0) & 0x1FFFFFF
		scrEntry  = int(args[3], base = 0)

	except IndexError:
		sys.exit("usage: [python3] {} <rom file> <table offset> <entry>".format(args[0]))

	if True:
		with open(romFile, 'rb') as f:
			for iScr in range(scrEntry):
				f.seek(romOffset + 4*iScr)
				scrOffset = read_int(f, 4) & 0x1FFFFFF

				if scrOffset != 0:
					hasLoop   = False
					hasSwitch = False
					lastOff   = 0

					for op, x, imm, off in script_ops(f, scrOffset):
						if op >= 0x18 and op <= 0x1E: # call
							if imm < off:
								hasLoop = True

						if op == 0x24:
							hasSwitch = True

						lastOff = off

					if hasLoop or hasSwitch:
						print("{:03X}: size={:X}, loop={}, switch={}".format(iScr, lastOff+1, hasLoop, hasSwitch))

	if False:
		# print offsets

		with open(romFile, 'rb') as f:
			for iScr in range(scrEntry):
				f.seek(romOffset + 4*iScr)
				scrOffset = read_int(f, 4)

				print("{:03X}: {:08X}".format(iScr, scrOffset))

	if False:
		# print script

		with open(romFile, 'rb') as f:
			f.seek(romOffset + 4*scrEntry)
			scrOffset = read_int(f, 4) & 0x1FFFFFF

			if scrOffset != 0:
				print('SCR: 0x{:X}'.format(scrOffset + 0x8000000))

				for line in script_lines(f, scrOffset):
					print(line)

	if False:
		# print op/fn stats

		opStats = {}
		fnStats = {}

		for i in range(0x25):
			opStats[i] = []

		for i in range(339):
			fnStats[i] = []

		with open(romFile, 'rb') as f:
			for iScr in range(scrEntry):
				f.seek(romOffset + 4*iScr)
				scrOffset = read_int(f, 4) & 0x1FFFFFF

				if scrOffset != 0:
					for op, x, imm, off in script_ops(f, scrOffset):
						if not (iScr in opStats[op]):
							opStats[op].append(iScr)

						if op == 0x21: # call
							if not (iScr in fnStats[imm]):
								fnStats[imm].append(iScr)

		for i in range(339):
			# name = CODE_NAME_TABLE[i]
			print('{:03X}: {}'.format(i, fnStats[i]))

if __name__ == '__main__':
	main(sys.argv)
