--!strict

local Payloads = {}
local createArray = (table :: any)["create"]

local function fillNumberList(target: {number}, count: number, seed: number): ()
	for index = 1, count do
		target[index] = seed + index
	end
end

local function assignSeries(owner: {[any]: any}, key: any, count: number, seed: number): ()
	owner[key] = createArray(count)
	fillNumberList(owner[key], count, seed)
end

local function makeLargePayload(index: number)
	local nested = {
		c = {
			ok = true,
			label = "large_" .. tostring(index),
		},
	}

	local payload = {
		id = index,
		position = Vector3.new(index % 41, index % 37, index % 29),
		look = CFrame.Angles(index % 3, index % 5, index % 7),
		samples = {},
		text = string.rep("x", 256),
		nested = nested,
	}

	assignSeries(payload, "samples", 64, index)
	assignSeries(nested, "a", 16, index * 2)
	assignSeries(nested, "b", 16, index * 3)

	return payload
end

function Payloads.create(kind: string, index: number): any
	if kind == "tiny" then
		return index
	end

	if kind == "small" then
		return {
			id = index,
			flag = index % 2 == 0,
			code = "item_" .. tostring(index),
		}
	end

	if kind == "medium" then
		return {
			id = index,
			position = Vector3.new(index % 31, index % 17, index % 13),
			look = CFrame.new(index % 7, index % 11, index % 5),
			stats = {
				hp = 100 + index % 50,
				mana = 40 + index % 25,
				speed = 16 + index % 4,
			},
			tags = {
				"bench",
				"medium",
				"packet",
			},
		}
	end

	if kind == "large" then
		return makeLargePayload(index)
	end

	error("[VNetBenchmark]: Unknown payload kind " .. kind, 2)
end

function Payloads.build(kind: string, count: number): {any}
	local payloads = createArray(count)

	for index = 1, count do
		payloads[index] = Payloads.create(kind, index)
	end

	return payloads
end

return table.freeze(Payloads)
