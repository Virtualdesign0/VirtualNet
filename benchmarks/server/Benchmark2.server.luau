-- Put this Script in ServerScriptService.
-- Keep VNet in ReplicatedStorage.
-- Keep generated Blink modules in ReplicatedStorage.Blink.Client/Server/Types.
-- Keep ByteNet in ReplicatedStorage.ByteNet.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local VNetModule = ReplicatedStorage:WaitForChild("VNet")
local Benchmarks = VNetModule:FindFirstChild("Benchmarks") or ReplicatedStorage:WaitForChild("Benchmarks")
local BlinkFolder = ReplicatedStorage:WaitForChild("Blink")
local VNet = require(VNetModule :: ModuleScript)
local Config = require(Benchmarks:WaitForChild("FrameBenchConfig") :: ModuleScript)
local VNetFrame = require(Benchmarks:WaitForChild("FrameVNet") :: ModuleScript)
local VNetImmediateFrame = require(Benchmarks:WaitForChild("FrameVNetImmediate") :: ModuleScript)
local VNetDirectFrame = require(Benchmarks:WaitForChild("FrameVNetDirect") :: ModuleScript)
local ByteNetFrame = require(Benchmarks:WaitForChild("FrameByteNet") :: ModuleScript)

local getField = rawget

local BlinkFrame = require(BlinkFolder:WaitForChild("Server") :: ModuleScript)
print("[VNetFrameBenchmark] Using Blink server module: ReplicatedStorage.Blink.Server")
print("[VNetFrameBenchmark] Using ByteNet module: ReplicatedStorage.ByteNet")

type RunState = {
	tool: string,
	caseName: string,
	expected: number?,
	received: number,
	callbacks: number,
	callbackSamples: number,
	callbackSeconds: number,
	receiveFrameSeconds: number,
	receiveFrameSecondsTotal: number,
	receiveFrameSecondsMax: number,
	receiveFrames: number,
	heapStartKb: number,
	batchTotal: number,
	batchMin: number?,
	batchMax: number,
	batchOne: number,
	batchSmall: number,
	batchMedium: number,
	batchLarge: number,
	batchHuge: number,
	startedAt: number?,
	finished: boolean,
}

local controlRemote = ReplicatedStorage:FindFirstChild(Config.controlRemoteName)
if not controlRemote then
	controlRemote = Instance.new("RemoteEvent")
	controlRemote.Name = Config.controlRemoteName
	controlRemote.Parent = ReplicatedStorage
end

VNet.configure({
	stats = false,
})

local states: {[Player]: {[string]: RunState}} = {}
local activeRuns: {[Player]: string} = {}
local cpuSampleStride = math.max(1, Config.cpuSampleStride or 128)

local function luaHeapKb(): number
	local ok, value = pcall(gcinfo)

	if ok and typeof(value) == "number" then
		return value
	end

	return 0
end

local function recordReceiveFrame(state: RunState): ()
	state.receiveFrames += 1
	state.receiveFrameSecondsTotal += state.receiveFrameSeconds

	if state.receiveFrameSeconds > state.receiveFrameSecondsMax then
		state.receiveFrameSecondsMax = state.receiveFrameSeconds
	end

	state.receiveFrameSeconds = 0
end

local function recordBatch(state: RunState, amount: number): ()
	state.batchTotal += amount
	state.batchMax = math.max(state.batchMax, amount)

	if state.batchMin == nil or amount < state.batchMin then
		state.batchMin = amount
	end

	if amount <= 1 then
		state.batchOne += 1
	elseif amount <= 31 then
		state.batchSmall += 1
	elseif amount <= 127 then
		state.batchMedium += 1
	elseif amount <= 511 then
		state.batchLarge += 1
	else
		state.batchHuge += 1
	end
end

local function getPlayerStates(player: Player): {[string]: RunState}
	local playerStates = states[player]

	if not playerStates then
		playerStates = {}
		states[player] = playerStates
	end

	return playerStates
end

local function finish(player: Player, runId: string, state: RunState): ()
	if state.finished then
		return
	end

	state.finished = true

	local expected = state.expected or state.received
	local serverSeconds = 0
	local heapEndKb = luaHeapKb()

	if state.startedAt then
		serverSeconds = os.clock() - state.startedAt
	end

	if state.receiveFrameSeconds > 0 then
		recordReceiveFrame(state)
	end

	getPlayerStates(player)[runId] = nil

	if activeRuns[player] == runId then
		activeRuns[player] = nil
	end

	(controlRemote :: RemoteEvent):FireClient(player, "done", runId, {
		tool = state.tool,
		caseName = state.caseName,
		expected = expected,
		received = state.received,
		serverSeconds = serverSeconds,
		serverCallbacks = state.callbacks,
		serverCallbackSamples = state.callbackSamples,
		serverCallbackSeconds = state.callbackSeconds,
		serverReceiveFrameSeconds = state.receiveFrameSecondsTotal,
		serverReceiveMaxFrameSeconds = state.receiveFrameSecondsMax,
		serverReceiveFrames = state.receiveFrames,
		serverHeapStartKb = state.heapStartKb,
		serverHeapEndKb = heapEndKb,
		serverHeapDeltaKb = heapEndKb - state.heapStartKb,
		batchTotal = state.batchTotal,
		batchMin = state.batchMin or 0,
		batchMax = state.batchMax,
		batchOne = state.batchOne,
		batchSmall = state.batchSmall,
		batchMedium = state.batchMedium,
		batchLarge = state.batchLarge,
		batchHuge = state.batchHuge,
		vnetStats = VNet.stats(),
	})
