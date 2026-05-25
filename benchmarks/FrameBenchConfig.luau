--!strict

return table.freeze({
	controlRemoteName = "_VNetFrameBenchmarkControl",
	durationSeconds = 10,
	firesPerFrame = 1000,
	warmupFrames = 8,
	warmupSettleSeconds = 0.25,
	cooldownSeconds = 1,
	settleSeconds = 3,
	cpuSampleStride = 128,

	methods = {
		"VNet",
		"VNetImmediate",
		"VNetDirect",
		"Blink",
		"ByteNet",
	},

	cases = {
		{
			name = "Booleans",
			payload = "boolean",
			packet = "BenchBoolean",
			immediatePacket = "BenchBooleanImmediate",
			directPacket = "BenchBooleanDirect",
		},
		{
			name = "Entities",
			payload = "entity",
			packet = "BenchEntity",
			immediatePacket = "BenchEntityImmediate",
			directPacket = "BenchEntityDirect",
		},
		{
			name = "QuantizedEntities",
			payload = "entity",
			packet = "BenchQuantizedEntity",
			immediatePacket = "BenchQuantizedEntityImmediate",
			directPacket = "BenchQuantizedEntityDirect",
			blinkPacket = "BenchEntity",
		},
	},
})
