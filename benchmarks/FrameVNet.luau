--!strict

local VNet = require(script.Parent.Parent)

return VNet({
	BenchBoolean = "bool",

	BenchEntity = {
		Active = "bool",
		Health = "u16",
		Id = "u32",
		Position = "vec3",
		Velocity = "vec3",
	},

	BenchQuantizedEntity = {
		Active = "bool",
		Health = "u16",
		Id = "u32",
		Position = "qvec3_i16",
		Velocity = "qvec3_i16",
	},
})
