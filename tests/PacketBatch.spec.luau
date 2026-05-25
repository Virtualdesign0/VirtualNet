--!strict

local Registry = require(script.Parent.Parent.Runtime.Registry)
local types: any = require(script.Parent.Parent.Schema.Types)
local codec: any = require(script.Parent.Parent.Wire.Codec)

local getField = rawget
local resolve = getField(types, "resolve") :: (any) -> any

local function packedPayloads(spec: any, payloads: {any}): buffer
	return codec.encodeMany(codec.compile(resolve(spec)), payloads)
end

return function()
	describe("packet.onBatch", function()
		it("dispatches a packed batch with one callback", function()
			local packet: any = Registry.define("Tests.OnBatchPacked", {
				id = 64001,
				payload = "u32",
				validate = false,
			})
			local calls = 0
			local receivedCount = 0
			local receivedPayloads: {any}? = nil
			local disconnect = packet.onBatch(function(payloads: {any}, count: number)
				calls += 1
				receivedCount = count
				receivedPayloads = payloads
			end)

			Registry.receiveBatch("reliable", nil, 3, packet.id, packedPayloads("u32", { 10, 20, 30 }), true)
			disconnect()

			local payloads = receivedPayloads :: {any}

			expect(calls).to.equal(1)
			expect(receivedCount).to.equal(3)
			expect(getField(payloads, 1)).to.equal(10)
			expect(getField(payloads, 2)).to.equal(20)
			expect(getField(payloads, 3)).to.equal(30)
		end)

		it("preserves count for payload-less batches", function()
			local packet: any = Registry.define("Tests.OnBatchNone", {
				id = 64002,
				payload = "none",
				validate = false,
			})
			local receivedCount = 0
			local receivedPayloads: {any}? = nil
			local disconnect = packet.onBatch(function(payloads: {any}, count: number)
				receivedCount = count
				receivedPayloads = payloads
			end)

			Registry.receiveBatch("reliable", nil, 3, packet.id, packedPayloads("none", { false, false, false }), true)
			disconnect()

			expect(receivedCount).to.equal(3)
			expect(#(receivedPayloads :: {any})).to.equal(0)
		end)

		it("passes an empty payload table for unpacked payload-less batches", function()
			local packet: any = Registry.define("Tests.OnBatchUnpackedNone", {
				id = 64003,
				payload = "none",
				validate = false,
			})
			local receivedCount = 0
			local receivedPayloads: {any}? = nil
			local disconnect = packet.onBatch(function(payloads: {any}, count: number)
				receivedCount = count
				receivedPayloads = payloads
			end)

			Registry.receiveBatch("reliable", nil, 2, packet.id, { false, false }, false)
			disconnect()

			expect(receivedCount).to.equal(2)
			expect(#(receivedPayloads :: {any})).to.equal(0)
		end)
	end)

	describe("packet.onBatchCount", function()
		it("dispatches a packed batch count without payloads", function()
			local packet: any = Registry.define("Tests.OnBatchCountPacked", {
				id = 64004,
				payload = "u32",
				validate = false,
			})
			local calls = 0
			local receivedCount = 0
			local disconnect = packet.onBatchCount(function(count: number)
				calls += 1
				receivedCount = count
			end)

			Registry.receiveBatch("reliable", nil, 3, packet.id, packedPayloads("u32", { 10, 20, 30 }), true)
			disconnect()

			expect(calls).to.equal(1)
			expect(receivedCount).to.equal(3)
		end)

		it("can mirror onBatch for the same packed batch", function()
			local packet: any = Registry.define("Tests.OnBatchCountMirror", {
				id = 64005,
				payload = "u32",
				validate = false,
			})
			local batchCount = 0
			local countOnly = 0
			local disconnectBatch = packet.onBatch(function(_payloads: {any}, count: number)
				batchCount = count
			end)
			local disconnectCount = packet.onBatchCount(function(count: number)
				countOnly = count
			end)

			Registry.receiveBatch("reliable", nil, 2, packet.id, packedPayloads("u32", { 40, 50 }), true)
			disconnectBatch()
			disconnectCount()

			expect(batchCount).to.equal(2)
			expect(countOnly).to.equal(2)
		end)

		it("dispatches a direct packed packet as a single batch count", function()
			local packet: any = Registry.define("Tests.OnDirectPackedCount", {
				id = 64006,
				payload = "u32",
				validate = false,
			})
			local calls = 0
			local receivedCount = 0
			local disconnect = packet.onBatchCount(function(count: number)
				calls += 1
				receivedCount = count
			end)

			Registry.receivePackedOne("reliable", nil, packet.id, packedPayloads("u32", { 90 }))
			disconnect()

			expect(calls).to.equal(1)
			expect(receivedCount).to.equal(1)
		end)
	end)
end
