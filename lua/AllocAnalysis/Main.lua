require "alloc_analysis"
require "memory_util"
require "tools/fomt"

--[[

THE PLAN:
	Analyse struct layouts:
		When allocated structs, register read/write hooks for that struct. Since we know the size of it, it shouldn't be a problem... right?
		On read/write, decode the reading/writing instruction to know the size of the field.
	
	Analyse function parameter types:
		Given a list of functions to analyse, we can use the list of currently allocated structs to know of the parameter type the function likes to take.

--]]

--[[
call_stack = {}

db = {

	set_function = function(db, address, name)
		memory.registerexec(address, function()
			local retloc = memory.getregister("r14")
			
			memory.registerexec(retloc, function()
				-- print(string.format("%s returned", name))
				memory.registerexec(retloc, nil)
			end)
		end)
	end

}

fill_db(db)
--]]

ALLOC_ANALYSER = alloc_analysis.new()

ALLOC_ANALYSER:setup_hook(
	-- 0x080D01F8, -- FOMT malloc address
	-- 0x080D0260  -- FOMT free   address
	
	-- 0x080D7E04, -- MFOMT malloc       address

	0x080005E8, -- MFOMT new operator address
	0x080D7E6C  -- MFOMT free         address
)

gui.register(function()
	local line = 0

	for address, info in pairs(ALLOC_ANALYSER.allocTable) do
		gui.text(4, 4 + line * 8, ("%X:%X %s"):format(address, info.size, info.struct:get_name()))
		line = line + 1
	end
end)

--[[
memory.registerexec(
	0x080D8C54, -- MFOMT decompress address

function()
	print(("%X > %X from %X"):format(
		memory.getregister("r0"),
		memory.getregister("r1"),
		memory.getregister("r14")
	))
end)
--]]

--[[

It would be nice if the vba-rr dev had noted that registerread/write/exec took a size parameter
It also would have been nice if they told us about the address/size parameter passed to the called function too
It is still nice that it exists tho

--]]

--[[

memory.registerexec(0x08009140, function()
	local input  = memory.getregister("r0")
	local retloc = memory.getregister("r14")
	
	memory.registerexec(retloc, function()
		print(string.format("%X -> %X", input, memory.getregister("r0")))
		memory.registerexec(retloc, nil)
	end)
end)

--]]

--[[

memory_util.register_func_call(0x08009140, function(state)
	state.input = memory.getregister("r0")
end, function(state)
	print(string.format("%X -> %X", state.input, memory.getregister("r0")))
end)

--]]
