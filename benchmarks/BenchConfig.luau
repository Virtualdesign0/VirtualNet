--!strict

return table.freeze({
	rawRemoteName = "_VNetBenchmarkRaw",
	cooldownSeconds = 0.25,
	measureBytes = true,

	cases = {
		{
			name = "tiny_2k",
			payload = "tiny",
			messages = 2000,
		},
		{
			name = "burst_20k",
			payload = "tiny",
			messages = 20000,
		},
		{
			name = "small_1k",
			payload = "small",
			messages = 1000,
		},
		{
			name = "medium_500",
			payload = "medium",
			messages = 500,
		},
		{
			name = "large_150",
			payload = "large",
			messages = 150,
		},
	},

	methods = {
		"RawSingle",
		"RawBatch",
		"VNet",
		"VNetBulk",
	},
})
