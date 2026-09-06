--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Bridge = require(script.Parent.Parent.Wire.Bridge)
local Config = require(script.Parent.Config)
local FrameStore = require(script.Parent.FrameStore)
local PackedStore = require(script.Parent.PackedStore)
local Protocol = require(script.Parent.Parent.Wire.Protocol)
local Stats = require(script.Parent.Parent.Diagnostics.Stats)

export type Lane = "reliable" | "fast"
type Batch = FrameStore.FrameBatch
type PackedBatch = PackedStore.PackedBatch

local Transport = {}

local CONTROL_REJECT_ID = 0
local CONTROL_JOIN_SYNC_ID = -1
local IS_SERVER = RunService:IsServer()
local IS_RUNNING = RunService:IsRunning()
local createBuffer = (buffer :: any)["create"]
local writeU32 = (buffer :: any)["writeu32"]
local bufferLen = (buffer :: any)["len"]
local clientDirty = false
local serverDirty = false

local clientQueues: { [Lane]: Batch } = {
	reliable = FrameStore.new(),
	fast = FrameStore.new(),
}

local targetQueues: { [Lane]: { [Player]: Batch } } = {
	reliable = {},
	fast = {},
}

local broadcastQueues: { [Lane]: Batch } = {
	reliable = FrameStore.new(),
	fast = FrameStore.new(),
}

local clientPackedQueues: { [Lane]: { [number]: PackedBatch } } = {
	reliable = {},
	fast = {},
}

local targetPackedQueues: { [Lane]: { [Player]: { [number]: PackedBatch } } } = {
	reliable = {},
	fast = {},
}

local broadcastPackedQueues: { [Lane]: { [number]: PackedBatch } } = {
	reliable = {},
	fast = {},
}

local clientPackedDirty: { [Lane]: boolean } = {
	reliable = false,
	fast = false,
}

local clientFrameDirty: { [Lane]: boolean } = {
	reliable = false,
	fast = false,
}

local targetPackedDirty: { [Lane]: boolean } = {
	reliable = false,
	fast = false,
}

local targetFrameDirty: { [Lane]: boolean } = {
	reliable = false,
	fast = false,
}

local broadcastPackedDirty: { [Lane]: boolean } = {
	reliable = false,
	fast = false,
}

local broadcastFrameDirty: { [Lane]: boolean } = {
	reliable = false,
	fast = false,
}

local function assertPlayer(player: any): Player
	-- Cast after the typeof check rather than narrowed by it: the newer solver
	-- does not carry a typeof narrowing onto an any, so IsA would read as
	-- uncallable. The check above is what makes the cast true.
	if typeof(player) ~= "Instance" then
		error("[VNet]: Expected a Player target.", 3)
	end

	local instance = player :: Instance

	if not instance:IsA("Player") then
		error("[VNet]: Expected a Player target.", 3)
	end

	return instance :: Player
end

local function sendBatchToServer(lane: Lane, frames: Batch): ()
	local ids: any = frames.ids

	if frames.singleId > 0 then
		ids = frames.singleId
	end

	Bridge.remote(lane):FireServer(frames.count, ids, frames.payloads)

	if Config.stats then
		Stats.bump("queuedPackets", frames.count)
		Stats.bump("sentBatches")
		Stats.bump("sentFrameBatches")
		Stats.bump("sentPackets", frames.count)
	end
end

local function sendBatchToPlayer(lane: Lane, player: Player, frames: Batch): ()
	local ids: any = frames.ids

	if frames.singleId > 0 then
		ids = frames.singleId
	end

	Bridge.remote(lane):FireClient(player, frames.count, ids, frames.payloads)

	if Config.stats then
		Stats.bump("queuedPackets", frames.count)
		Stats.bump("sentBatches")
		Stats.bump("sentFrameBatches")
		Stats.bump("sentPackets", frames.count)
	end
end

