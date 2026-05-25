--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ByteNet = require(ReplicatedStorage:WaitForChild("ByteNet"))
local getField = rawget

local function lookup(name: string): any
	local value = getField(ByteNet :: any, name)
	if value ~= nil then
		return value
	end

	local dataTypes = getField(ByteNet :: any, "dataTypes")
	if typeof(dataTypes) == "table" then
		return getField(dataTypes, name)
	end

	return nil
end

local function byteNetFunction(name: string): (...any) -> any
	local value = lookup(name)

	if typeof(value) ~= "function" then
		error(`[VNetFrameBenchmark]: ByteNet.{name} is missing.`, 2)
	end

	return value
end

local function byteNetType(...: string): any
	for index = 1, select("#", ...) do
		local name = select(index, ...)
		local value = lookup(name)

		if value ~= nil then
			if typeof(value) == "function" then
				local ok, result = pcall(value)

				if ok and result ~= nil then
					return result
				end
			end

			return value
		end
	end

	error("[VNetFrameBenchmark]: ByteNet datatype is missing.", 2)
end

local defineNamespace = byteNetFunction("defineNamespace")
local definePacket = byteNetFunction("definePacket")
local struct = byteNetFunction("struct")

local bool = byteNetType("bool", "boolean")
local uint16 = byteNetType("uint16", "u16")
local uint32 = byteNetType("uint32", "u32")
local vec3 = byteNetType("vec3", "vector3")

local function reliable(value: any): {[string]: any}
	return {
		value = value,
		reliabilityType = "reliable",
	}
end

return defineNamespace("VNetFrameBenchmarkByteNet", function()
	local entity = struct({
		Active = bool,
		Health = uint16,
		Id = uint32,
		Position = vec3,
		Velocity = vec3,
	})

	return {
		BenchBoolean = definePacket(reliable(bool)),
		BenchEntity = definePacket(reliable(entity)),

		-- ByteNet does not use VNet's qvec3_i16 codec here. This packet keeps the
		-- same entity shape so the benchmark can run the same traffic case.
		BenchQuantizedEntity = definePacket(reliable(entity)),
	}
end)