end

local function count(player: Player, tool: string, caseName: string, amount: number): ()
	local runId = activeRuns[player]
	if not runId then
		return
	end

	local state = getPlayerStates(player)[runId]
	if not state or state.tool ~= tool or state.caseName ~= caseName then
		return
	end

	if not state.startedAt then
		state.startedAt = os.clock()
	end

	state.callbacks += 1

	local sampled = state.callbacks % cpuSampleStride == 0
	local callbackStartedAt = if sampled then os.clock() else 0

	state.received += amount
	recordBatch(state, amount)

	if sampled then
		state.callbackSamples += 1
		local estimatedSeconds = (os.clock() - callbackStartedAt) * cpuSampleStride

		state.callbackSeconds += estimatedSeconds
		state.receiveFrameSeconds += estimatedSeconds
	end

	if state.expected and state.received >= state.expected then
		finish(player, runId, state)
	end
end

local function countActiveBlink(player: Player): ()
	local runId = activeRuns[player]
	if not runId then
		return
	end

	local state = getPlayerStates(player)[runId]
	if not state or state.tool ~= "Blink" then
		return
	end

	count(player, "Blink", state.caseName, 1)
end

local function countVNetBatch(packet: any, tool: string, caseName: string): ()
	local onBatchCount = getField(packet, "onBatchCount")

	if typeof(onBatchCount) == "function" then
		onBatchCount(function(player: Player, amount: number)
			count(player, tool, caseName, amount)
		end)
		return
	end

	packet.onBatch(function(player: Player, _payloads: {any}, amount: number)
		count(player, tool, caseName, amount)
	end)
end

local function singularName(name: string): string
	if string.sub(name, -3) == "ies" then
		return string.sub(name, 1, -4) .. "y"
	end

	if string.sub(name, -1) == "s" then
		return string.sub(name, 1, -2)
	end

	return name
end

local function availableKeys(source: {[any]: any}): string
	local keys = {}

	for key, value in source do
		if typeof(key) == "string" and typeof(value) == "table" then
			local methods = {}

			for methodName, methodValue in value do
				if typeof(methodName) == "string" and typeof(methodValue) == "function" then
					table.insert(methods, methodName)
				end
			end

			table.sort(methods)
			table.insert(keys, key .. "(" .. table.concat(methods, ",") .. ")")
		end
	end

	table.sort(keys)
	return table.concat(keys, ", ")
end

local function soleCompatibleBlinkEvent(methodName: string)
	local foundName: string? = nil
	local foundEvent = nil

	for key, value in BlinkFrame :: any do
		if typeof(key) == "string" and typeof(value) == "table" and typeof(getField(value, methodName)) == "function" then
			if foundEvent ~= nil then
				return nil, nil
			end

			foundName = key
			foundEvent = value
		end
	end

	return foundEvent, foundName
end

local function blinkCandidates(caseConfig): {string}
	local candidates = {}
	local seen: {[string]: boolean} = {}

	local function push(value: any): ()
		if typeof(value) == "string" and value ~= "" and not seen[value] then
			seen[value] = true
			table.insert(candidates, value)
		end
	end

	local singular = singularName(caseConfig.name)

	push(caseConfig.blinkPacket)
	push(caseConfig.packet)
	push(caseConfig.name)
	push(singular)
	push("Bench" .. singular)

	return candidates
end

local function byteNetCandidates(caseConfig): {string}
	local candidates = {}
	local seen: {[string]: boolean} = {}

	local function push(value: any): ()
		if typeof(value) == "string" and value ~= "" and not seen[value] then
			seen[value] = true
			table.insert(candidates, value)
		end
	end

	local singular = singularName(caseConfig.name)

	push(caseConfig.byteNetPacket)
	push(caseConfig.packet)
	push(caseConfig.name)
	push(singular)
	push("Bench" .. singular)

	return candidates
end