local function sendBatchToAll(lane: Lane, frames: Batch): ()
	local ids: any = frames.ids

	if frames.singleId > 0 then
		ids = frames.singleId
	end

	Bridge.remote(lane):FireAllClients(frames.count, ids, frames.payloads)

	if Config.stats then
		Stats.bump("queuedPackets", frames.count)
		Stats.bump("sentBatches")
		Stats.bump("sentFrameBatches")
		Stats.bump("sentPackets", frames.count)
	end
end

local function sendPackedToServer(lane: Lane, id: number, count: number, payloads: buffer): ()
	Bridge.remote(lane):FireServer(count, id, payloads, true)

	if Config.stats then
		local bytes = bufferLen(payloads)

		Stats.bump("queuedPackets", count)
		Stats.bump("sentBatches")
		Stats.bump("sentPackedBatches")
		Stats.bump("sentPackets", count)
		Stats.bump("sentBytes", bytes)
		Stats.bump("sentPackedBytes", bytes)
	end
end

local function sendPackedToPlayer(
	lane: Lane,
	player: Player,
	id: number,
	count: number,
	payloads: buffer
): ()
	Bridge.remote(lane):FireClient(player, count, id, payloads, true)

	if Config.stats then
		local bytes = bufferLen(payloads)

		Stats.bump("queuedPackets", count)
		Stats.bump("sentBatches")
		Stats.bump("sentPackedBatches")
		Stats.bump("sentPackets", count)
		Stats.bump("sentBytes", bytes)
		Stats.bump("sentPackedBytes", bytes)
	end
end

local function sendPackedToAll(lane: Lane, id: number, count: number, payloads: buffer): ()
	Bridge.remote(lane):FireAllClients(count, id, payloads, true)

	if Config.stats then
		local bytes = bufferLen(payloads)

		Stats.bump("queuedPackets", count)
		Stats.bump("sentBatches")
		Stats.bump("sentPackedBatches")
		Stats.bump("sentPackets", count)
		Stats.bump("sentBytes", bytes)
		Stats.bump("sentPackedBytes", bytes)
	end
end

local function bumpSentDirect(): ()
	if Config.stats then
		Stats.bump("queuedPackets")
		Stats.bump("sentPackets")
		Stats.bump("sentDirectPackets")
	end
end

local function bumpSentPackedDirect(payloads: buffer): ()
	if Config.stats then
		local bytes = bufferLen(payloads)

		Stats.bump("queuedPackets")
		Stats.bump("sentPackets")
		Stats.bump("sentDirectPackets")
		Stats.bump("sentPackedDirectPackets")
		Stats.bump("sentBytes", bytes)
		Stats.bump("sentPackedBytes", bytes)
	end
end

local function encodePackedOne(unit: any, payload: any): buffer
	local fixedSize = unit.size

	if fixedSize then
		local target = createBuffer(fixedSize)

		unit.write(target, 0, payload)

		return target
	end

	local writePacked = unit.writePacked

	if writePacked then
		local batch = PackedStore.new()
		local writePackedFn = writePacked :: (any, any) -> ()

		writePackedFn(batch, payload)

		return PackedStore.read(batch)
	end

	local size = unit.measure(payload)
	local target = createBuffer(size)

	unit.write(target, 0, payload)

	return target
end

local function sendOneToServer(lane: Lane, id: number, payload: any): ()
	Bridge.remote(lane):FireServer(Protocol.SINGLE, id, payload)
	bumpSentDirect()
end

local function sendPackedOneToServer(lane: Lane, id: number, unit: any, payload: any): ()
	local payloads = encodePackedOne(unit, payload)

	Bridge.remote(lane):FireServer(Protocol.PACKED_SINGLE, id, payloads)
	bumpSentPackedDirect(payloads)
end

local function sendOneToPlayer(lane: Lane, player: Player, id: number, payload: any): ()
	Bridge.remote(lane):FireClient(player, Protocol.SINGLE, id, payload)
	bumpSentDirect()
end

