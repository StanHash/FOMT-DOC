#!/usr/bin/python3

import sys, os
import png

def read_int(input, byteCount, signed = False):
	return int.from_bytes(input.read(byteCount), byteorder = 'little', signed = signed)

class GlyphBase:
	COLOR_CHARS  = ['  ', '██']

	COLOR_VALUES = [
		(0,   0,   0),
		(255, 255, 255),
	]

	def __init__(self):
		self.pixels = [0 for i in range(self.WIDTH * self.HEIGHT)]

	def compute_effective_length(self):
		result = 0

		for iy in range(self.HEIGHT):
			linelen = 0

			for ix in range(self.WIDTH):
				if self.pixels[ix + self.WIDTH * iy] == 0:
					continue

				if linelen < ix:
					linelen = ix + 1

			if result < linelen:
				result = linelen

		return result

	def __repr__(self):
		result = ''

		for iy in range(self.HEIGHT):
			for ix in range(self.WIDTH):
				result += self.COLOR_CHARS[self.pixels[ix + self.WIDTH * iy]]

			result += '\n'

		return result

class Glyph1Tile(GlyphBase):
	WIDTH  = 8
	HEIGHT = 12

	def read_from_file(self, file):
		for iy in range(self.HEIGHT):
			line = read_int(file, 1)

			for ix in range(self.WIDTH):
				self.pixels[ix + self.WIDTH * iy] = 1 & (line >> (7 - ix))

class Glyph2Tile(GlyphBase):
	WIDTH  = 16
	HEIGHT = 12

	def read_from_file(self, file):
		for iy in range(self.HEIGHT):
			line1 = read_int(file, 1)
			line2 = read_int(file, 1)

			for ix in range(self.WIDTH // 2):
				self.pixels[ix + self.WIDTH * iy]                   = 1 & (line1 >> (7 - ix))
				self.pixels[ix + self.WIDTH * iy + self.WIDTH // 2] = 1 & (line2 >> (7 - ix))

class CheapBitmap:

	def __init__(self, width, height):
		self.width = width
		self.height = height

		self.rows = [[0 for ix in range(width)] for iy in range(height)]

	def clear(self):
		for iy in range(self.height):
			for ix in range(self.width):
				self.rows[iy][ix] = 0

def make_glyph_sheet_rows(glyphs, glyphPerRow = 16):
	bitmap = CheapBitmap(glyphPerRow * glyphs[0].WIDTH, glyphs[0].HEIGHT)
	col = 0

	for glyph in glyphs:
		for iy in range(glyph.HEIGHT):
			for ix in range(glyph.WIDTH):
				bitmap.rows[iy][col * glyph.WIDTH + ix] = glyph.pixels[ix + glyph.WIDTH * iy]

		col += 1

		if col >= glyphPerRow:
			for row in bitmap.rows:
				yield row

			col = 0
			bitmap.clear()

	if col != 0:
		for row in bitmap.rows:
			yield row

def write_glyph_sheet_to_png(glyphs, pngFileName, glyphPerRow = 16):
	rowCount = (len(glyphs) + glyphPerRow - 1) // glyphPerRow

	pngWriter = png.Writer(
		size = (glyphPerRow * glyphs[0].WIDTH, rowCount * glyphs[0].HEIGHT),
		palette = glyphs[0].COLOR_VALUES
	)

	with open(pngFileName, 'wb') as file:
		pngWriter.write(file, make_glyph_sheet_rows(glyphs, glyphPerRow))

if __name__ == '__main__':
	if len(sys.argv) < 6:
		sys.exit("usage: (pyhton3) {} <ROM> <offset> <type (1/2)> <count> <PNG>".format(sys.argv[0]))

	# $0171 glyphs for 1 tile characters (?)
	# $1B0A glyphs for 2 tile characters (!)

	rom        = sys.argv[1]
	offset     = int(sys.argv[2], base = 0) & 0x1FFFFFF
	glyphType  = int(sys.argv[3])
	glyphCount = int(sys.argv[4], base = 0)
	outFile    = sys.argv[5]

	if rom == outFile:
		sys.exit(":(")

	if glyphType == 1:
		glyphClass = Glyph1Tile
	elif glyphType == 2:
		glyphClass = Glyph2Tile
	else:
		sys.exit("Invalid glyph type id {}".format(glyphType))

	glyphs = []

	with open(rom, 'rb') as file:
		for i in range(glyphCount):
			file.seek(offset + (glyphClass.WIDTH * glyphClass.HEIGHT // 8) * i)

			glyph = glyphClass()
			glyph.read_from_file(file)

			glyphs.append(glyph)

	write_glyph_sheet_to_png(glyphs, outFile)
