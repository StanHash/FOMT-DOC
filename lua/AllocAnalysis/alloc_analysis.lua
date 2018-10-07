require "memory_util"
require "struct_type"

alloc_analysis = {

	new = function()
		local instance = {}
		
		instance.allocTable = {}
		
		return setmetatable(instance, alloc_analysis);
	end,
	
	setup_hook = function(self, pMalloc, pFree)
		if pMalloc then
			memory.registerexec(pMalloc, function()
				self:on_malloc()
			end)
		end
		
		if pFree then
			memory.registerexec(pFree, function()
				self:on_free()
			end)
		end
	end,
	
	on_malloc = function(self)
		local size   = memory.getregister("r0")
		local retloc = memory.getregister("r14")
		
		memory.registerexec(retloc, function()
			self:register_struct(memory.getregister("r0"), size)
			memory.registerexec(retloc, nil)
			
			print(("%X(%X) from %X"):format(memory.getregister("r0"), size, retloc))
		end)
	end,
	
	on_free = function(self)
		self:free_struct(memory.getregister("r0"))
	end,
	
	register_struct = function(self, address, size)
		local info = {}
		
		info.address = address
		info.size    = size
		info.struct  = struct_type.new(size)
		
		memory_util.register_readwrite(address, size, function(addr)
			local pc = memory.getregister("r15") - 4
			info.struct:register_field_access(pc, addr - info.address)
		end)
		
		self.allocTable[address] = info
	end,
	
	free_struct = function(self, address)
		local info = self.allocTable[address]
		
		if info then
			local fields = info.struct:get_fields()
			
			print(string.format("%X", info.address))
			print("struct {")
			
			local offset = 0
			local pad    = 0
			while offset < info.size do
				if fields[offset] and fields[offset] > 0 then
					if pad > 0 then
						print(string.format("  u8 _pad%X[0x%X];", offset - pad, pad))
						pad = 0
					end
					print(string.format("  u%d field%X;", fields[offset]*8, offset))
					offset = offset + fields[offset]
				else
					pad    = pad + 1
					offset = offset + 1
				end
			end
			
			print("};")
			print("")
			
			memory_util.register_readwrite(address, info.size, nil)
			self.allocTable[address] = nil
		end
	end

}

alloc_analysis.__index = alloc_analysis
