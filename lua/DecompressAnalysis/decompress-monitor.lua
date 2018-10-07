
-- HUFFMAN TREE

huffman_mt = {

	is_leaf = function(node)
		return (node.value ~= nil)
	end,
	
	child = function(node, which)
		if not node[which] then
			node[which] = new_huffman_tree()
		end
		
		return node[which]
	end,
	
	get = function(node)
		return node.value
	end,
	
	decode = function(node, bitGetter)
		if node:is_leaf() then
			return node:get()
		end
		
		return node:child(bitGetter()):decode(bitGetter)
	end

}

function new_huffman_tree()
	local result = {}
	return setmetatable(result, huffman_mt)
end

hufftree = {
	
	root = function()
		return {}
	end,
	
	leaf = function(aValue)
		return {
			value = aValue
		}
	end,
	
	node = function(aLeft, aRight)
		return {
			left  = aLeft,
			right = aRight
		}
	end,
	
	child = function(aNode, index)
		if not aNode   then return end
		if aNode.value then return end
		
		if index == 0 then
			return aNode.left
		elseif index == 1 then
			return aNode.right
		else
			return
		end
	end,
	
	set_child = function(aNode, index, aChild)
		if not aNode   then return end
		if aNode.value then return end
		
		if index == 0 then
			aNode.left  = aChild
		elseif index == 1 then
			aNode.right = aChild
		end
	end,
	
	print_values = function(aRoot)
		hufftree.print_values_recursive(aRoot, 0, 0)
	end,
	
	print_values_recursive = function(aNode, path, depth)
		if not aNode then return end
		
		if aNode.value then
			print(string.format("%X(%d) -> %X", path, depth, aNode.value))
		else
			hufftree.print_values_recursive(aNode.left,  bit.lshift(path, 1),     depth + 1)
			hufftree.print_values_recursive(aNode.right, bit.lshift(path, 1) + 1, depth + 1)
		end
	end
	
}

