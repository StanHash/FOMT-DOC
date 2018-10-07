
memory_util = {

	register_func_call = function(address, on_call, on_return)
		memory.registerexec(address, function()
			local state  = {}
			local retloc = memory.getregister("r14")
			
			on_call(state)
			
			memory.registerexec(retloc, function()
				on_return(state)
				
				state = {}
				memory.registerexec(retloc, nil)
			end)
		end)
	end,
	
	register_readwrite = function(address, size, func)
		memory.registerread(address, size, func)
		memory.registerwrite(address, size, func)
	end,
	
	is_wram_address = function(address)
		return memory_util.is_ewram_address(address) or memory_util.is_iwram_address(address)
	end,
	
	is_ewram_address = function(address)
		return (address >= 0x2000000) and (address < 0x2040000)
	end,
	
	is_iwram_address = function(address)
		return (address >= 0x3000000) and (address < 0x3008000)
	end

}
