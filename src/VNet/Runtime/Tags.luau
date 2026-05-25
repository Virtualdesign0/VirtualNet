--!strict

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local InstanceRegistry = require(script.Parent.InstanceRegistry)
local Registry = require(script.Parent.Registry)
local Signal = require(script.Parent.Parent.Signals.Signal)

local Tags = {}

local IS_SERVER = RunService:IsServer()

local function assertTag(tag: any): string
	if typeof(tag) ~= "string" or tag == "" then
		error("[VNet]: tag name must be a non-empty string.", 3)
	end

	return tag
end

local function defaultIdOf(kind: string, attributeName: string, instance: Instance): number?
	local registered = InstanceRegistry.id(kind, instance)

	if registered then
		return registered
	end

	local attribute = instance:GetAttribute(attributeName)

	if typeof(attribute) == "number" then
		return attribute
	end

	return nil
end

function Tags.replicate(tag: string, options: {[any]: any}?)
	tag = assertTag(tag)
	options = options or {}

	local entityIdSpec = options.entityId or options.entityIdSpec or options.idSpec or "u32"
	local referenceKind = options.kind or "Entity"
	local attributeName = options.attribute or "VNetId"
	local idOf = options.idOf

	if idOf ~= nil and typeof(idOf) ~= "function" then
		error("[VNet]: Tags.replicate idOf must be a function.", 3)
	end

	local packet = Registry.define(options.name or ("VNet.Tags." .. tag), {
		id = options.id,
		payload = {
			entityId = entityIdSpec,
			tagged = "bool",
		},
		lane = options.lane,
		fast = options.fast,
		reliable = options.reliable,
		immediate = options.immediate,
		validate = options.validate,
	})
	local changed = Signal.new(options.defer == true)
	local state: {[any]: boolean} = {}
	local connections: {RBXScriptConnection} = {}
	local disconnectPacket: (() -> ())? = nil
	local api = {}

	local function resolveId(instance: Instance): number?
		if idOf then
			local value = idOf(instance)

			if typeof(value) == "number" then
				return value
			end

			return nil
		end

		return defaultIdOf(referenceKind, attributeName, instance)
	end

	local function publish(instance: Instance, tagged: boolean, player: Player?): ()
		local entityId = resolveId(instance)

		if entityId == nil then
			return
		end

		local payload = {
			entityId = entityId,
			tagged = tagged,
		}

		if player then
			packet.send(player, payload)
		else
			packet.all(payload)
		end
	end

	if IS_SERVER then
		connections[#connections + 1] = CollectionService:GetInstanceAddedSignal(tag):Connect(function(instance: Instance)
			publish(instance, true)
		end)
		connections[#connections + 1] = CollectionService:GetInstanceRemovedSignal(tag):Connect(function(instance: Instance)
			publish(instance, false)
		end)
	else
		disconnectPacket = packet.on(function(payload: {[string]: any})
			local entityId = payload.entityId
			local tagged = payload.tagged == true

			state[entityId] = if tagged then true else nil
			changed:fire(entityId, tagged)
		end)
	end

	function api.Sync(_self: any, player: Player?): ()
		for _, instance in ipairs(CollectionService:GetTagged(tag)) do
			publish(instance, true, player)
		end
	end

	function api.Has(_self: any, entityId: any): boolean
		return state[entityId] == true
	end

	function api.OnChanged(_self: any, listener: (any, boolean) -> ()): () -> ()
		local connection = changed:connect(listener)

		return function()
			connection:disconnect()
		end
	end

	function api.Destroy(_self: any): ()
		for _, connection in ipairs(connections) do
			connection:Disconnect()
		end

		table.clear(connections)

		if disconnectPacket then
			disconnectPacket()
			disconnectPacket = nil
		end

		changed:clear()
	end

	api.packet = packet
	api.Packet = packet

	return api
end

return table.freeze(Tags)
