--!strict

local VNet = require(script.Parent.Parent)

return VNet({
	BenchBooleanDirect = VNet.direct("bool"),

	BenchEntityDirect = VNet.direct({
		Active = "bool",
		Health = "u16",
		Id = "u32",
		Position = "vec3",
		Velocity = "vec3",
	}),

	BenchQuantizedEntityDirect = VNet.direct({
		Active = "bool",
		Health = "u16",
		Id = "u32",
		Position = "qvec3_i16",
		Velocity = "qvec3_i16",
	}),
})