local function sendPackedOneToPlayer(
	lane: Lane,
	player: Player,
	id: number,
	unit: any,
	payload: any
): ()
	local payloads = encodePackedOne(unit, payload)

	Bridge.remote(lane):FireClient(player, Protocol.PACKED_SINGLE, id, payloads)
	bumpSentPackedDirect(payloads)
end

local function sendOneToAll(lane: Lane, id: number, payload: any): ()
	Bridge.remote(lane):FireAllClients(Protocol.SINGLE, id, payload)
	bumpSentDirect()
end

local function sendPackedOneToAll(lane: Lane, id: number, unit: any, payload: any): ()
	local payloads = encodePackedOne(unit, payload)

	Bridge.remote(lane):FireAllClients(Protocol.PACKED_SINGLE, id, payloads)
	bumpSentPackedDirect(payloads)
end

local function getPacked(owner: { [number]: PackedBatch }, id: number): PackedBatch
	local packet = owner[id]

	if not packet then
		packet = PackedStore.new()
		owner[id] = packet
	end

	return packet
end

local function getPlayerPacked(
	owner: { [Player]: { [number]: PackedBatch } },
	player: Player
): { [number]: PackedBatch }
	local packets = owner[player]

	if not packets then
		packets = {}
		owner[player] = packets
	end

	return packets
end

local function flushPackedServer(lane: Lane): ()
	if broadcastPackedDirty[lane] then
		broadcastPackedDirty[lane] = false

		for id, batch in broadcastPackedQueues[lane] do
			if batch.count > 0 then
				sendPackedToAll(lane, id, batch.count, PackedStore.read(batch))
				PackedStore.reset(batch)
			end
		end
	end

	if targetPackedDirty[lane] then
		targetPackedDirty[lane] = false

		for player, packets in targetPackedQueues[lane] do
			for id, batch in packets do
				if batch.count > 0 then
					sendPackedToPlayer(lane, player, id, batch.count, PackedStore.read(batch))
					PackedStore.reset(batch)
				end
			end
		end
	end
end

local function flushPackedClient(lane: Lane): ()
	if not clientPackedDirty[lane] then
		return
	end

	clientPackedDirty[lane] = false

	for id, batch in clientPackedQueues[lane] do
		if batch.count > 0 then
			sendPackedToServer(lane, id, batch.count, PackedStore.read(batch))
			PackedStore.reset(batch)
		end
	end
end

local function flushServerLane(lane: Lane): ()
	flushPackedServer(lane)

	if broadcastFrameDirty[lane] then
		broadcastFrameDirty[lane] = false

		local broadcast = broadcastQueues[lane]
		if broadcast.count > 0 then
			sendBatchToAll(lane, broadcast)
			FrameStore.reset(broadcast)
		end
	end

	if targetFrameDirty[lane] then
		targetFrameDirty[lane] = false

		local queues = targetQueues[lane]
		for player, frames in queues do
			if frames.count > 0 then
				sendBatchToPlayer(lane, player, frames)
				FrameStore.reset(frames)
			end
		end
	end
end

local function flushClientLane(lane: Lane): ()
	flushPackedClient(lane)

	if clientFrameDirty[lane] then
		clientFrameDirty[lane] = false

		local frames = clientQueues[lane]
		if frames.count > 0 then
			sendBatchToServer(lane, frames)
			FrameStore.reset(frames)
		end
	end
end

function Transport.flush(): ()
	if not IS_RUNNING then
		return
	end

	if IS_SERVER then
		if not serverDirty then
			return
		end

		serverDirty = false
		flushServerLane("reliable")
		flushServerLane("fast")
		return
	end

	if not clientDirty then
		return
	end

	clientDirty = false
	flushClientLane("reliable")
	flushClientLane("fast")
end

local function flushClientIfDirty(): ()
	if clientDirty then
		Transport.flush()
	end
end

local function flushServerIfDirty(): ()
	if serverDirty then
		Transport.flush()
	end
end

