--!strict

local Codec = require(script.Parent.Parent.Wire.Codec)
local InstanceRegistry = require(script.Parent.Parent.Runtime.InstanceRegistry)
local JoinSync = require(script.Parent.Parent.Runtime.JoinSync)
local Registry = require(script.Parent.Parent.Runtime.Registry)
local Types: any = require(script.Parent.Parent.Schema.Types)

local getField = rawget

return function()
	describe("delta codec", function()
		it("encodes only changed fields", function()
			local guard = Types.delta({
				health = "u16",
				shield = "u16",
			})
			local unit = Codec.compile(guard)
			local payload = {
				id = 42,
				changes = {
					health = 80,
				},
			}

			local encoded = Codec.encodeOne(unit :: any, payload)
			local decoded = Codec.decodeOne(unit :: any, encoded, 0)
			local decodedPayload = decoded :: any
			local changes = getField(decodedPayload, "changes") :: {[string]: any}

			expect(getField(decodedPayload, "id")).to.equal(42)
			expect(getField(changes, "health")).to.equal(80)
			expect(getField(changes, "shield")).to.equal(nil)
		end)
	end)

	describe("instance reference codec", function()
		it("encodes registered Instances as registry ids", function()
			local folder = Instance.new("Folder")
			local disconnect = InstanceRegistry.register("Character", folder, 101)
			local unit = Codec.compile(Types.ref("Character"))
			local encoded = Codec.encodeOne(unit :: any, folder)
			local decoded = Codec.decodeOne(unit :: any, encoded, 0)

			disconnect()
			folder:Destroy()

			expect(decoded).to.equal(folder)
		end)
	end)

	describe("JoinSync", function()
		it("receives ordered stage markers", function()
			local pipeline: any = JoinSync.define({ "MatchState", "Entities" }, {
				name = "Tests.JoinSync",
			})
			local received: {string} = {}
			local done = false
			local disconnectStage = pipeline.onStage(function(stage: string)
				received[#received + 1] = stage
			end)
			local disconnectDone = pipeline.onDone(function()
				done = true
			end)

			Registry.receiveBatch("reliable", nil, 1, -1, {
				{
					name = "Tests.JoinSync",
					stage = "MatchState",
				},
			}, false)
			Registry.receiveBatch("reliable", nil, 1, -1, {
				{
					name = "Tests.JoinSync",
					stage = "Entities",
				},
			}, false)
			Registry.receiveBatch("reliable", nil, 1, -1, {
				{
					name = "Tests.JoinSync",
					done = true,
				},
			}, false)

			disconnectStage()
			disconnectDone()
			pipeline.reset()

			expect(received[1]).to.equal("MatchState")
			expect(received[2]).to.equal("Entities")
			expect(done).to.equal(true)
		end)
	end)
end
