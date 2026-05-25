--!strict

local types: any = require(script.Parent.Parent.Schema.Types)
local getField = rawget
local resolve = getField(types, "resolve") :: (any) -> any
local f32 = getField(types, "f32")
local f64 = getField(types, "f64")
local numberType = getField(types, "number")

local function scalar(name: string): any
	return getField(types, name)
end

return function()
	describe("numeric scalar aliases", function()
		it("maps float aliases to f32", function()
			expect(resolve("float")).to.equal(f32)
			expect(scalar("float")).to.equal(f32)
			expect(getField(scalar("float"), "kind")).to.equal("f32")
		end)

		it("maps double aliases to f64", function()
			expect(resolve("double")).to.equal(f64)
			expect(scalar("double")).to.equal(f64)
			expect(numberType).to.equal(f64)
			expect(getField(scalar("double"), "kind")).to.equal("f64")
		end)

		it("rejects the ambiguous f alias", function()
			local ok, message = pcall(function()
				resolve("f")
			end)

			expect(ok).to.equal(false)
			expect(string.find(tostring(message), 'Unknown schema type "f"', 1, true) ~= nil).to.equal(true)
		end)
	end)

	describe("compact scalar aliases", function()
		it("resolves Packet-style casing", function()
			expect(getField(resolve("S8"), "kind")).to.equal("i8")
			expect(getField(resolve("S16"), "kind")).to.equal("i16")
			expect(getField(resolve("S24"), "kind")).to.equal("i24")
			expect(getField(resolve("S32"), "kind")).to.equal("i32")
			expect(getField(resolve("U4"), "kind")).to.equal("u4")
			expect(getField(resolve("U24"), "kind")).to.equal("u24")
			expect(getField(resolve("F16"), "kind")).to.equal("f16")
			expect(getField(resolve("F24"), "kind")).to.equal("f24")
			expect(getField(resolve("Boolean1"), "kind")).to.equal("boolean1")
			expect(getField(resolve("Boolean8"), "kind")).to.equal("bool")
		end)

		it("resolves compact Roblox value types", function()
			expect(getField(resolve("Vector2S16"), "kind")).to.equal("vector2s16")
			expect(getField(resolve("Vector2F24"), "kind")).to.equal("vector2f24")
			expect(getField(resolve("Vector2F32"), "kind")).to.equal("vec2")
			expect(getField(resolve("Vector3S16"), "kind")).to.equal("vector3s16")
			expect(getField(resolve("CFrameF24U8"), "kind")).to.equal("cframef24u8")
			expect(getField(resolve("NumberRange"), "kind")).to.equal("numberrange")
			expect(getField(resolve("NumberSequence"), "kind")).to.equal("numbersequence")
			expect(getField(resolve("Color3"), "kind")).to.equal("color3")
			expect(getField(resolve("ColorSequence"), "kind")).to.equal("colorsequence")
			expect(getField(resolve("Region3"), "kind")).to.equal("region3")
			expect(getField(resolve("Rect"), "kind")).to.equal("rect")
			expect(getField(resolve("BrickColor"), "kind")).to.equal("brickcolor")
			expect(getField(resolve("UDim"), "kind")).to.equal("udim")
			expect(getField(resolve("UDim2"), "kind")).to.equal("udim2")
		end)
	end)

	describe("state helper schemas", function()
		it("creates ref guards", function()
			local guard = types.ref("Character")

			expect(getField(guard, "kind")).to.equal("ref")
			expect(getField(guard, "refKind")).to.equal("Character")
		end)

		it("creates delta guards", function()
			local guard = types.delta({
				health = "u16",
			})

			expect(getField(guard, "kind")).to.equal("delta")
		end)
	end)
end