function Transport.toServerPackedOne(
	lane: Lane,
	id: number,
	unit: any,
	payload: any,
	immediate: boolean?
): ()
	if immediate then
		flushClientIfDirty()
		sendPackedOneToServer(lane, id, unit, payload)
		return
	end

	PackedStore.push(getPacked(clientPackedQueues[lane], id), unit, payload)
	clientDirty = true
	clientPackedDirty[lane] = true
end

function Transport.toServerPackedMany(
	lane: Lane,
	id: number,
	unit: any,
	payloads: { any },
	immediate: boolean?
): ()
	PackedStore.pushMany(getPacked(clientPackedQueues[lane], id), unit, payloads)
	clientDirty = true
	clientPackedDirty[lane] = true

	if immediate then
		Transport.flush()
	end
end

function Transport.serverPackedWriter(
	lane: Lane,
	id: number,
	unit: any,
	immediate: boolean?,
	direct: boolean?
): (any) -> ()
	local write = unit.write
	local fixedSize = unit.size

	if direct and fixedSize then
		local remote = Bridge.remote(lane)

		return function(payload: any): ()
			local payloads = createBuffer(fixedSize)

			write(payloads, 0, payload)
			remote:FireServer(Protocol.PACKED_SINGLE, id, payloads)
			bumpSentPackedDirect(payloads)
		end
	end

	if direct then
		local remote = Bridge.remote(lane)

		return function(payload: any): ()
			local payloads = encodePackedOne(unit, payload)

			remote:FireServer(Protocol.PACKED_SINGLE, id, payloads)
			bumpSentPackedDirect(payloads)
		end
	end

	local packet = getPacked(clientPackedQueues[lane], id)
	local reserve = PackedStore.reserve

	if immediate and fixedSize then
		local remote = Bridge.remote(lane)

		return function(payload: any): ()
			flushClientIfDirty()

			local payloads = createBuffer(fixedSize)

			write(payloads, 0, payload)
			remote:FireServer(Protocol.PACKED_SINGLE, id, payloads)
			bumpSentPackedDirect(payloads)
		end
	end

	if unit.writePacked then
		if immediate then
			return function(payload: any): ()
				flushClientIfDirty()
				sendPackedOneToServer(lane, id, unit, payload)
			end
		end

		return function(payload: any): ()
			(unit :: any)["writePacked"](packet, payload)
			clientDirty = true
			clientPackedDirty[lane] = true
		end
	end

	if fixedSize then
		return function(payload: any): ()
			local cursor = packet.size
			local needed = cursor + fixedSize

			if needed > packet.capacity then
				reserve(packet, needed)
			end

			packet.size = write(packet.data, cursor, payload)
			packet.count += 1
			clientDirty = true
			clientPackedDirty[lane] = true
		end
	end

	local measure = unit.measure

	if immediate then
		return function(payload: any): ()
			flushClientIfDirty()
			sendPackedOneToServer(lane, id, unit, payload)
		end
	end

	return function(payload: any): ()
		local size = measure(payload)
		local cursor = packet.size
		local needed = cursor + size

		if needed > packet.capacity then
			reserve(packet, needed)
		end

		packet.size = write(packet.data, cursor, payload)
		packet.count += 1
		clientDirty = true
		clientPackedDirty[lane] = true
	end
end

function Transport.serverU32Writer(
	lane: Lane,
	id: number,
	immediate: boolean?,
	direct: boolean?
): (number) -> ()
	if direct then
		local remote = Bridge.remote(lane)

		return function(payload: number): ()
			local payloads = createBuffer(4)

			writeU32(payloads, 0, payload)
			remote:FireServer(Protocol.PACKED_SINGLE, id, payloads)
			bumpSentPackedDirect(payloads)
		end
	end

	local packet = getPacked(clientPackedQueues[lane], id)
	local reserve = PackedStore.reserve

	if immediate then
		local remote = Bridge.remote(lane)

		return function(payload: number): ()
			local payloads = createBuffer(4)

			writeU32(payloads, 0, payload)
			flushClientIfDirty()
			remote:FireServer(Protocol.PACKED_SINGLE, id, payloads)
			bumpSentPackedDirect(payloads)
		end
	end

	return function(payload: number): ()
		local cursor = packet.size
		local needed = cursor + 4

		if needed > packet.capacity then
			reserve(packet, needed)
		end

		writeU32(packet.data, cursor, payload)
		packet.size = needed
		packet.count += 1
		clientDirty = true
		clientPackedDirty[lane] = true
	end
