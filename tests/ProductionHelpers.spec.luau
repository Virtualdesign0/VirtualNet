--!strict

local Layer = require(script.Parent.Parent.Runtime.Layer)
local Registry = require(script.Parent.Parent.Runtime.Registry)
local Relevance = require(script.Parent.Parent.Runtime.Relevance)
local Replicator = require(script.Parent.Parent.Runtime.Replicator)
local Shard = require(script.Parent.Parent.Runtime.Shard)
local Types: any = require(script.Parent.Parent.Schema.Types)

local getField = rawget

return function()
	describe("transaction packets", function()
		it("drops duplicate idempotency keys from the same player", function()
			local packet: any = Registry.define("Tests.Transaction", {
				id = 64100,
				payload = {
					idempotencyKey = "u32",
					payload = "u8",
				},
				transaction = true,
				validate = false,
			})
			local calls = 0
			local fakePlayer: any = {
				UserId = 123,
			}
			local disconnect = packet.on(function(_player, _data)
				calls += 1
			end)

			Registry.receive("reliable", fakePlayer, packet.id, {
				idempotencyKey = 77,
				payload = 1,
			})
			Registry.receive("reliable", fakePlayer, packet.id, {
				idempotencyKey = 77,
				payload = 2,
			})
			Registry.receive("reliable", fakePlayer, packet.id, {
				idempotencyKey = 78,
				payload = 3,
			})

			disconnect()

			expect(calls).to.equal(2)
		end)
	end)

	describe("packet policy", function()
		it("drops packets rejected by a custom validator", function()
			local packet: any = Registry.define("Tests.PacketPolicy", {
				id = 64101,
				payload = {
					allowed = "bool",
				},
				validate = function(_player, data)
					return data.allowed == true
				end,
				onViolation = "drop",
			})
			local calls = 0
			local fakePlayer: any = {
				UserId = 456,
			}
			local disconnect = packet.on(function(_player, _data)
				calls += 1
			end)

			Registry.receive("reliable", fakePlayer, packet.id, {
				allowed = false,
			})
			Registry.receive("reliable", fakePlayer, packet.id, {
				allowed = true,
			})

			disconnect()

			expect(calls).to.equal(1)
		end)
	end)

	describe("runtime schema helpers", function()
		it("creates player/entity id and flag guards", function()
			expect(getField(Types.resolve("playerId"), "kind")).to.equal("playerId")
			expect(getField(Types.resolve("entityId"), "kind")).to.equal("entityId")
			expect(getField(Types.player(), "kind")).to.equal("player")
			expect(getField(Types.character(), "kind")).to.equal("character")
			expect(getField(Types.entity(), "kind")).to.equal("ref")
			expect(getField(Types.flags({ "Running", "Blocking" }), "kind")).to.equal("flags")
		end)
	end)

	describe("layer and relevance helpers", function()
		it("checks phase/layer and custom relevance rules", function()
			local player: any = {}
			local entity = "Entity_1"
			local disconnect = Relevance.rule("Tests.Party", function(candidate, target)
				return candidate == player and target == entity
			end)

			Layer.set(player, "Dungeon_12")
			Layer.set(entity, "Dungeon_12")

			expect(Layer.same(player, entity)).to.equal(true)
			expect(Relevance.check(player, entity)).to.equal(true)

			disconnect()
			Layer.clear(player)
			Layer.clear(entity)
		end)
	end)

	describe("replicator", function()
		it("tracks dirty state through Set", function()
			local replicator: any = Replicator.new({
				name = "Tests.Replicator",
				entityId = "u16",
				state = {
					health = "u8",
				},
			})
			local replica = replicator:Track(10, {
				health = 100,
			})

			replica:Set("health", 80)

			expect(replicator:Get(10).health).to.equal(80)
		end)
	end)

	describe("shard bridge", function()
		it("creates a bridge without auto-starting", function()
			local bridge: any = Shard.bridge("Tests.Shard", {
				Ping = {
					value = "u8",
				},
			}, {
				autoStart = false,
			})
			local disconnect = bridge:On("Ping", function(_payload)
			end)

			disconnect()

			expect(bridge ~= nil).to.equal(true)
		end)
	end)
end
