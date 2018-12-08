
-- reference table
MFOMT = dofile('../MFOMT.lua')

-- helpers
read_byte  = memory.readbyte
read_short = memory.readword
read_word  = memory.readlong

-- VBlankHookHandler 'class'

VBlankHookHandler = {}
VBlankHookHandler.__index = VBlankHookHandler

function VBlankHookHandler.new(ref, handlerTable)
	return setmetatable({
		xOrig = 4,
		yOrig = 4,
		line = 0,
		
		nameRef = ref,
		handlerTable = handlerTable,
		
		passTable = {}
	}, VBlankHookHandler)
end

function VBlankHookHandler.println(self, depth, text)
	-- print(text)
	gui.text(self.xOrig + 4*depth, self.yOrig + 8*self.line, text)
	self.line = self.line + 1
end

function VBlankHookHandler.handle_node(self, depth, pVBlankNode)
	local pVTable = read_word(pVBlankNode + 0x08)
	local name = self.nameRef[pVTable] or '<unk>'
	
	self.passTable[pVBlankNode] = true
	
	self:println(depth, ("%X %s"):format(pVTable, name))
	
	local handlerFunc = self.handlerTable[pVTable]
	if handlerFunc then handlerFunc(self, depth+1, pVBlankNode) end
	
	local pNext = read_word(pVBlankNode + 0x04)
	if pNext ~= 0 and not self.passTable[pNext] then self:handle_node(depth, pNext) end
end

-- script stuff

function make_vtable_name_ref(base)
	local result = {}

	for name, value in pairs(base) do
		if name:find('vtable_') == 1 then
			result[value] = name
		end
	end
	
	return result
end

function setup_vblank_hook_observer(ref)
	HANDLER_LOOKUP = {
		[ref.vtable_VBlankNodeList] = function(handler, depth, pVBlankNode)
			handler:handle_node(depth, read_word(pVBlankNode + 0x0C))
		end
	}
	
	HANDLER_LOOKUP[ref.vtable_VBlankRootNodeList]               = HANDLER_LOOKUP[ref.vtable_VBlankNodeList]
	HANDLER_LOOKUP[ref.vtable_VBlankRootNodeList_VBlankHandler] = HANDLER_LOOKUP[ref.vtable_VBlankRootNodeList]
	
	VTABLE_NAME_REF = make_vtable_name_ref(ref)
	
	gui.register(function()
		local handler = VBlankHookHandler.new(VTABLE_NAME_REF, HANDLER_LOOKUP)

		local pVBlankHook = read_word(ref.gpVBlankHook_instance)
		local pVBlankNode = read_word(pVBlankHook + 0x00)
		
		if pVBlankNode ~= 0 then handler:handle_node(0, pVBlankNode) end
	end)
end

setup_vblank_hook_observer(MFOMT)