end

function Transport.serverWriter(lane: Lane, id: number): (any) -> ()
	local remote = Bridge.remote(lane)

	return function(payload: any): ()
		remote:FireServer(Protocol.SINGLE, id, payload)
		bumpSentDirect()
	end
end

function Transport.toServer(lane: Lane, id: number, payload: any, immediate: boolean?): ()
	if immediate then
		flushClientIfDirty()
		sendOneToServer(lane, id, payload)
		return
	end

	FrameStore.push(clientQueues[lane], id, payload)
	clientDirty = true
	clientFrameDirty[lane] = true
end

function Transport.toServerMany(lane: Lane, id: number, payloads: { any }, immediate: boolean?): ()
	FrameStore.pushMany(clientQueues[lane], id, payloads)
	clientDirty = true
	clientFrameDirty[lane] = true

	if immediate then
		Transport.flush()
	end
end

function Transport.toServerPacked(lane: Lane, id: number, count: number, payloads: buffer): ()
	Transport.flush()
	sendPackedToServer(lane, id, count, payloads)
end

function Transport.toServerU32(lane: Lane, id: number, values: { any }): ()
	Transport.flush()

	local count = #values
	local payloads = createBuffer(count * 4)
	local cursor = 0

	for index = 1, count do
		writeU32(payloads, cursor, values[index])
		cursor += 4
	end

	sendPackedToServer(lane, id, count, payloads)
end

function Transport.toPlayerPackedOne(
	lane: Lane,
	player: Player,
	id: number,
	unit: any,
	payload: any,
	immediate: boolean?,
	direct: boolean?
): ()
	player = assertPlayer(player)

	if direct then
		sendPackedOneToPlayer(lane, player, id, unit, payload)
		return
	end

	if immediate then
		flushServerIfDirty()
		sendPackedOneToPlayer(lane, player, id, unit, payload)
		return
	end

	local packets = getPlayerPacked(targetPackedQueues[lane], player)

	PackedStore.push(getPacked(packets, id), unit, payload)
	serverDirty = true
	targetPackedDirty[lane] = true
end

function Transport.toPlayerPackedMany(
	lane: Lane,
	player: Player,
	id: number,
	unit: any,
	payloads: { any },
	immediate: boolean?
): ()
	local packets = getPlayerPacked(targetPackedQueues[lane], assertPlayer(player))

	PackedStore.pushMany(getPacked(packets, id), unit, payloads)
	serverDirty = true
	targetPackedDirty[lane] = true

	if immediate then
		Transport.flush()
	end
end

function Transport.toPlayer(
	lane: Lane,
	player: Player,
	id: number,
	payload: any,
	immediate: boolean?,
	direct: boolean?
): ()
	player = assertPlayer(player)

	if direct then
		sendOneToPlayer(lane, player, id, payload)
		return
	end

	if immediate then
		flushServerIfDirty()
		sendOneToPlayer(lane, player, id, payload)
		return
	end

	FrameStore.pushFor(targetQueues[lane], player, id, payload)
	serverDirty = true
	targetFrameDirty[lane] = true
end

function Transport.toPlayerMany(
	lane: Lane,
	player: Player,
	id: number,
	payloads: { any },
	immediate: boolean?
): ()
	FrameStore.pushManyFor(targetQueues[lane], assertPlayer(player), id, payloads)
	serverDirty = true
	targetFrameDirty[lane] = true

	if immediate then
		Transport.flush()
	end
end

