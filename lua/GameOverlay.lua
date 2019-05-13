
MFOMT = {
	GameObject_construct = 0x08017740,
	GameObject_destruct  = 0x08017B54,
	vtable_GameObject    = 0x080EE404
}

ref = MFOMT

-- Helper functions

function find_class_instance(vtable, vtable_offset)
	for addr = 0x02000000, 0x0203FFFF, 4 do
		if memory.readlong(addr) == vtable then
			return addr - vtable_offset
		end
	end
	
	return 0
end

function draw_cross(x, y, color)
	gui.line(x - 2, y, x + 2, y, color)
	gui.line(x, y - 2, x, y + 2, color)
end

function draw_actor_overlay(x, y, id, pActor)
	gui.text(x - 3, y - 32, ("%02X"):format(id))
	
	draw_cross(x+1, y+1, 'black')
	draw_cross(x, y, 'white')
end

-- Global variables

pGameObject = 0

-- Find Game Object, and hook into constructor/destructors to make sure we don't miss it

pGameObject = find_class_instance(ref.vtable_GameObject, 0x00)

memory.registerexec(ref.GameObject_construct, function()
	pGameObject = memory.getregister('r0')
end)

-- register destruct hook
memory.registerexec(ref.GameObject_destruct, function()
	pGameObject = 0
end)

-- Register main loop

gui.register(function()
	if pGameObject ~= 0 then
		-- Get camera coordinates

		pCameraObject = memory.readlong(pGameObject + 0x04)
		
		locCamera = memory.readlong(pCameraObject + 0x00)
		mapCamera = memory.readlong(pCameraObject + 0x04)
		xCamera   = memory.readshort(pCameraObject + 0x0A)
		yCamera   = memory.readshort(pCameraObject + 0x0E)
		
		-- Draw general information
		
		gui.text(4, 4, ("LOCATION: %03X (MAP: %04X)"):format(locCamera, mapCamera))
		
		-- Draw actor overlays
		
		for i = 0, 99 do
			pActor = memory.readlong(pGameObject + 8 + i * 4)
			
			if pActor ~= 0 and memory.readshort(pActor + 4) == locCamera then
				x = memory.readshort(pActor + 0x0A) - xCamera
				y = memory.readshort(pActor + 0x0E) - yCamera
				
				draw_actor_overlay(x, y, i, pActor)
			end
		end
	end
end)
