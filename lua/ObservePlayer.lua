
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

function display_actor_panel(pActor, x, y)
	gui.text(x + 4, y + 4,  ("POS:   %08X, %08X"):format(memory.readlong(pActor + 0x08), memory.readlong(pActor + 0x0C)))
	gui.text(x + 4, y + 12, ("SPEED: %08X, %08X"):format(memory.readlong(pActor + 0x18), memory.readlong(pActor + 0x1C)))
	gui.text(x + 4, y + 20, ("LOC:   %04X"):format(memory.readshort(pActor + 0x04)))
end

yStart = 0

gui.register(function()
	if pPlayer ~= 0 then
		-- Display player info
		display_actor_panel(pPlayer, 0, 0)
		gui.text(4, 28, ("STATE: %02X"):format(memory.readbyte(pPlayer + 0x3C)))
		gui.text(4, 36, ("ANIM:  %04X+%02X"):format(memory.readshort(pPlayer + 0x22), memory.readbyte(pPlayer + 0x20)))
		
		-- Display time?
		
		pGameObject = memory.readlong(pPlayer + 0x00)
		pGameData   = memory.readlong(pGameObject + 0x1038)
		
		timeHours   = bit.band(memory.readshort(pGameData + 0x12), 0x1F)
		timeMinutes = bit.band(bit.rshift(memory.readshort(pGameData + 0x12), 5), 0x3F)
		
		gui.text(4, 50, ("TIME: %02d:%02d"):format(timeHours, timeMinutes))
		
		-- Display other actors info
		
		y = yStart
		
		for i = 1, 99 do
			pActor = memory.readlong(pGameObject + 8 + i * 4)
			
			if pActor ~= 0 then
				gui.text(124, y+4, ("ACTOR #%02X"):format(i))
				display_actor_panel(pActor, 120, y+8)
				
				y = y + 40
			end
		end
		
		-- Update stuff based on input
		
		key = input.get()
		
		if key["numpad-"] then yStart = yStart - 4 end
		if key["numpad+"] then yStart = yStart + 4 end
	end
end)