function Transport.toPlayerPacked(
	lane: Lane,
	player: Player,
	id: number,
	count: number,
	payloads: buffer
): ()
	Transport.flush()
	sendPackedToPlayer(lane, assertPlayer(player), id, count, payloads)
end

function Transport.toAllPackedOne(
	lane: Lane,
	id: number,
	unit: any,
	payload: any,
	immediate: boolean?
): ()
	if immediate then
		flushServerIfDirty()
		sendPackedOneToAll(lane, id, unit, payload)
		return
	end

	PackedStore.push(getPacked(broadcastPackedQueues[lane], id), unit, payload)
	serverDirty = true
	broadcastPackedDirty[lane] = true
end

function Transport.toAllPackedMany(
	lane: Lane,
	id: number,
	unit: any,
	payloads: { any },
	immediate: boolean?
): ()
	PackedStore.pushMany(getPacked(broadcastPackedQueues[lane], id), unit, payloads)
	serverDirty = true
	broadcastPackedDirty[lane] = true

	if immediate then
		Transport.flush()
	end
end

function Transport.toAll(lane: Lane, id: number, payload: any, immediate: boolean?): ()
	if immediate then
		flushServerIfDirty()
		sendOneToAll(lane, id, payload)
		return
	end

	FrameStore.push(broadcastQueues[lane], id, payload)
	serverDirty = true
	broadcastFrameDirty[lane] = true
end

function Transport.toAllMany(lane: Lane, id: number, payloads: { any }, immediate: boolean?): ()
	FrameStore.pushMany(broadcastQueues[lane], id, payloads)
	serverDirty = true
	broadcastFrameDirty[lane] = true

	if immediate then
		Transport.flush()
	end
end

function Transport.toAllPacked(lane: Lane, id: number, count: number, payloads: buffer): ()
	Transport.flush()
	sendPackedToAll(lane, id, count, payloads)
end

function Transport.rejectToPlayer(player: Player, id: number, reason: any): ()
	Transport.flush()
	Bridge.remote("reliable"):FireClient(assertPlayer(player), 1, CONTROL_REJECT_ID, {
		{
			id = id,
			reason = reason,
		},
	}, false)

	if Config.stats then
		Stats.bump("queuedPackets")
		Stats.bump("sentBatches")
		Stats.bump("sentFrameBatches")
		Stats.bump("sentPackets")
	end
end

function Transport.syncToPlayer(player: Player, payload: any): ()
	Transport.flush()
	Bridge.remote("reliable"):FireClient(assertPlayer(player), 1, CONTROL_JOIN_SYNC_ID, {
		payload,
	}, false)

	if Config.stats then
		Stats.bump("queuedPackets")
		Stats.bump("sentBatches")
		Stats.bump("sentFrameBatches")
		Stats.bump("sentPackets")
	end
end

function Transport.toList(
	lane: Lane,
	players: { Player },
	id: number,
	payload: any,
	immediate: boolean?
): ()
	if immediate then
		flushServerIfDirty()

		for _, player in ipairs(players) do
			if typeof(player) == "Instance" and player:IsA("Player") then
				sendOneToPlayer(lane, player, id, payload)
			end
		end

		return
	end

	for _, player in ipairs(players) do
		if typeof(player) == "Instance" and player:IsA("Player") then
			FrameStore.pushFor(targetQueues[lane], player, id, payload)
			serverDirty = true
			targetFrameDirty[lane] = true
		end
	end

	if immediate then
		Transport.flush()
	end
end

function Transport.toListMany(
	lane: Lane,
	players: { Player },
	id: number,
	payloads: { any },
	immediate: boolean?
): ()
	for _, player in ipairs(players) do
		if typeof(player) == "Instance" and player:IsA("Player") then
			FrameStore.pushManyFor(targetQueues[lane], player, id, payloads)
			serverDirty = true
			targetFrameDirty[lane] = true
		end
	end

	if immediate then
		Transport.flush()
	end
end

