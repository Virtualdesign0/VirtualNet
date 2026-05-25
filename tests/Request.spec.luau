--!strict

local Network = require(script.Parent.Parent.Runtime.Network)
local Request = require(script.Parent.Parent.Runtime.Request)
local getField = rawget

return function()
	describe("request config form", function()
		it("accepts output-only request configs", function()
			local config = Network.request({
				output = {
					level = "u16",
					coins = "u32",
				},
				requestId = 100,
				responseId = 101,
			})

			local requestInfo, responseInfo = Request.expand("GetProfile", config)

			expect(requestInfo.name).to.equal("GetProfile:request")
			expect(responseInfo.name).to.equal("GetProfile:response")
			expect(requestInfo.config.id).to.equal(100)
			expect(responseInfo.config.id).to.equal(101)
			expect(requestInfo.config.payload.requestId).to.equal("u32")
			expect(requestInfo.config.payload.value).to.equal("none")
		end)

		it("audits output-only request configs with explicit ids", function()
			local auditReport: any = Network.audit({
				GetProfile = Network.request({
					output = {
						level = "u16",
						coins = "u32",
					},
					requestId = 100,
					responseId = 101,
				}),
			}, {
				requireExplicitIds = true,
			})

			local errors = getField(auditReport, "errors") :: {any}
			local packets = getField(auditReport, "packets") :: {{[string]: any}}

			local requestPacket = packets[1]
			local responsePacket = packets[2]

			expect(getField(auditReport, "ok")).to.equal(true)
			expect(#errors).to.equal(0)
			expect(#packets).to.equal(2)
			expect(requestPacket.name).to.equal("GetProfile:request")
			expect(requestPacket.id).to.equal(100)
			expect(responsePacket.name).to.equal("GetProfile:response")
			expect(responsePacket.id).to.equal(101)
		end)

		it("does not leak internal config markers into expanded packets", function()
			local config = Network.request({
				input = {
					userId = "u32",
				},
				output = {
					level = "u16",
				},
				requestId = 110,
				responseId = 111,
			})

			local requestInfo, responseInfo = Request.expand("GetProfile", config)

			expect(requestInfo.config.__vnetPacket == nil).to.equal(true)
			expect(requestInfo.config.__vnetRequest == nil).to.equal(true)
			expect(responseInfo.config.__vnetPacket == nil).to.equal(true)
			expect(responseInfo.config.__vnetRequest == nil).to.equal(true)
		end)
	end)
end
