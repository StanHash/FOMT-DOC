#/usr/bin/python3

import sys, os
import png

def read_int(input, byteCount, signed = False):
	return int.from_bytes(input.read(byteCount), byteorder = 'little', signed = signed)

def short_to_color(value):
	if value == 0:
		return (0, 0, 0)

	return (
		8*(0x1F & (value)),
		8*(0x1F & (value >> 5)),
		8*(0x1F & (value >> 10))
	)

def color_to_short(color):
	if color[4] == 0:
		return 0

	return ((0xFF & color[0])>>3) | (((0xFF & color[1])>>3)<<5) | (((0xFF & color[2])>>3)<<10)

def pool_range_iter(pool, rng):
	for i in range(rng[1]):
		yield pool[rng[0] + i]

class GBAPalette:
	def __init__(self):
		self.colors = []

	def read_from_file(self, input, count = 16):
		for _ in range(count):
			self.colors.append(short_to_color(read_int(input, 2)))

	def get_color(self, index):
		return self.colors[index]

	def color_count(self):
		return len(self.colors)

	def palette_bank_count(self):
		return (self.color_count() + 15) // 0x10

class GBATile:

	WIDTH  = 8
	HEIGHT = 8

	def __init__(self):
		self.pixels  = [0 for i in range(self.WIDTH * self.HEIGHT)]
		self.palette = None

	def read_from_file(self, input):
		for iy in range(self.HEIGHT):
			line = read_int(input, 4)

			for ix in range(self.WIDTH):
				self.pixels[ix + self.WIDTH * iy] = 0xF & (line >> (ix*4))

	def get_pixel(self, x, y):
		return self.pixels[x + self.WIDTH * y]

	def __repr__(self):
		result = ''

		for iy in range(self.HEIGHT):
			for ix in range(self.WIDTH):
				result += '{:X} '.format(self.pixels[ix + self.WIDTH * iy])

			result += '\n'

		return result

class GBAOAM:

	SIZE_LOOKUP = [
		(8,  8),
		(16, 16),
		(32, 32),
		(64, 64),

		(16, 8),
		(32, 8),
		(32, 16),
		(64, 32),

		(8,  16),
		(8,  32),
		(16, 32),
		(32, 64),
	]

	def __init__(self, oamTuple = (0, 0, 0)):
		self.oam = oamTuple

	def get_x(self):
		return 0x1FF & self.oam[1]

	def get_y(self):
		return 0x0FF & self.oam[0]

	def get_tile(self):
		return 0x3FF & self.oam[2]

	def get_palette(self):
		return 0x00F & (self.oam[2] >> 12)

	def get_shape_id(self):
		return 0x3 & (self.oam[0] >> 14)

	def get_size_id(self):
		return 0x3 & (self.oam[1] >> 14)

	def get_size(self):
		return self.SIZE_LOOKUP[self.get_size_id() | (self.get_shape_id() << 2)]

	def get_tile_size(self):
		size = self.get_size()
		return (size[0] // 8, size[1] // 8)

	def get_tile_count(self):
		size = self.get_tile_size()
		return size[0] * size[1]

	# TODO: affine stuff and whatnot

class FOMTSpriteData:

	def __init__(self):
		self.animations = [] # animRange (range = tuple<int start, int length>)
		self.frames     = [] # tuple<oamRange, tileRange, colorRange, affineRange>
		self.oamPool    = [] # 
		self.tilePool   = [] # GBATile[]
		self.colorPool  = [] # GBAPalette[]
		self.affinePool = [] # 
		self.animPool   = [] #

	def read_from_file(self, input):
		def read_range(input):
			length = read_int(input, 2)
			start  = read_int(input, 2)

			return (start, length)

		animCount = read_int(input, 4)

		for _ in range(animCount):
			self.animations.append(read_range(input))

		frameCount = read_int(input, 4)

		for _ in range(frameCount):
			oamRange    = read_range(input)
			tileRange   = read_range(input)
			colorRange  = read_range(input)
			affineRange = read_range(input)

			self.frames.append((oamRange, tileRange, colorRange, affineRange))

		oamCount = read_int(input, 4)

		for _ in range(oamCount):
			oam0 = read_int(input, 2)
			oam1 = read_int(input, 2)
			oam2 = read_int(input, 2)

			read_int(input, 2) # padding

			self.oamPool.append((oam0, oam1, oam2))

		tileCount = read_int(input, 4)

		for _ in range(tileCount):
			tile = GBATile()
			tile.read_from_file(input)

			self.tilePool.append(tile)

		paletteCount = read_int(input, 4)

		for _ in range(paletteCount):
			palette = GBAPalette()
			palette.read_from_file(input)

			self.colorPool.append(palette)

		affineCount = read_int(input, 4)

		for _ in range(affineCount):
			pa = read_int(input, 2)
			pb = read_int(input, 2)
			pc = read_int(input, 2)
			pd = read_int(input, 2)

			self.affinePool.append((pa, pb, pc, pd))

		animInsrCount = read_int(input, 4)

		for _ in range(animInsrCount):
			frame = read_int(input, 2)
			time  = read_int(input, 2)

			self.animPool.append((frame, time))

class CheapBitmap:

	def __init__(self, width, height):
		self.width  = width
		self.height = height

		self.rows = [[0 for ix in range(width)] for iy in range(height)]

	def clear(self):
		for iy in range(self.height):
			for ix in range(self.width):
				self.rows[iy][ix] = 0

if __name__ == '__main__':
	if len(sys.argv) < 4:
		sys.exit("usage: (pyhton3) {} <ROM> <offset> <PNG>".format(sys.argv[0]))

	rom         = sys.argv[1]
	offset      = int(sys.argv[2], base = 0) & 0x1FFFFFF
	pngFileBase = sys.argv[3]

	with open(rom, 'rb') as file:
		file.seek(offset)

		spriteData = FOMTSpriteData()
		spriteData.read_from_file(file)

		if len(spriteData.frames) < 1:
			sys.exit("Sprite has no frames!")

		iFrame = 0

		for frame in spriteData.frames:
			iObj = 0

			for oamTuple in pool_range_iter(spriteData.oamPool, frame[0]):
				oam    = GBAOAM(oamTuple = oamTuple)
				size   = oam.get_size()
				bitmap = CheapBitmap(size[0], size[1])

				tileRange = (frame[1][0] + oam.get_tile(), oam.get_tile_count())
				tileIter  = pool_range_iter(spriteData.tilePool, tileRange)

				for ty in range(size[1] // 8):
					for tx in range(size[0] // 8):
						tile = next(tileIter)

						for ix in range(tile.WIDTH):
							for iy in range(tile.HEIGHT):
								bitmap.rows[ty*8+iy][tx*8+ix] = tile.get_pixel(ix, iy)

				pngWriter = png.Writer(
					size = (bitmap.width, bitmap.height),
					palette = spriteData.colorPool[frame[2][0] + oam.get_palette()].colors
				)

				with open('{}.{}.{}.png'.format(pngFileBase, iFrame, iObj), 'wb') as file:
					pngWriter.write(file, bitmap.rows)

				iObj = iObj + 1

			iFrame = iFrame + 1
