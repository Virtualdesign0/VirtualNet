
-- Put this LocalScript in StarterPlayerScripts.
-- Keep VNet in ReplicatedStorage.
-- Keep generated Blink modules in ReplicatedStorage.Blink.Client/Server/Types.
-- Keep ByteNet in ReplicatedStorage.ByteNet.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local VNetModule = ReplicatedStorage:WaitForChild("VNet")
local Benchmarks = VNetModule:FindFirstChild("Benchmarks") or ReplicatedStorage:WaitForChild("Benchmarks")
local BlinkFolder = ReplicatedStorage:WaitForChild("Blink")
local VNet = require(VNetModule :: ModuleScript)
local ByteCounter = require(Benchmarks:WaitForChild("FrameByteCounter") :: ModuleScript)
local Config = require(Benchmarks:WaitForChild("FrameBenchConfig") :: ModuleScript)
local Payloads = require(Benchmarks:WaitForChild("FramePayloads") :: ModuleScript)
local VNetFrame = require(Benchmarks:WaitForChild("FrameVNet") :: ModuleScript)
local VNetImmediateFrame = require(Benchmarks:WaitForChild("FrameVNetImmediate") :: ModuleScript)
local VNetDirectFrame = require(Benchmarks:WaitForChild("FrameVNetDirect") :: ModuleScript)
local ByteNetFrame = require(Benchmarks:WaitForChild("FrameByteNet") :: ModuleScript)

local getField = rawget

local BlinkFrame = require(BlinkFolder:WaitForChild("Client") :: ModuleScript)
print("[VNetFrameBenchmark] Using Blink client module: ReplicatedStorage.Blink.Client")
print("[VNetFrameBenchmark] Using ByteNet module: ReplicatedStorage.ByteNet")

type PendingRun = {
	ready: BindableEvent,
	done: BindableEvent,
}

type Summary = {
	tool: string,
	caseName: string,
	sent: number,
	received: number,
	lossPercent: number,
	serverSeconds: number,
	clientSeconds: number,
	clientEnqueueSeconds: number,
	clientEnqueueFrames: number,
	serverCallbackSeconds: number,
	serverCallbacks: number,
	serverCallbackSamples: number,
	serverReceiveFrameSeconds: number,
	serverReceiveMaxFrameSeconds: number,
	serverReceiveFrames: number,
	clientHeapStartKb: number,
	clientHeapEndKb: number,
	clientHeapDeltaKb: number,
	serverHeapStartKb: number,
	serverHeapEndKb: number,
	serverHeapDeltaKb: number,
	batchTotal: number,
	batchMin: number,
	batchMax: number,
	batchOne: number,
	batchSmall: number,
	batchMedium: number,
	batchLarge: number,
	batchHuge: number,
	fps: {number},
	byteStats: any,
}

local controlRemote = ReplicatedStorage:WaitForChild(Config.controlRemoteName) :: RemoteEvent
local pending: {[string]: PendingRun} = {}
local results: {[string]: {[string]: Summary}} = {}

local function luaHeapKb(): number
	local ok, value = pcall(gcinfo)

	if ok and typeof(value) == "number" then
		return value
	end

	return 0
end

VNet.configure({
	stats = false,
})

local function makeRunId(tool: string, caseName: string): string
	return tool .. ":" .. caseName .. ":" .. string.format("%.6f", os.clock())
end