decompress = {

	passTable = {
		huffman = {
			[0] = function(state) -- 0 is also default
				state.readByte = decompress.read_byte_raw
			end,
			
			[1] = function(state)
				decompress.read_huffman_tree(state, 4)
				state.readByte = decompress.read_byte_huff4
			end,
			
			[2] = function(state)
				decompress.read_huffman_tree(state, 8)
				state.readByte = decompress.read_byte_huff8
			end
		},
		
		decomp = {
			[0] = function(state) -- 0 is also default
				decompress.read_lz_lookup_ladder(state, 2)
				
				while not decompress.at_end(state) do
					local i = decompress.read_bits(state, 2)
					
					if i < 2 then
						local distance = state.lzLadder[i + 1].offset + decompress.read_bits(state, state.lzLadder[i + 1].bits)
						local size     = decompress.read_bits(state, 6) + 3
						
						decompress.apply_lz_bytes(state, distance, size)
					elseif i == 2 then
						local count = decompress.read_bits(state, 6) + 1
						
						for j = 1, count do
							decompress.write_byte(state, state:readByte())
						end
					elseif i == 3 then
						local size = decompress.read_bits(state, 6) + 1
						
						decompress.write_byte(state, decompress.read_bits(state, 8))
						decompress.apply_lz_bytes(state, 1, size)
					else
						error("bad read")
					end
				end
			end,
			
			[1] = function(state)
				decompress.read_lz_lookup_ladder(state, 4)
				
				while not decompress.at_end(state) do
					if decompress.read_bit(state) == 0 then
						-- bit was clear
						
						decompress.write_byte(state, state:readByte())
					else
						-- bit was set
						
						local i = decompress.read_bits(state, 2)
						
						local distance = state.lzLadder[i + 1].offset + decompress.read_bits(state, state.lzLadder[i + 1].bits)
						local size     = decompress.read_bits(state, 4) + 3
						
						decompress.apply_lz_bytes(state, distance, size)
					end
				end
			end,
			
			[2] = function(state)
				decompress.read_lz_lookup_ladder(state, 7)
				
				while not decompress.at_end(state) do
					if decompress.read_bit(state) == 0 then
						-- bit was clear
						
						decompress.write_byte(state, state:readByte())
					else
						-- bit was set
						
						local i = decompress.read_bits(state, 3)
						
						if i < 7 then
							local distance = state.lzLadder[i + 1].offset + decompress.read_bits(state, state.lzLadder[i + 1].bits)
							local size     = decompress.read_bits(state, 4) + 3
							
							decompress.apply_lz_bytes(state, distance, size)
						elseif i == 7 then
							local count = 0
							local value = 0
							
							repeat
								value = decompress.read_bits(state, 4)
								count = bit.bor(bit.lshift(count, 3), bit.rshift(value, 1))
							until (bit.band(value, 1) == 0)
							
							if decompress.read_bit(state) == 0 then
								-- bit was clear
								
								for _ = 1, count + 1 do
									decompress.write_byte(state, state:readByte())
								end
							else
								-- bit was set
								
								local j = decompress.read_bits(state, 3)
								
								local distance = state.lzLadder[j + 1].offset + decompress.read_bits(state, state.lzLadder[j + 1].bits)
								local size     = decompress.read_bits(state, 4) + bit.lshift(count, 4) + 3
								
								decompress.apply_lz_bytes(state, distance, size)
							end
						else
							error("bad read")
						end
					end
				end
			end,
			
			[3] = function(state)
				decompress.read_lz_lookup_ladder(state, 3)
				
				while not decompress.at_end(state) do
					if decompress.read_bit(state) == 0 then
						-- bit was clear
						
						decompress.write_byte(state, state:readByte())
						decompress.write_byte(state, state:readByte())
					else
						-- bit was set
						
						local i = decompress.read_bits(state, 2)
						
						if i < 3 then
							local distance = state.lzLadder[i + 1].offset + decompress.read_bits(state, state.lzLadder[i + 1].bits)
							local size     = decompress.read_bits(state, 3) + 2
							
							decompress.apply_lz_2bytes(state, distance, size)
						elseif i == 3 then
							local count = 0
							local value = 0
							
							repeat
								value = decompress.read_bits(state, 3)
								count = bit.bor(bit.lshift(count, 2), bit.rshift(value, 1))
							until (bit.band(value, 1) == 0)
							
							if decompress.read_bit(state) == 0 then
								-- bit was clear
								
								for _ = 1, (count + 1) do
									decompress.write_byte(state, state:readByte())
									decompress.write_byte(state, state:readByte())
								end
							else
								-- bit was set
								
								local j = decompress.read_bits(state, 2)
								
								local distance = state.lzLadder[j + 1].offset + decompress.read_bits(state, state.lzLadder[j + 1].bits)
								local size     = decompress.read_bits(state, 3) + bit.lshift(count, 3) + 2
								
								decompress.apply_lz_2bytes(state, distance, size)
							end
						else
							error("bad read")
						end
					end
				end
			end,
			
			[4] = function(state)
				while not decompress.at_end(state) do
					decompress.write_byte(state, state:readByte())
				end
			end
		},
		
		filter = {
			[0] = function(state) -- 0 is also default
				-- do nothing
			end,
			
			[1] = function(state)
				local acc = 0
				
				for i = 1, #state.data do
					local a = bit.band(state.data[i], 0xF)
					local b = bit.rshift(state.data[i], 4)
					
					-- acc = b = b + acc
					b   = bit.band(b + acc, 0xF)
					acc = b
					
					-- acc = a = a + acc
					a   = bit.band(a + acc, 0xF)
					acc = a
					
					state.data[i] = bit.bor(a, bit.lshift(b, 4))
				end
			end,
			
			[2] = function(state)
				local acc = 0
				
				for i = 1, #state.data do
					acc = bit.band(state.data[i] + acc, 0xFF)
					state.data[i] = acc
				end
			end,
			
			[3] = function(state)
				local acc = 0
				
				for i = 1, #state.data, 2 do
					local value = bit.bor(state.data[i], bit.lshift(state.data[i + 1], 8))
					
					value = bit.band(value + acc, 0xFFFF)
					acc   = value
					
					state.data[i]     = bit.band(value, 0xFF)
					state.data[i + 1] = bit.band(bit.rshift(value, 8), 0xFF)
				end
			end,
			
			[4] = function(state)
				local loAcc = 0
				local hiAcc = 0
				
				for i = 1, #state.data, 2 do
					local a = state.data[i]
					local b = state.data[i + 1]
					
					a     = bit.band(a + loAcc, 0xFF)
					loAcc = a
					
					b     = bit.band(b + hiAcc, 0xFF)
					hiAcc = b
					
					state.data[i]     = a
					state.data[i + 1] = b
				end
			end
		}
	},

	start = function(apSource, apTarget) 
		return {
			pSource = apSource,   -- 'real' input
			pTarget = apTarget,   -- 'real' output
			
			pSourceIt = apSource, -- next input address
			data = {},            -- output
			
			readBits = 0,         -- bits in read buffer
			readBuff = 0,         -- read buffer
			
			readByte = nil,       -- byte reading function
			
			targetSize = -1,      -- size of target after decompression
			
			huffType = -1,        -- type identifier for huffman coding
			compType = -1,        -- type identifier for compression
			filtType = -1,        -- type identifier for post-compression filtering
			
			huffman = {},         -- huffman tree
			lzLadder = {}         -- lz lookup ladder data
		}
	end,
	
	read_bits = function(state, bitCount)
		local data = bit.rshift(state.readBuff, 32 - bitCount)
		state.readBits = state.readBits - bitCount
		
		if state.readBits < 0 then
			local newRead = memory.readlong(state.pSourceIt)
			state.pSourceIt = state.pSourceIt + 4
			
			state.readBuff = bit.lshift(newRead, -state.readBits)
			state.readBits = state.readBits + 32
			
			return bit.bor(data, bit.rshift(newRead, state.readBits))
		end
		
		state.readBuff = bit.lshift(state.readBuff, bitCount)
		return data
	end,
	
	read_bit = function(state)
		state.readBits = state.readBits - 1
		
		if state.readBits < 0 then
			state.readBuff  = memory.readlong(state.pSourceIt)
			state.pSourceIt = state.pSourceIt + 4
			
			state.readBits  = state.readBits + 32
		end
		
		local result   = bit.rshift(state.readBuff, 31)
		state.readBuff = bit.lshift(state.readBuff, 1)
		
		return result
	end,

	write_byte = function(state, value)
		state.data[#state.data + 1] = bit.band(value, 0xFF)
	end,
	
	write_hword = function(state, value)
		state.data[#state.data + 1] = bit.band(value, 0xFF)
		state.data[#state.data + 1] = bit.band(bit.rshift(value, 8), 0xFF)
	end,
	
	at_end = function(state)
		return (#state.data >= state.targetSize)
	end,
	
	check_decomp = function(state)
		for i = 0, (state.targetSize - 1) do
			local realByte = memory.readbyte(state.pTarget + i)
			local dataByte = state.data[i + 1]
			
			if realByte ~= dataByte then
				return false
			end
		end
		
		return true
	end,
	
	read_header = function(state)
		state.targetSize = bit.rshift(decompress.read_bits(state, 32), 8)
		
		local typeByte = decompress.read_bits(state, 8)
		
		state.compType = bit.band(typeByte, 0x7)
		state.huffType = bit.band(bit.rshift(typeByte, 3), 0x3)
		state.filtType = bit.band(bit.rshift(typeByte, 5), 0x7)
	end,
	
	huffman_pass = function(state)
		local func = decompress.passTable.huffman[state.huffType]
		
		if not func then
			func = decompress.passTable.huffman[0]
		end
		
		func(state)
	end,
	
	decomp_pass = function(state)
		local func = decompress.passTable.decomp[state.compType]
		
		if not func then
			func = decompress.passTable.decomp[0]
		end
		
		func(state)
	end,
	
	filter_pass = function(state)
		local func = decompress.passTable.filter[state.filtType]
		
		if not func then
			func = decompress.passTable.filter[0]
		end
		
		func(state)
	end,
	
	read_huffman_tree = function(state, bits)
		local currentNodePath = 0

		for i = 0, (bits*2-1) do -- idk about that bits*2
			local count = decompress.read_bits(state, bits)
			
			currentNodePath = bit.lshift(currentNodePath, 1)
			
			-- print(string.format("%X %X %X", i, count, currentNodePath))

			for _ = 1, count do
				local node = state.huffman -- root

				for j = i, 1, -1 do
					local huffBit = bit.band(bit.rshift(currentNodePath, j), 1)
					local child = hufftree.child(node, huffBit)
					
					if not child then
						child = {}
						hufftree.set_child(node, huffBit, child)
					end
					
					node = child
				end

				hufftree.set_child(node, bit.band(currentNodePath, 1), hufftree.leaf(decompress.read_bits(state, bits)))
				currentNodePath = currentNodePath + 1
			end
		end
		
		-- hufftree.print_values(state.huffman)
	end,
	
	read_byte_huff4 = function(state)
		local result = 0
		
		result = bit.bor(result, bit.lshift(decompress.read_huff_chunk(state), 4))
		result = bit.bor(result, decompress.read_huff_chunk(state))
		
		return result
	end,
	
	read_byte_huff8 = function(state)
		return decompress.read_huff_chunk(state)
	end,
	
	read_byte_raw = function(state)
		return decompress.read_bits(state, 8)
	end,
	
	read_huff_chunk = function(state)
		local node = state.huffman -- root
		
		repeat
			node = hufftree.child(node, decompress.read_bit(state))
		until node.value
		
		return node.value
	end,
	
	read_lz_lookup_ladder = function(state, count)
		local nextOffset = 1
		
		for i = 1, count do
			local ref = {}
			
			ref.bits   = decompress.read_bits(state, 4) + 1
			ref.offset = nextOffset
			
			state.lzLadder[i] = ref
			
			nextOffset = nextOffset + bit.lshift(1, ref.bits)
		end
	end,
	
	apply_lz_bytes = function(state, distance, length)
		local viewOffset = #state.data - distance

		for _ = 1, length do
			state.data[#state.data + 1] = state.data[viewOffset + 1]
			viewOffset = viewOffset + 1
		end
	end,
	
	apply_lz_2bytes = function(state, distance, length)
		local viewOffset = #state.data - (distance*2)

		for _ = 1, length do
			state.data[#state.data + 1] = state.data[viewOffset + 1]
			state.data[#state.data + 1] = state.data[viewOffset + 2]
			
			viewOffset = viewOffset + 2
		end
	end

}

pDecompStart = 0x080D102C
pDecompEnd   = 0x080D10EE

decompState  = nil

function on_decomp_start()
	local source = memory.getregister("r0")
	local target = memory.getregister("r1")
	
	decompState = decompress.start(source, target)
	
	decompress.read_header(decompState)
	
	print(
		string.format("DECOMP %X[%X] to %X; huff=%X,comp=%X,filt=%X",
			source,
			decompState.targetSize,
			target,
			decompState.huffType,
			decompState.compType,
			decompState.filtType
		)
	)
	
	decompress.huffman_pass(decompState)
	decompress.decomp_pass(decompState)
	decompress.filter_pass(decompState)
end

function on_decomp_end()
	if decompress.check_decomp(decompState) then
		print("  SUCCESS")
	else
		print("  FAILURE")
	end
end

memory.registerexec(pDecompStart, on_decomp_start)
memory.registerexec(pDecompEnd,   on_decomp_end)
