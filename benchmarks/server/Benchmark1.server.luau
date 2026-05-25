-- Put this Script in ServerScriptService.
-- Keep VNet and VNet.Benchmarks in ReplicatedStorage.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VNetModule = ReplicatedStorage:WaitForChild("VNet")
local Benchmarks = VNetModule:WaitForChild("Benchmarks")
local VNet = require(VNetModule :: ModuleScript)
local BenchConfig = require(Benchmarks:WaitForChild("BenchConfig") :: ModuleScript)
local BenchNet = require(Benchmarks:WaitForChild("Net") :: ModuleScript)

type RunState = {
	method: string,
	caseName: string,
	expected: number,
	received: number,
	startedAt: number?,
}

local measureBytes = BenchConfig.measureBytes == true
local getField = rawget
local rawRemote = ReplicatedStorage:FindFirstChild(BenchConfig.rawRemoteName)
if not rawRemote then
	rawRemote = Instance.new("RemoteEvent")
	rawRemote.Name = BenchConfig.rawRemoteName
	rawRemote.Parent = ReplicatedStorage
end

VNet.configure({
	stats = measureBytes,
})

local states: {[Player]: {[string]: RunState}} = {}
local activeVNetRuns: {[Player]: string} = {}
local benchPackets = {
	BenchNet.BenchTiny,
	BenchNet.BenchSmall,
	BenchNet.BenchMedium,
	BenchNet.BenchLarge,
}

local function getPlayerStates(player: Player): {[string]: RunState}
	local playerStates = states[player]

	if not playerStates then
		playerStates = {}
		states[player] = playerStates
	end

	return playerStates
end

local function finish(player: Player, runId: string, state: RunState): ()
	local serverSeconds = 0

	if state.startedAt then
		serverSeconds = os.clock() - state.startedAt
	end

	getPlayerStates(player)[runId] = nil

	if activeVNetRuns[player] == runId then
		activeVNetRuns[player] = nil
	end

	local stats = if measureBytes then VNet.stats() else nil

	(rawRemote :: RemoteEvent):FireClient(player, "done", runId, {
		method = state.method,
		caseName = state.caseName,
		expected = state.expected,
		serverSeconds = serverSeconds,
		stats = stats,
	})
end

local function count(player: Player, runId: string, amount: number): ()
	local state = getPlayerStates(player)[runId]
	if not state then
		return
	end

	if not state.startedAt then
		state.startedAt = os.clock()
	end

	state.received += amount

	if state.received >= state.expected then
		finish(player, runId, state)
	end
end

(rawRemote :: RemoteEvent).OnServerEvent:Connect(function(player: Player, action: string, runId: string, ...: any)
	if action == "start" then
		local method = select(1, ...) :: string
		local caseName = select(2, ...) :: string
		local expected = select(3, ...) :: number

		if measureBytes then
			VNet.resetStats()
		end

		getPlayerStates(player)[runId] = {
			method = method,
			caseName = caseName,
			expected = expected,
			received = 0,
			startedAt = nil,
		}

		if method == "VNet" or method == "VNetBulk" then
			activeVNetRuns[player] = runId
		end

		(rawRemote :: RemoteEvent):FireClient(player, "ready", runId)
		return
	end

	if action == "single" then
		count(player, runId, 1)
		return
	end

	if action == "batch" then
		local payloads = select(1, ...) :: {any}
		local amount = 0

		for _ in ipairs(payloads) do
			amount += 1
		end

		count(player, runId, amount)
	end
end)

local function countVNet(player: Player, _payload: any): ()
	local runId = activeVNetRuns[player]

	if runId then
		count(player, runId, 1)
	end
end

local function countVNetBatch(player: Player, _payloads: {any}, amount: number): ()
	local runId = activeVNetRuns[player]

	if runId then
		count(player, runId, amount)
	end
end

for _, packet in ipairs(benchPackets) do
	local onBatch = getField(packet, "onBatch") :: any

	if typeof(onBatch) == "function" then
		onBatch(countVNetBatch)
	else
		local on = getField(packet, "on") :: any
		on(countVNet)
	end
end