function Transport.toListPackedOne(
	lane: Lane,
	players: { Player },
	id: number,
	unit: any,
	payload: any,
	immediate: boolean?
): ()
	if immediate then
		flushServerIfDirty()

		for _, player in ipairs(players) do
			if typeof(player) == "Instance" and player:IsA("Player") then
				sendPackedOneToPlayer(lane, player, id, unit, payload)
			end
		end

		return
	end

	for _, player in ipairs(players) do
		if typeof(player) == "Instance" and player:IsA("Player") then
			PackedStore.push(
				getPacked(getPlayerPacked(targetPackedQueues[lane], player), id),
				unit,
				payload
			)
			serverDirty = true
			targetPackedDirty[lane] = true
		end
	end

	if immediate then
		Transport.flush()
	end
end

function Transport.toListPackedMany(
	lane: Lane,
	players: { Player },
	id: number,
	unit: any,
	payloads: { any },
	immediate: boolean?
): ()
	for _, player in ipairs(players) do
		if typeof(player) == "Instance" and player:IsA("Player") then
			PackedStore.pushMany(
				getPacked(getPlayerPacked(targetPackedQueues[lane], player), id),
				unit,
				payloads
			)
			serverDirty = true
			targetPackedDirty[lane] = true
		end
	end

	if immediate then
		Transport.flush()
	end
end

function Transport.toExcept(
	lane: Lane,
	except: Player,
	id: number,
	payload: any,
	immediate: boolean?
): ()
	except = assertPlayer(except)

	if immediate then
		flushServerIfDirty()

		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= except then
				sendOneToPlayer(lane, player, id, payload)
			end
		end

		return
	end

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= except then
			FrameStore.pushFor(targetQueues[lane], player, id, payload)
			serverDirty = true
			targetFrameDirty[lane] = true
		end
	end

	if immediate then
		Transport.flush()
	end
end

function Transport.toExceptMany(
	lane: Lane,
	except: Player,
	id: number,
	payloads: { any },
	immediate: boolean?
): ()
	except = assertPlayer(except)

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= except then
			FrameStore.pushManyFor(targetQueues[lane], player, id, payloads)
			serverDirty = true
			targetFrameDirty[lane] = true
		end
	end

	if immediate then
		Transport.flush()
	end
end

function Transport.toExceptPackedOne(
	lane: Lane,
	except: Player,
	id: number,
	unit: any,
	payload: any,
	immediate: boolean?
): ()
	except = assertPlayer(except)

	if immediate then
		flushServerIfDirty()

		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= except then
				sendPackedOneToPlayer(lane, player, id, unit, payload)
			end
		end

		return
	end

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= except then
			PackedStore.push(
				getPacked(getPlayerPacked(targetPackedQueues[lane], player), id),
				unit,
				payload
			)
			serverDirty = true
			targetPackedDirty[lane] = true
		end
	end

	if immediate then
		Transport.flush()
	end
end

function Transport.toExceptPackedMany(
	lane: Lane,
	except: Player,
	id: number,
	unit: any,
	payloads: { any },
	immediate: boolean?
): ()
	except = assertPlayer(except)

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= except then
			PackedStore.pushMany(
				getPacked(getPlayerPacked(targetPackedQueues[lane], player), id),
				unit,
				payloads
			)
			serverDirty = true
			targetPackedDirty[lane] = true
		end
	end

	if immediate then
		Transport.flush()
	end
end

if IS_SERVER then
	-- Named as Lane rather than written as literals at the call site: these
	-- tables are keyed by the union, and a bare string -- including one read
	-- out of an array of them -- widens to string and stops matching it.
	local reliable: Lane = "reliable"
	local fast: Lane = "fast"

	Players.PlayerRemoving:Connect(function(player: Player)
		targetQueues[reliable][player] = nil
		targetQueues[fast][player] = nil
		targetPackedQueues[reliable][player] = nil
		targetPackedQueues[fast][player] = nil
	end)
end

if IS_RUNNING then
	RunService.Heartbeat:Connect(Transport.flush)
end

return table.freeze(Transport)
