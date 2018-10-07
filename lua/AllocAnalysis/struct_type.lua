require "thumb_decode"

struct_type = {

	new = function(size)
		local instance = {}
		
		instance.size = size
		instance.accesses = {}
		instance.fields   = nil
		
		return setmetatable(instance, struct_type)
	end,
	
	__index = {
	
		register_field_access = function(self, from, offset)
			self.accesses[from] = offset
			
			-- clean fields, they need updating anyway
			self.fields = nil
		end,
		
		get_fields = function(self)
			if not self.fields then
				local fields = {}
				
				-- For each access, decode instruction (get size)
				for access, offset in pairs(self.accesses) do
					local inst = thumb_decode.decode_load_store(access)
					local size = inst and inst:get_field_size() or 0
					
					-- Only set size of the offset wasn't registered OR the new size is bigger
					if (not fields[offset]) or (fields[offset] < size) then
						fields[offset] = size
					end
				end
				
				-- Removing dead fields
				local offset = 0
				while offset < self.size do
					local size = fields[offset]
					
					if size and size > 1 then
						for i = (offset + 1), (offset + size - 1) do
							fields[i] = nil
						end
						
						offset = offset + size
					else
						offset = offset + 1
					end
				end
				
				self.fields = fields
			end
			
			return self.fields
		end
	
	}

}
