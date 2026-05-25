--!strict

local VNet = require(script.Parent.Parent)

return VNet({
	BenchBooleanImmediate = VNet.instant("bool"),

	BenchEntityImmediate = VNet.instant({
		Active = "bool",
		Health = "u16",
		Id = "u32",
		Position = "vec3",
		Velocity = "vec3",
	}),

	BenchQuantizedEntityImmediate = VNet.instant({
		Active = "bool",
		Health = "u16",
		Id = "u32",
		Position = "qvec3_i16",
		Velocity = "qvec3_i16",
	}),
})
