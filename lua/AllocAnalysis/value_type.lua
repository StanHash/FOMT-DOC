require "struct_type"

value_type = {

	new_int_constant = function(value)
		local result = {
			int_constant = value
		}
		
		return setmetatable(result, value_type)
	end,
	
	new_pointer = function(targetType)
		local result = {
			pointer = targetType
		}
		
		return setmetatable(result, value_type)
	end,
	
	new_struct = function(size)
		local result = {
			struct = struct_type:new(size)
		}
		
		return setmetatable(result, value_type)
	end,
	
	__index = {
	
		is_struct = function(self)
			return self.struct ~= nil
		end,
		
		is_int_constant = function(self)
			return self.int_constant ~= nil
		end,
		
		is_pointer = function(self)
			return self.pointer ~= nil
		end
	
	}

}

type_db = {

	new = function()
		local result = {}
		
		result.int_constant_pool = {}
		result.struct_pool       = {}
		result.pointer_pool      = {}
		
		return setmetatable(result, type_db)
	end,

	__index = {
	
		int_constant = function(self, value)
			local result = self.int_constant_pool[value]
			
			if not result then
				result = value_type:new_int_constant(value)
				self.int_constant_pool[value] = result
			end
			
			return result
		end,
		
		struct = function(self, size)
			local result = value_type:new_struct(size)
			
			self.struct_pool[#self.struct_pool] = result
			
			return result
		end
	
	}

}
