--!strict

local Network = require(script.Parent.Parent.Runtime.Network)

return function()
	describe("bindable transport", function()
		it("sends local payloads", function()
			local LocalNet: any = Network.bindable({
				MenuOpened = {
					menuId = "string",
				},
			})
			local received = ""
			local disconnect = LocalNet.MenuOpened.on(function(data)
				received = data.menuId
			end)

			LocalNet.MenuOpened.send({
				menuId = "Inventory",
			})

			disconnect()
			LocalNet.MenuOpened.destroy()

			expect(received).to.equal("Inventory")
		end)

		it("supports local prediction and rejection callbacks", function()
			local LocalNet: any = Network.bindable({
				Attack = {
					weaponId = "string",
				},
			})
			local predicted = ""
			local rejected = ""
			local disconnectPredict = LocalNet.Attack.predict(function(data)
				predicted = data.weaponId
			end)
			local disconnectReject = LocalNet.Attack.reject(function(reason)
				rejected = reason
			end)

			LocalNet.Attack.send({
				weaponId = "Katana",
			})
			LocalNet.Attack.reject("out_of_range")

			disconnectPredict()
			disconnectReject()
			LocalNet.Attack.destroy()

			expect(predicted).to.equal("Katana")
			expect(rejected).to.equal("out_of_range")
		end)
	end)
end
