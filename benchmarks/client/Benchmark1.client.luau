-- Put this LocalScript in StarterPlayerScripts.
-- Keep VNet and VNet.Benchmarks in ReplicatedStorage.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VNetModule = ReplicatedStorage:WaitForChild("VNet")
local Benchmarks = VNetModule:WaitForChild("Benchmarks")
local VNet = require(VNetModule :: ModuleScript)
local BenchConfig = require(Benchmarks:WaitForChild("BenchConfig") :: ModuleScript)
local Payloads = require(Benchmarks:WaitForChild("Payloads") :: ModuleScript)
local BenchNet = require(Benchmarks:WaitForChild("Net") :: ModuleScript)

type PendingRun = {
	ready: BindableEvent,
	done: BindableEvent,
}

local getField = rawget
local measureBytes = BenchConfig.measureBytes == true
local rawRemote = ReplicatedStorage:WaitForChild(BenchConfig.rawRemoteName) :: RemoteEvent
local pending: {[string]: PendingRun} = {}
local packets = {
	tiny = BenchNet.BenchTiny,
	small = BenchNet.BenchSmall,
	medium = BenchNet.BenchMedium,
	large = BenchNet.BenchLarge,
}

VNet.configure({
	stats = measureBytes,
})

local function makeRunId(method: string, caseName: string): string
	return method .. ":" .. caseName .. ":" .. string.format("%.6f", os.clock())
end

rawRemote.OnClientEvent:Connect(function(action: string, runId: string, data: any)
	local run = pending[runId]
	if not run then
		return
	end

	if action == "ready" then
		run.ready:Fire()
	elseif action == "done" then
		run.done:Fire(data)
	end
end)

local function waitReady(runId: string): ()
	local run = pending[runId]
	if run then
		run.ready.Event:Wait()
	end
end

local function waitDone(runId: string): any
	local run = pending[runId]
	if not run then
		return nil
	end

	return run.done.Event:Wait()
end

local function startRun(method: string, caseName: string, expected: number): string
	local runId = makeRunId(method, caseName)

	pending[runId] = {
		ready = Instance.new("BindableEvent"),
		done = Instance.new("BindableEvent"),
	}

	rawRemote:FireServer("start", runId, method, caseName, expected)
	waitReady(runId)

	return runId
end

local function cleanupRun(runId: string): ()
	local run = pending[runId]
	if not run then
		return
	end

	run.ready:Destroy()
	run.done:Destroy()
	pending[runId] = nil
end

local function sendRawSingle(runId: string, payloads: {any}): ()
	for index, payload in ipairs(payloads) do
		rawRemote:FireServer("single", runId, index, payload)
	end
end

local function sendRawBatch(runId: string, payloads: {any}): ()
	rawRemote:FireServer("batch", runId, payloads)
end

local function sendVNet(_runId: string, payloads: {any}, payloadKind: string): ()
	local packet = packets[payloadKind]
	local sendPacket = getField(packet, "send") :: any

	for _, payload in ipairs(payloads) do
		sendPacket(payload)
	end

	VNet.flush()
end

local function sendVNetBulk(_runId: string, payloads: {any}, payloadKind: string): ()
	local packet = packets[payloadKind]
	local flushMany = getField(packet, "flushMany") :: any

	if typeof(flushMany) == "function" then
		flushMany(payloads)
	else
		local many = getField(packet, "many") :: any
		many(payloads)
		VNet.flush()
	end
end

local function send(method: string, runId: string, payloads: {any}, payloadKind: string): ()
	if method == "RawSingle" then
		sendRawSingle(runId, payloads)
	elseif method == "RawBatch" then
		sendRawBatch(runId, payloads)
	elseif method == "VNet" then
		sendVNet(runId, payloads, payloadKind)
	elseif method == "VNetBulk" then
		sendVNetBulk(runId, payloads, payloadKind)
	else
		error("[VNetBenchmark]: Unknown method " .. method, 2)
	end
end

local function formatRate(messages: number, seconds: number): string
	if seconds <= 0 then
		return "inf"
	end

	return string.format("%.0f msg/s", messages / seconds)
end

local function numberField(source: any, key: string): number
	if typeof(source) ~= "table" then
		return 0
	end

	local value = getField(source, key)
	return if typeof(value) == "number" then value else 0
end

local function formatBytes(bytes: number): string
	if bytes >= 1048576 then
		return string.format("%.2fMiB", bytes / 1048576)
	end

	if bytes >= 1024 then
		return string.format("%.2fKiB", bytes / 1024)
	end

	return tostring(bytes) .. "B"
end

local function isVNetMethod(method: string): boolean
	return method == "VNet" or method == "VNetBulk"
end

local function resetStatsIfMeasuring(): ()
	if measureBytes then
		VNet.resetStats()
	end
end

local function attachClientByteStats(result: any, stats: any): ()
	if not measureBytes then
		return
	end

	result.clientSentBytes = numberField(stats, "sentBytes")
	result.clientSentPackedBytes = numberField(stats, "sentPackedBytes")
	result.clientSentBatches = numberField(stats, "sentBatches")
	result.clientSentPackets = numberField(stats, "sentPackets")
end

local function attachServerByteStats(result: any): ()
	if not measureBytes then
		return
	end

	local serverStats = getField(result, "stats")

	result.serverReceivedBytes = numberField(serverStats, "receivedBytes")
	result.serverReceivedPackedBytes = numberField(serverStats, "receivedPackedBytes")
	result.serverReceivedBatches = numberField(serverStats, "receivedBatches")
	result.serverReceivedPackets = numberField(serverStats, "receivedPackets")
