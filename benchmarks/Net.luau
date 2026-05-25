--!strict

local VNet = require(script.Parent.Parent)
local t = VNet.t

return VNet({
	BenchTiny = "u32",

	BenchSmall = {
		code = "string",
		flag = "bool",
		id = "u32",
	},

	BenchMedium = {
		id = "u32",
		look = "qtransform_yaw_i16",
		position = "qvec3_i16",
		stats = {
			hp = "u16",
			mana = "u16",
			speed = "u16",
		},
		tags = t.array("string"),
	},

	BenchLarge = {
		id = "u32",
		look = "qtransform_yaw_i16",
		nested = {
			a = t.array("u32"),
			b = t.array("u32"),
			c = {
				label = "string",
				ok = "bool",
			},
		},
		position = "qvec3_i16",
		samples = t.array("u32"),
		text = "string",
	},
})
