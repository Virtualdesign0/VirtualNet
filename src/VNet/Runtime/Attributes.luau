--!strict

local RunService = game:GetService("RunService")

local InstanceRegistry = require(script.Parent.InstanceRegistry)
local Registry = require(script.Parent.Registry)
local Signal = require(script.Parent.Parent.Signals.Signal)
local Types = require(script.Parent.Parent.Schema.Types)

local Attributes = {}

local IS_SERVER = RunService:IsServer()

local function assertInstance(instance: any): Instance
	if typeof(instance) ~= "Instance" then
		error("[VNet]: Attributes.track expects an Instance.", 3)
	end

	return instance
end

local function assertSchema(schema: any): {[string]: any}
	if typeof(schema) ~= "table" then
		error("[VNet]: Attributes.track expects a schema table.", 3)
	end

	return schema
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

function Attributes.track(instance: Instance, schema: {[string]: any}, options: {[any]: any}?)
	instance = assertInstance(instance)
	schema = assertSchema(schema)
	options = options or {}

	local entityIdSpec = options.entityId or options.entityIdSpec or options.idSpec or "u32"
	local referenceKind = options.kind or "Entity"
	local attributeName = options.idAttribute or "VNetId"
	local idOf = options.idOf

	if idOf ~= nil and typeof(idOf) ~= "function" then
		error("[VNet]: Attributes.track idOf must be a function.", 3)
	end

	local packet = Registry.define(options.name or "VNet.Attributes", {
		id = options.id,
		payload = Types.delta(schema, entityIdSpec),
		delta = true,
		lane = options.lane,
		fast = options.fast,
		reliable = options.reliable,
		immediate = options.immediate,
		validate = options.validate,
	})
	local changed = Signal.new(options.defer == true)
	local state: {[any]: {[string]: any}} = {}
	local connections: {RBXScriptConnection} = {}
	local disconnectPacket: (() -> ())? = nil
	local api = {}

	local function resolveId(target: Instance): number?
		if idOf then
			local value = idOf(target)

			if typeof(value) == "number" then
				return value
			end

			return nil
		end

		return defaultIdOf(referenceKind, attributeName, target)
	end

	local function publish(changes: {[string]: any}, player: Player?): ()
		local entityId = resolveId(instance)

		if entityId == nil then
			return
		end

		if player then
			packet.sendDelta(player, entityId, changes)
		else
			packet.allDelta(entityId, changes)
		end
	end

	if IS_SERVER then
		for field in schema do
			if typeof(field) == "string" then
				local attributeField = field

				connections[#connections + 1] = instance:GetAttributeChangedSignal(attributeField):Connect(function()
					publish({
						[attributeField] = instance:GetAttribute(attributeField),
					})
				end)
			end
		end
	else
		disconnectPacket = packet.onDelta(function(entityId: any, changes: {[string]: any})
			local current = state[entityId]

			if not current then
				current = {}
				state[entityId] = current
			end

			local target = InstanceRegistry.resolve(referenceKind, entityId)

			for field, value in changes do
				current[field] = value

				if options.apply ~= false and target then
					target:SetAttribute(field, value)
				end
			end

			changed:fire(entityId, changes, target)
		end)
	end

	function api.Sync(_self: any, player: Player?): ()
		local changes = {}
		local count = 0

		for field in schema do
			if typeof(field) == "string" then
				local value = instance:GetAttribute(field)

				if value ~= nil then
					changes[field] = value
					count += 1
				end
			end
		end

		if count > 0 then
			publish(changes, player)
		end
	end

	function api.Get(_self: any, entityId: any): {[string]: any}?
		return state[entityId]
	end

	function api.OnChanged(_self: any, listener: (any, {[string]: any}, Instance?) -> ()): () -> ()
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

return table.freeze(Attributes)
