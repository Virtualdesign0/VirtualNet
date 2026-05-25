--!strict

local FrameByteCounter = {}

export type ByteSummary = {
	messages: number,
	batches: number,
	payloadBytesPerMessage: number,
	batchHeaderBytes: number,
	batchHeaderBytesTotal: number,
	bytesSent: number,
	bytesReceived: number,
	bytesPerMessage: number,
	kbpsEstimate: number,
}

type ByteSpec = {
	payloadBytesPerMessage: number,
	batchHeaderBytes: number,
}

local VNET_PACKED_BATCH_HEADER_BYTES = 7 -- count:u32 + packetId:u16 + packedFlag:bool
local VNET_DIRECT_PACKET_HEADER_BYTES = 2 -- packetId:u16
local BLINK_BATCH_HEADER_BYTES = 0 -- Blink stores its event id in each message buffer.
local BYTENET_BATCH_HEADER_BYTES = 0

local SPECS: {[string]: {[string]: ByteSpec}} = {
	Booleans = {
		VNet = {
			payloadBytesPerMessage = 1,
			batchHeaderBytes = VNET_PACKED_BATCH_HEADER_BYTES,
		},
		VNetImmediate = {
			payloadBytesPerMessage = 1,
			batchHeaderBytes = VNET_DIRECT_PACKET_HEADER_BYTES,
		},
		VNetDirect = {
			payloadBytesPerMessage = 1,
			batchHeaderBytes = VNET_PACKED_BATCH_HEADER_BYTES,
		},
		Blink = {
			payloadBytesPerMessage = 2,
			batchHeaderBytes = BLINK_BATCH_HEADER_BYTES,
		},
		ByteNet = {
			payloadBytesPerMessage = 1,
			batchHeaderBytes = BYTENET_BATCH_HEADER_BYTES,
		},
	},

	Entities = {
		VNet = {
			payloadBytesPerMessage = 31,
			batchHeaderBytes = VNET_PACKED_BATCH_HEADER_BYTES,
		},
		VNetImmediate = {
			payloadBytesPerMessage = 31,
			batchHeaderBytes = VNET_DIRECT_PACKET_HEADER_BYTES,
		},
		VNetDirect = {
			payloadBytesPerMessage = 31,
			batchHeaderBytes = VNET_PACKED_BATCH_HEADER_BYTES,
		},
		Blink = {
			payloadBytesPerMessage = 32,
			batchHeaderBytes = BLINK_BATCH_HEADER_BYTES,
		},
		ByteNet = {
			payloadBytesPerMessage = 31,
			batchHeaderBytes = BYTENET_BATCH_HEADER_BYTES,
		},
	},

	QuantizedEntities = {
		VNet = {
			payloadBytesPerMessage = 19,
			batchHeaderBytes = VNET_PACKED_BATCH_HEADER_BYTES,
		},
		VNetImmediate = {
			payloadBytesPerMessage = 19,
			batchHeaderBytes = VNET_DIRECT_PACKET_HEADER_BYTES,
		},
		VNetDirect = {
			payloadBytesPerMessage = 19,
			batchHeaderBytes = VNET_PACKED_BATCH_HEADER_BYTES,
		},
		Blink = {
			payloadBytesPerMessage = 32,
			batchHeaderBytes = BLINK_BATCH_HEADER_BYTES,
		},
		ByteNet = {
			payloadBytesPerMessage = 31,
			batchHeaderBytes = BYTENET_BATCH_HEADER_BYTES,
		},
	},
}

local function statNumber(stats: any, key: string): number?
	if typeof(stats) ~= "table" then
		return nil
	end

	local value = stats[key]
	if typeof(value) == "number" and value > 0 then
		return value
	end

	return nil
end

local function estimateBatches(messages: number, firesPerFrame: number): number
	if messages <= 0 then
		return 0
	end

	return math.ceil(messages / math.max(1, firesPerFrame))
end

local function resolveSpec(tool: string, caseName: string): ByteSpec
	local byTool = SPECS[caseName]
	if not byTool then
		error("[VNetFrameBenchmark]: Missing byte spec for case " .. caseName, 3)
	end

	local spec = byTool[tool]
	if not spec then
		error("[VNetFrameBenchmark]: Missing byte spec for " .. tool .. " " .. caseName, 3)
	end

	return spec
end

function FrameByteCounter.summarize(
	tool: string,
	caseName: string,
	sent: number,
	received: number,
	sentBatches: number,
	durationSeconds: number,
	firesPerFrame: number,
	clientVNetStats: any?,
	serverVNetStats: any?
): ByteSummary
	local spec = resolveSpec(tool, caseName)
	local payloadBytesSent = sent * spec.payloadBytesPerMessage
	local payloadBytesReceived = received * spec.payloadBytesPerMessage
	local resolvedSentBatches = sentBatches
	local resolvedReceivedBatches = estimateBatches(received, firesPerFrame)

	if tool == "VNet" or tool == "VNetDirect" then
		payloadBytesSent = statNumber(clientVNetStats, "sentPackedBytes") or payloadBytesSent
		payloadBytesReceived = statNumber(serverVNetStats, "receivedPackedBytes") or payloadBytesReceived
		resolvedSentBatches = statNumber(clientVNetStats, "sentPackedBatches") or resolvedSentBatches
		resolvedReceivedBatches = statNumber(serverVNetStats, "receivedPackedBatches") or resolvedReceivedBatches
	elseif tool == "VNetImmediate" then
		payloadBytesSent = statNumber(clientVNetStats, "sentPackedBytes") or payloadBytesSent
		payloadBytesReceived = statNumber(serverVNetStats, "receivedPackedBytes") or payloadBytesReceived
		resolvedSentBatches = statNumber(clientVNetStats, "sentDirectPackets") or sent
		resolvedReceivedBatches = statNumber(serverVNetStats, "receivedDirectPackets") or received
	end

	local batchHeaderBytesTotal = resolvedSentBatches * spec.batchHeaderBytes
	local bytesSent = payloadBytesSent + batchHeaderBytesTotal
	local bytesReceived = payloadBytesReceived + resolvedReceivedBatches * spec.batchHeaderBytes
	local bytesPerMessage = if sent > 0 then bytesSent / sent else 0
	local kbpsEstimate = if durationSeconds > 0 then (bytesSent * 8) / 1000 / durationSeconds else 0

	return {
		messages = sent,
		batches = resolvedSentBatches,
		payloadBytesPerMessage = spec.payloadBytesPerMessage,
		batchHeaderBytes = spec.batchHeaderBytes,
		batchHeaderBytesTotal = batchHeaderBytesTotal,
		bytesSent = bytesSent,
		bytesReceived = bytesReceived,
		bytesPerMessage = bytesPerMessage,
		kbpsEstimate = kbpsEstimate,
	}
end

return table.freeze(FrameByteCounter)