local function resolveBlinkEvent(caseConfig, methodName: string)
	for _, name in ipairs(blinkCandidates(caseConfig)) do
		local event = getField(BlinkFrame, name)
		if typeof(event) == "table" and typeof(getField(event, methodName)) == "function" then
			return event
		end
	end

	local event, eventName = soleCompatibleBlinkEvent(methodName)
	if event then
		warn(
			string.format(
				"[VNetFrameBenchmark]: Using only compatible Blink Server event '%s' for case '%s'. Set blinkPacket in FrameBenchConfig to remove this warning.",
				eventName,
				caseConfig.name
			)
		)
		return event
	end

	error(
		string.format(
			"[VNetFrameBenchmark]: Blink Server module has no event for case '%s'. Tried: %s. Available events: %s",
			caseConfig.name,
			table.concat(blinkCandidates(caseConfig), ", "),
			availableKeys(BlinkFrame :: any)
		),
		2
	)
end

local function resolveByteNetPacket(caseConfig, methodName: string)
	for _, name in ipairs(byteNetCandidates(caseConfig)) do
		local packet = getField(ByteNetFrame, name)
		if typeof(packet) == "table" and typeof(getField(packet, methodName)) == "function" then
			return packet
		end
	end

	error(
		string.format(
			"[VNetFrameBenchmark]: ByteNet namespace has no packet for case '%s'. Tried: %s. Available packets: %s",
			caseConfig.name,
			table.concat(byteNetCandidates(caseConfig), ", "),
			availableKeys(ByteNetFrame :: any)
		),
		2
	)
end

(controlRemote :: RemoteEvent).OnServerEvent:Connect(function(player: Player, action: string, runId: string, ...: any)
	if action == "start" then
		local tool = select(1, ...) :: string
		local caseName = select(2, ...) :: string

		VNet.resetStats()

		getPlayerStates(player)[runId] = {
			tool = tool,
			caseName = caseName,
			expected = nil,
			received = 0,
			callbacks = 0,
			callbackSamples = 0,
			callbackSeconds = 0,
			receiveFrameSeconds = 0,
			receiveFrameSecondsTotal = 0,
			receiveFrameSecondsMax = 0,
			receiveFrames = 0,
			heapStartKb = luaHeapKb(),
			batchTotal = 0,
			batchMin = nil,
			batchMax = 0,
			batchOne = 0,
			batchSmall = 0,
			batchMedium = 0,
			batchLarge = 0,
			batchHuge = 0,
			startedAt = nil,
			finished = false,
		}

		activeRuns[player] = runId

		controlRemote:FireClient(player, "ready", runId)
		return
	end

	if action == "finish" then
		local expected = select(1, ...) :: number
		local state = getPlayerStates(player)[runId]
		if not state or state.finished then
			return
		end

		state.expected = expected

		if state.received >= expected then
			finish(player, runId, state)
			return
		end

		task.delay(Config.settleSeconds, function()
			local delayed = getPlayerStates(player)[runId]
			if delayed and not delayed.finished then
				finish(player, runId, delayed)
			end
		end)
	end
end)

countVNetBatch(VNetFrame.BenchBoolean, "VNet", "Booleans")
countVNetBatch(VNetFrame.BenchEntity, "VNet", "Entities")
countVNetBatch(VNetFrame.BenchQuantizedEntity, "VNet", "QuantizedEntities")
countVNetBatch(VNetImmediateFrame.BenchBooleanImmediate, "VNetImmediate", "Booleans")
countVNetBatch(VNetImmediateFrame.BenchEntityImmediate, "VNetImmediate", "Entities")
countVNetBatch(VNetImmediateFrame.BenchQuantizedEntityImmediate, "VNetImmediate", "QuantizedEntities")
countVNetBatch(VNetDirectFrame.BenchBooleanDirect, "VNetDirect", "Booleans")
countVNetBatch(VNetDirectFrame.BenchEntityDirect, "VNetDirect", "Entities")
countVNetBatch(VNetDirectFrame.BenchQuantizedEntityDirect, "VNetDirect", "QuantizedEntities")

for _, caseConfig in ipairs(Config.cases) do
	local caseName = caseConfig.name
	local packet = resolveByteNetPacket(caseConfig, "listen")

	packet.listen(function(_payload: any, player: Player?)
		if player then
			count(player, "ByteNet", caseName, 1)
		end
	end)
end

local blinkEvents = {}

for _, caseConfig in ipairs(Config.cases) do
	table.insert(blinkEvents, {
		caseName = caseConfig.name,
		event = resolveBlinkEvent(caseConfig, "Iter"),
	})
end

RunService.Heartbeat:Connect(function()
	for _, info in ipairs(blinkEvents) do
		for _index, player, _value in info.event.Iter() do
			countActiveBlink(player)
		end

	end

	for player, runId in activeRuns do
		local state = getPlayerStates(player)[runId]

		if state and state.startedAt then
			recordReceiveFrame(state)
		end
	end
end)
