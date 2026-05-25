--!strict

local Registry = require(script.Parent.Parent.Runtime.Registry)

return function()
	describe("prediction helpers", function()
		it("dispatches packet rejection control messages", function()
			local packet: any = Registry.define("Tests.PredictionReject", {
				id = 64020,
				payload = {
					weaponId = "string",
				},
				validate = false,
			})
			local rejected = ""
			local disconnect = packet.reject(function(reason)
				rejected = reason
			end)

			Registry.receiveBatch("reliable", nil, 1, 0, {
				{
					id = packet.id,
					reason = "out_of_range",
				},
			}, false)

			disconnect()

			expect(rejected).to.equal("out_of_range")
		end)
	end)
end
