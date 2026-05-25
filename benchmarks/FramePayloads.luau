--!strict

local Payloads = {}

local ENTITY_PAYLOAD = table.freeze({
	Active = true,
	Health = 875,
	Id = 123456,
	Position = Vector3.new(12.5, 4.25, -19.75),
	Velocity = Vector3.new(1.5, 0, -3.25),
})

function Payloads.get(kind: string): any
	if kind == "boolean" then
		return true
	end

	if kind == "entity" then
		return ENTITY_PAYLOAD
	end

	error("[VNetFrameBenchmark]: Unknown payload kind " .. kind, 2)
end

return table.freeze(Payloads)
