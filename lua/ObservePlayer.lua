
-- Constants
pPlayerActorConstructFunc = 0x08024AFC
pPlayerActorDestructFunc  = 0x08024C08
pPlayerActorVTable        = 0x080EEB98

-- Variables
pPlayer = 0

-- find player struct
-- in order to do this, we loop through all of ewram in search for a pointer to the PlayerActor vtable
-- if we don't find it, we will hook into the PlayerActor constructors and destructors anyway

for addr = 0x02000000, 0x0203FFFF, 4 do
	if memory.readlong(addr) == pPlayerActorVTable then
		pPlayer = addr - 0x14
		break
	end
end

-- register construct hook
memory.registerexec(pPlayerActorConstructFunc, function()
	pPlayer = memory.getregister('r0')
end)

-- register destruct hook
memory.registerexec(pPlayerActorDestructFunc, function()
	pPlayer = 0
end)

gui.register(function()
	if pPlayer ~= 0 then
		gui.text(4, 4, ("POS:   %08X, %08X"):format(memory.readlong(pPlayer + 0x08), memory.readlong(pPlayer + 0x0C)))
		gui.text(4, 12, ("SPEED: %08X, %08X"):format(memory.readlong(pPlayer + 0x18), memory.readlong(pPlayer + 0x1C)))
		gui.text(4, 20, ("STATE: %02X"):format(memory.readbyte(pPlayer + 0x3C)))
		gui.text(4, 28, ("ANIM:  %04X+%02X"):format(memory.readshort(pPlayer + 0x22), memory.readbyte(pPlayer + 0x20)))
	end
end)