controlRemote.OnClientEvent:Connect(function(action: string, runId: string, data: any)
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

local function startRun(tool: string, caseName: string): string
	local runId = makeRunId(tool, caseName)

	pending[runId] = {
		ready = Instance.new("BindableEvent"),
		done = Instance.new("BindableEvent"),
	}

	controlRemote:FireServer("start", runId, tool, caseName)
	pending[runId].ready.Event:Wait()

	return runId
end

local function finishRun(runId: string, sent: number): any
	local run = pending[runId]
	if not run then
		return nil
	end

	controlRemote:FireServer("finish", runId, sent)
	return run.done.Event:Wait()
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
				"[VNetFrameBenchmark]: Using only compatible Blink Client event '%s' for case '%s'. Set blinkPacket in FrameBenchConfig to remove this warning.",
				eventName,
				caseConfig.name
			)
		)
		return event
	end

	error(
		string.format(
			"[VNetFrameBenchmark]: Blink Client module has no event for case '%s'. Tried: %s. Available events: %s",
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

local function resolveSender(tool: string, caseConfig): (any) -> ()
	if tool == "VNet" then
		local send = (VNetFrame :: any)[caseConfig.packet].send

		return function(payload: any): ()
			send(payload)
		end
	end

	if tool == "VNetImmediate" then
		local send = (VNetImmediateFrame :: any)[caseConfig.immediatePacket].send

		return function(payload: any): ()
			send(payload)
		end
	end

	if tool == "VNetDirect" then
		local send = (VNetDirectFrame :: any)[caseConfig.directPacket].send

		return function(payload: any): ()
			send(payload)
		end
	end

	if tool == "Blink" then
		local fire = resolveBlinkEvent(caseConfig, "Fire").Fire

		return function(payload: any): ()
			fire(payload)
		end
	end

	if tool == "ByteNet" then
		local send = resolveByteNetPacket(caseConfig, "send").send

		return function(payload: any): ()
			send(payload)
		end
	end

	error("[VNetFrameBenchmark]: Unknown tool " .. tool, 2)
end

local function flushTool(tool: string): ()
	if tool == "VNet" or tool == "VNetImmediate" or tool == "VNetDirect" then
		VNet.flush()
		return
	end

	if tool == "Blink" then
		local stepReplication = (BlinkFrame :: any).StepReplication
		if typeof(stepReplication) == "function" then
			stepReplication()
		end
	end
end

local function percentile(values: {number}, percent: number, higherIsBetter: boolean): number
	local count = #values
	if count == 0 then
		return 0
	end

	local sorted = table.clone(values)
	table.sort(sorted, function(left, right)
		if higherIsBetter then
			return left > right
		end

		return left < right
	end)

	if count == 1 then
		return sorted[1]
	end

	local index = math.floor((percent / 100) * (count - 1) + 1.5)
	index = math.clamp(index, 1, count)

	return sorted[index]
end

local function metricSet(values: {number}, higherIsBetter: boolean): {median: number, p0: number, p80: number, p90: number, p95: number, p99: number}
	return {
		median = percentile(values, 50, higherIsBetter),
		p0 = percentile(values, 0, higherIsBetter),
		p80 = percentile(values, 80, higherIsBetter),
		p90 = percentile(values, 90, higherIsBetter),
		p95 = percentile(values, 95, higherIsBetter),
		p99 = percentile(values, 99, higherIsBetter),
	}
end

local function formatNumber(value: number): string
	return string.format("%.2f", value)
end

local function formatInteger(value: number): string
	local text = tostring(math.floor(value + 0.5))
	local output = ""

	while #text > 3 do
		output = "," .. string.sub(text, -3) .. output
		text = string.sub(text, 1, -4)
	end

	return text .. output
end

local function formatBytes(value: number): string
	local absolute = math.abs(value)

	if absolute >= 1024 * 1024 then
		return string.format("%.2f MiB", value / (1024 * 1024))
	end

	if absolute >= 1024 then
		return string.format("%.2f KiB", value / 1024)
	end

	return formatInteger(value) .. " B"
end

local function formatLoss(value: number): string
	if math.abs(value) < 0.005 then
		return "0%"
	end

	return string.format("%.2f%%", value)
end

local function printMetricRow(tool: string, metrics, lossPercent: number): ()
	print(
		string.format(
			"| %s | %s | %s | %s | %s | %s | %s | %s |",
			tool,
			formatNumber(metrics.median),
			formatNumber(metrics.p0),
			formatNumber(metrics.p80),
			formatNumber(metrics.p90),
			formatNumber(metrics.p95),
			formatNumber(metrics.p99),
			formatLoss(lossPercent)
		)
	)
end

local function printByteRow(tool: string, result: Summary): ()
	local bytes = result.byteStats

	print(
		string.format(
			"%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s",
			tool,
			formatInteger(bytes.messages),
			formatInteger(bytes.batches),
			formatInteger(bytes.payloadBytesPerMessage),
			formatInteger(bytes.batchHeaderBytes),
			formatBytes(bytes.batchHeaderBytesTotal),
			formatBytes(bytes.bytesSent),
			formatBytes(bytes.bytesReceived),
			formatNumber(bytes.bytesPerMessage),
			formatNumber(bytes.kbpsEstimate),
			formatLoss(result.lossPercent)
		)
	)
end

local function printMarkdownByteRow(tool: string, result: Summary): ()
	local bytes = result.byteStats

	print(
		string.format(
			"| %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s |",
			tool,
			formatInteger(bytes.messages),
			formatInteger(bytes.batches),
			formatInteger(bytes.payloadBytesPerMessage),
			formatInteger(bytes.batchHeaderBytes),
			formatBytes(bytes.batchHeaderBytesTotal),
			formatBytes(bytes.bytesSent),
			formatBytes(bytes.bytesReceived),
			formatNumber(bytes.bytesPerMessage),
			formatNumber(bytes.kbpsEstimate),
			formatLoss(result.lossPercent)
		)
	)
end

local function cpuUsPerMessage(seconds: number, messages: number): number
	if messages <= 0 then
		return 0
	end

	return seconds * 1000000 / messages
end

local function cpuMsPerFrame(seconds: number, frames: number): number
	if frames <= 0 then
		return 0
	end

	return seconds * 1000 / frames
end

local function kbPerMillionMessages(kilobytes: number, messages: number): number
	if messages <= 0 then
		return 0
	end

	return kilobytes * 1000000 / messages
end

local function averageBatchSize(result: Summary): number
	if result.serverCallbacks <= 0 then
		return 0
	end

	return result.batchTotal / result.serverCallbacks
end

local function printCpuRow(tool: string, result: Summary): ()
	print(
		string.format(
			"%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s",
			tool,
			formatNumber(cpuMsPerFrame(result.clientEnqueueSeconds, result.clientEnqueueFrames)),
			formatNumber(cpuUsPerMessage(result.clientEnqueueSeconds, result.sent)),
			formatNumber(cpuMsPerFrame(result.serverReceiveFrameSeconds, result.serverReceiveFrames)),
			formatNumber(result.serverReceiveMaxFrameSeconds * 1000),
			formatNumber(cpuUsPerMessage(result.serverCallbackSeconds, result.received)),
			formatInteger(result.serverCallbacks),
			formatInteger(result.serverCallbackSamples),
			formatNumber(result.serverCallbackSeconds * 1000)
		)
	)
end

local function printMarkdownCpuRow(tool: string, result: Summary): ()
	print(
		string.format(
			"| %s | %s | %s | %s | %s | %s | %s | %s | %s |",
			tool,
			formatNumber(cpuMsPerFrame(result.clientEnqueueSeconds, result.clientEnqueueFrames)),
			formatNumber(cpuUsPerMessage(result.clientEnqueueSeconds, result.sent)),
			formatNumber(cpuMsPerFrame(result.serverReceiveFrameSeconds, result.serverReceiveFrames)),
			formatNumber(result.serverReceiveMaxFrameSeconds * 1000),
			formatNumber(cpuUsPerMessage(result.serverCallbackSeconds, result.received)),
			formatInteger(result.serverCallbacks),
			formatInteger(result.serverCallbackSamples),
			formatNumber(result.serverCallbackSeconds * 1000)
		)
	)
end

local function printMemoryRow(tool: string, result: Summary): ()
	print(
		string.format(
			"%s\t%s\t%s\t%s\t%s",
			tool,
			formatNumber(result.clientHeapDeltaKb),
			formatNumber(result.serverHeapDeltaKb),
			formatNumber(kbPerMillionMessages(result.clientHeapDeltaKb, result.sent)),
			formatNumber(kbPerMillionMessages(result.serverHeapDeltaKb, result.received))
		)
	)
end

local function printMarkdownMemoryRow(tool: string, result: Summary): ()
	print(
		string.format(
			"| %s | %s | %s | %s | %s |",
			tool,
			formatNumber(result.clientHeapDeltaKb),
			formatNumber(result.serverHeapDeltaKb),
			formatNumber(kbPerMillionMessages(result.clientHeapDeltaKb, result.sent)),
			formatNumber(kbPerMillionMessages(result.serverHeapDeltaKb, result.received))
		)
	)
end

local function printBatchRow(tool: string, result: Summary): ()
	print(
		string.format(
			"%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s",
			tool,
			formatInteger(result.serverCallbacks),
			formatNumber(averageBatchSize(result)),
			formatInteger(result.batchMin),
			formatInteger(result.batchMax),
			formatInteger(result.batchOne),
			formatInteger(result.batchSmall),
			formatInteger(result.batchMedium),
			formatInteger(result.batchLarge),
			formatInteger(result.batchHuge)
		)
	)
end

local function printMarkdownBatchRow(tool: string, result: Summary): ()
	print(
		string.format(
			"| %s | %s | %s | %s | %s | %s | %s | %s | %s | %s |",
			tool,
			formatInteger(result.serverCallbacks),
			formatNumber(averageBatchSize(result)),
			formatInteger(result.batchMin),
			formatInteger(result.batchMax),
			formatInteger(result.batchOne),
			formatInteger(result.batchSmall),
			formatInteger(result.batchMedium),
			formatInteger(result.batchLarge),
			formatInteger(result.batchHuge)
		)
	)
end

local function warmupCase(tool: string, caseConfig, payload: any, sendPayload: (any) -> ()): ()
	local warmupFrames = Config.warmupFrames or 0
	if warmupFrames <= 0 then
		return
	end

	for _frame = 1, warmupFrames do
		RunService.Heartbeat:Wait()

		for _index = 1, Config.firesPerFrame do
			sendPayload(payload)
		end

		flushTool(tool)
	end

	local settleSeconds = Config.warmupSettleSeconds or 0
	if settleSeconds > 0 then
		task.wait(settleSeconds)
	end
end

local function runCase(tool: string, caseConfig): Summary
	local payload = Payloads.get(caseConfig.payload)
	local sendPayload = resolveSender(tool, caseConfig)

	warmupCase(tool, caseConfig, payload, sendPayload)

	local runId = startRun(tool, caseConfig.name)
	local fpsSamples = {}
	local sent = 0
	local sentBatches = 0
	local clientHeapStartKb = luaHeapKb()
	local startedAt = os.clock()
	local deadline = startedAt + Config.durationSeconds
	local hasSentFrame = false
	local clientEnqueueSeconds = 0
	local clientEnqueueFrames = 0

	VNet.resetStats()

	while os.clock() < deadline do
		local delta = RunService.Heartbeat:Wait()

		if hasSentFrame and delta > 0 then
			table.insert(fpsSamples, 1 / delta)
		end

		local enqueueStartedAt = os.clock()
		for _index = 1, Config.firesPerFrame do
			sendPayload(payload)
		end
		clientEnqueueSeconds += os.clock() - enqueueStartedAt
		clientEnqueueFrames += 1

		sent += Config.firesPerFrame
		sentBatches += 1
		hasSentFrame = true
	end

	local flushStartedAt = os.clock()
	flushTool(tool)
	clientEnqueueSeconds += os.clock() - flushStartedAt

	local clientHeapEndKb = luaHeapKb()
	local clientSeconds = os.clock() - startedAt
	local clientVNetStats = if tool == "VNet" or tool == "VNetImmediate" or tool == "VNetDirect" then VNet.stats() else nil
	local serverResult = finishRun(runId, sent)
	cleanupRun(runId)

	local received = if serverResult and typeof(serverResult.received) == "number" then serverResult.received else 0
	local lossPercent = if sent > 0 then math.max(0, (sent - received) / sent * 100) else 0
	local serverVNetStats = if serverResult then serverResult.vnetStats else nil
	local serverCallbacks = if serverResult and typeof(serverResult.serverCallbacks) == "number" then serverResult.serverCallbacks else 0
	local serverCallbackSamples = if serverResult and typeof(serverResult.serverCallbackSamples) == "number" then serverResult.serverCallbackSamples else 0
	local serverCallbackSeconds = if serverResult and typeof(serverResult.serverCallbackSeconds) == "number" then serverResult.serverCallbackSeconds else 0
	local serverReceiveFrameSeconds = if serverResult and typeof(serverResult.serverReceiveFrameSeconds) == "number" then serverResult.serverReceiveFrameSeconds else 0
	local serverReceiveMaxFrameSeconds = if serverResult and typeof(serverResult.serverReceiveMaxFrameSeconds) == "number" then serverResult.serverReceiveMaxFrameSeconds else 0
	local serverReceiveFrames = if serverResult and typeof(serverResult.serverReceiveFrames) == "number" then serverResult.serverReceiveFrames else 0
	local serverHeapStartKb = if serverResult and typeof(serverResult.serverHeapStartKb) == "number" then serverResult.serverHeapStartKb else 0
	local serverHeapEndKb = if serverResult and typeof(serverResult.serverHeapEndKb) == "number" then serverResult.serverHeapEndKb else 0
	local serverHeapDeltaKb = if serverResult and typeof(serverResult.serverHeapDeltaKb) == "number" then serverResult.serverHeapDeltaKb else 0
	local batchTotal = if serverResult and typeof(serverResult.batchTotal) == "number" then serverResult.batchTotal else received
	local batchMin = if serverResult and typeof(serverResult.batchMin) == "number" then serverResult.batchMin else 0
	local batchMax = if serverResult and typeof(serverResult.batchMax) == "number" then serverResult.batchMax else 0
	local batchOne = if serverResult and typeof(serverResult.batchOne) == "number" then serverResult.batchOne else 0
	local batchSmall = if serverResult and typeof(serverResult.batchSmall) == "number" then serverResult.batchSmall else 0
	local batchMedium = if serverResult and typeof(serverResult.batchMedium) == "number" then serverResult.batchMedium else 0
	local batchLarge = if serverResult and typeof(serverResult.batchLarge) == "number" then serverResult.batchLarge else 0
	local batchHuge = if serverResult and typeof(serverResult.batchHuge) == "number" then serverResult.batchHuge else 0
	local byteStats = ByteCounter.summarize(
		tool,
		caseConfig.name,
		sent,
		received,
		sentBatches,
		clientSeconds,
		Config.firesPerFrame,
		clientVNetStats,
		serverVNetStats
	)

	return {
		tool = tool,
		caseName = caseConfig.name,
		sent = sent,
		received = received,
		lossPercent = lossPercent,
		serverSeconds = if serverResult and typeof(serverResult.serverSeconds) == "number" then serverResult.serverSeconds else 0,
		clientSeconds = clientSeconds,
		clientEnqueueSeconds = clientEnqueueSeconds,
		clientEnqueueFrames = clientEnqueueFrames,
		serverCallbackSeconds = serverCallbackSeconds,
		serverCallbacks = serverCallbacks,
		serverCallbackSamples = serverCallbackSamples,
		serverReceiveFrameSeconds = serverReceiveFrameSeconds,
		serverReceiveMaxFrameSeconds = serverReceiveMaxFrameSeconds,
		serverReceiveFrames = serverReceiveFrames,
		clientHeapStartKb = clientHeapStartKb,
		clientHeapEndKb = clientHeapEndKb,
		clientHeapDeltaKb = clientHeapEndKb - clientHeapStartKb,
		serverHeapStartKb = serverHeapStartKb,
		serverHeapEndKb = serverHeapEndKb,
		serverHeapDeltaKb = serverHeapDeltaKb,
		batchTotal = batchTotal,
		batchMin = batchMin,
		batchMax = batchMax,
		batchOne = batchOne,
		batchSmall = batchSmall,
		batchMedium = batchMedium,
		batchLarge = batchLarge,
		batchHuge = batchHuge,
		fps = fpsSamples,
		byteStats = byteStats,
	}
end

local function printCase(caseName: string, byTool: {[string]: Summary}): ()
	print("")
	print(caseName)
	print("Tool (FPS)\tMedian\tBest\tP80\tP90\tP95\tP99\tLoss (%)")

	for _, tool in ipairs(Config.methods) do
		local result = byTool[tool]
		if result then
			local metrics = metricSet(result.fps, true)
			print(
				string.format(
					"%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s",
					tool,
					formatNumber(metrics.median),
					formatNumber(metrics.p0),
					formatNumber(metrics.p80),
					formatNumber(metrics.p90),
					formatNumber(metrics.p95),
					formatNumber(metrics.p99),
					formatLoss(result.lossPercent)
				)
			)
		end
	end

	print("Tool (Bytes)\tMessages\tGroups\tPayload B/msg\tHeader B/group\tHeader Total\tBytes Sent\tBytes Recv\tBytes/msg\tEstimated Kbps\tLoss (%)")

	for _, tool in ipairs(Config.methods) do
		local result = byTool[tool]
		if result then
			printByteRow(tool, result)
		end
	end

	print("Tool (Timing)\tClient encode ms/frame\tClient encode us/msg\tServer receive ms/frame\tServer receive max ms/frame\tDecode/callback us/msg\tServer callbacks\tServer samples\tServer callback ms")

	for _, tool in ipairs(Config.methods) do
		local result = byTool[tool]
		if result then
			printCpuRow(tool, result)
		end
	end

	print("Tool (Memory)\tClient heap delta KiB\tServer heap delta KiB\tClient KiB/M msg\tServer KiB/M msg")

	for _, tool in ipairs(Config.methods) do
		local result = byTool[tool]
		if result then
			printMemoryRow(tool, result)
		end
	end

	print("Tool (Receive Shape)\tCallbacks\tAvg payloads/callback\tMin\tMax\tSize 1\t2-31\t32-127\t128-511\t512+")

	for _, tool in ipairs(Config.methods) do
		local result = byTool[tool]
		if result then
			printBatchRow(tool, result)
		end
	end
end

local function printMarkdownCase(caseName: string, byTool: {[string]: Summary}): ()
	print("")
	print("### " .. caseName)
	print("| Tool (FPS) | Median | Best | P80 | P90 | P95 | P99 | Loss (%) |")
	print("| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |")

	for _, tool in ipairs(Config.methods) do
		local result = byTool[tool]
		if result then
			printMetricRow(tool, metricSet(result.fps, true), result.lossPercent)
		end
	end

	print("| Tool | Messages | Groups | Payload B/Msg | Header B/Group | Header Total | Bytes Sent | Bytes Received | Bytes/Msg | Estimated Kbps | Loss |")
	print("| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |")

	for _, tool in ipairs(Config.methods) do
		local result = byTool[tool]
		if result then
			printMarkdownByteRow(tool, result)
		end
	end

	print("| Tool (Timing) | Client Encode ms/frame | Client Encode us/msg | Server Receive ms/frame | Server Receive max ms/frame | Decode/Callback us/msg | Server Callbacks | Server Samples | Server Callback ms |")
	print("| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |")

	for _, tool in ipairs(Config.methods) do
		local result = byTool[tool]
		if result then
			printMarkdownCpuRow(tool, result)
		end
	end

	print("| Tool (Memory) | Client Heap Delta KiB | Server Heap Delta KiB | Client KiB/M msg | Server KiB/M msg |")
	print("| --- | ---: | ---: | ---: | ---: |")

	for _, tool in ipairs(Config.methods) do
		local result = byTool[tool]
		if result then
			printMarkdownMemoryRow(tool, result)
		end
	end

	print("| Tool (Receive Shape) | Callbacks | Avg Payloads/Callback | Min | Max | Size 1 | 2-31 | 32-127 | 128-511 | 512+ |")
	print("| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |")

	for _, tool in ipairs(Config.methods) do
		local result = byTool[tool]
		if result then
			printMarkdownBatchRow(tool, result)
		end
	end
end

task.wait(2)
print("[VNetFrameBenchmark] Starting 1000 fires/frame for 10 seconds")

for _, caseConfig in ipairs(Config.cases) do
	results[caseConfig.name] = {}

	for _, tool in ipairs(Config.methods) do
		local result = runCase(tool, caseConfig)
		results[caseConfig.name][tool] = result

		print(
			string.format(
				"[VNetFrameBenchmark] %s %s sent=%d received=%d loss=%s client=%.3fs server=%.3fs fpsSamples=%d bytesSent=%d bytesRecv=%d bytesPerMsg=%.2f kbpsEstimate=%.2f encodeUsMsg=%.3f decodeCallbackUsMsg=%.3f serverReceiveMsFrame=%.3f clientHeapDeltaKb=%.2f serverHeapDeltaKb=%.2f avgBatch=%.2f",
				tool,
				caseConfig.name,
				result.sent,
				result.received,
				formatLoss(result.lossPercent),
				result.clientSeconds,
				result.serverSeconds,
				#result.fps,
				math.floor(result.byteStats.bytesSent + 0.5),
				math.floor(result.byteStats.bytesReceived + 0.5),
				result.byteStats.bytesPerMessage,
				result.byteStats.kbpsEstimate,
				cpuUsPerMessage(result.clientEnqueueSeconds, result.sent),
				cpuUsPerMessage(result.serverCallbackSeconds, result.received),
				cpuMsPerFrame(result.serverReceiveFrameSeconds, result.serverReceiveFrames),
				result.clientHeapDeltaKb,
				result.serverHeapDeltaKb,
				averageBatchSize(result)
			)
		)

		task.wait(Config.cooldownSeconds)
	end

	printCase(caseConfig.name, results[caseConfig.name])
end

print("")
print("[VNetFrameBenchmark] Markdown")

for _, caseConfig in ipairs(Config.cases) do
	printMarkdownCase(caseConfig.name, results[caseConfig.name])
end

print("[VNetFrameBenchmark] Done")