end

local function formatByteStats(result): string
	if not measureBytes then
		return ""
	end

	if not isVNetMethod(result.method) then
		return " bytes=raw:n/a"
	end

	return string.format(
		" bytes=sent:%s recv:%s packets:%d/%d batches:%d/%d",
		formatBytes(result.clientSentBytes or 0),
		formatBytes(result.serverReceivedBytes or 0),
		result.clientSentPackets or 0,
		result.serverReceivedPackets or 0,
		result.clientSentBatches or 0,
		result.serverReceivedBatches or 0
	)
end

local function runCase(method: string, caseConfig): any
	local payloads = Payloads.build(caseConfig.payload, caseConfig.messages)
	local runId = startRun(method, caseConfig.name, caseConfig.messages)

	resetStatsIfMeasuring()

	local startedAt = os.clock()

	send(method, runId, payloads, caseConfig.payload)

	local sentAt = os.clock()
	local clientStatsAtSend = if measureBytes then VNet.stats() else nil
	local result = waitDone(runId)
	local clientSeconds = os.clock() - startedAt
	local sendSeconds = sentAt - startedAt

	cleanupRun(runId)

	result.clientSeconds = clientSeconds
	result.sendSeconds = sendSeconds
	result.clientRate = formatRate(caseConfig.messages, clientSeconds)
	result.sendRate = formatRate(caseConfig.messages, sendSeconds)
	result.serverRate = formatRate(caseConfig.messages, result.serverSeconds)

	attachClientByteStats(result, clientStatsAtSend)
	attachServerByteStats(result)

	return result
end

local function printResult(result): ()
	print(
		string.format(
			"[VNetBenchmark] %-9s %-10s client=%.5fs (%s) send=%.5fs (%s) server=%.5fs (%s)%s",
			result.method,
			result.caseName,
			result.clientSeconds,
			result.clientRate,
			result.sendSeconds,
			result.sendRate,
			result.serverSeconds,
			result.serverRate,
			formatByteStats(result)
		)
	)
end

task.wait(2)
print("[VNetBenchmark] Starting benchmark")

local byCase = {}

for _, caseConfig in ipairs(BenchConfig.cases) do
	byCase[caseConfig.name] = {}

	for _, method in ipairs(BenchConfig.methods) do
		local result = runCase(method, caseConfig)
		byCase[caseConfig.name][method] = result
		printResult(result)
		task.wait(BenchConfig.cooldownSeconds)
	end

	local raw = byCase[caseConfig.name].RawSingle
	local rawBatch = byCase[caseConfig.name].RawBatch
	local vnet = byCase[caseConfig.name].VNet
	local vnetBulk = byCase[caseConfig.name].VNetBulk

	if raw and vnet and vnet.clientSeconds > 0 then
		print(
			string.format(
				"[VNetBenchmark] %-10s RawSingle/VNet client speedup: %.2fx",
				caseConfig.name,
				raw.clientSeconds / vnet.clientSeconds
			)
		)
	end

	if rawBatch and vnet and vnet.clientSeconds > 0 then
		print(
			string.format(
				"[VNetBenchmark] %-10s RawBatch/VNet client speedup: %.2fx",
				caseConfig.name,
				rawBatch.clientSeconds / vnet.clientSeconds
			)
		)
	end

	if raw and vnetBulk and vnetBulk.clientSeconds > 0 then
		print(
			string.format(
				"[VNetBenchmark] %-10s RawSingle/VNetBulk client speedup: %.2fx",
				caseConfig.name,
				raw.clientSeconds / vnetBulk.clientSeconds
			)
		)
	end

	if rawBatch and vnetBulk and vnetBulk.clientSeconds > 0 then
		print(
			string.format(
				"[VNetBenchmark] %-10s RawBatch/VNetBulk client speedup: %.2fx",
				caseConfig.name,
				rawBatch.clientSeconds / vnetBulk.clientSeconds
			)
		)
	end

	if raw and vnet and vnet.sendSeconds > 0 then
		print(
			string.format(
				"[VNetBenchmark] %-10s RawSingle/VNet send speedup: %.2fx",
				caseConfig.name,
				raw.sendSeconds / vnet.sendSeconds
			)
		)
	end

	if rawBatch and vnet and vnet.sendSeconds > 0 then
		print(
			string.format(
				"[VNetBenchmark] %-10s RawBatch/VNet send speedup: %.2fx",
				caseConfig.name,
				rawBatch.sendSeconds / vnet.sendSeconds
			)
		)
	end

	if raw and vnetBulk and vnetBulk.sendSeconds > 0 then
		print(
			string.format(
				"[VNetBenchmark] %-10s RawSingle/VNetBulk send speedup: %.2fx",
				caseConfig.name,
				raw.sendSeconds / vnetBulk.sendSeconds
			)
		)
	end

	if rawBatch and vnetBulk and vnetBulk.sendSeconds > 0 then
		print(
			string.format(
				"[VNetBenchmark] %-10s RawBatch/VNetBulk send speedup: %.2fx",
				caseConfig.name,
				rawBatch.sendSeconds / vnetBulk.sendSeconds
			)
		)
	end
end

print("[VNetBenchmark] Done")
