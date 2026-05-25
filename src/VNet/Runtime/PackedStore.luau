--!strict

local PackedStore = {}

export type PackedBatch = {
	count: number,
	size: number,
	capacity: number,
	data: buffer,
}

type Unit = {
	size: number?,
	measure: (value: any) -> number,
	measureMany: ((values: {any}) -> number)?,
	write: (target: buffer, cursor: number, value: any) -> number,
	writeMany: ((target: buffer, cursor: number, values: {any}) -> number)?,
	writePacked: ((batch: PackedBatch, value: any) -> ())?,
}

local INITIAL_CAPACITY = 4096
local createBuffer = (buffer :: any)["create"]
local copyBuffer = (buffer :: any)["copy"]
local EMPTY_BUFFER = createBuffer(0)

function PackedStore.new(): PackedBatch
	return {
		count = 0,
		size = 0,
		capacity = INITIAL_CAPACITY,
		data = createBuffer(INITIAL_CAPACITY),
	} :: PackedBatch
end

function PackedStore.reset(batch: PackedBatch): ()
	batch.count = 0
	batch.size = 0
end

function PackedStore.reserve(batch: PackedBatch, needed: number): ()
	if needed <= batch.capacity then
		return
	end

	local capacity = math.max(batch.capacity, INITIAL_CAPACITY)

	while needed > capacity do
		capacity *= 2
	end

	local data = createBuffer(capacity)
	copyBuffer(data, 0, batch.data, 0, batch.size)

	batch.capacity = capacity
	batch.data = data
end

function PackedStore.push(batch: PackedBatch, unit: Unit, payload: any): ()
	local fixedSize = unit.size
	local size = if fixedSize then fixedSize else unit.measure(payload)
	local cursor = batch.size
	local write = unit.write

	PackedStore.reserve(batch, cursor + size)

	batch.size = write(batch.data, cursor, payload)
	batch.count += 1
end

function PackedStore.pushMany(batch: PackedBatch, unit: Unit, payloads: {any}): ()
	local size = 0
	local fixedSize = unit.size

	if fixedSize then
		size = #payloads * fixedSize
	else
		local measureMany = unit.measureMany

		if measureMany then
			size = measureMany(payloads)
		else
			local measure = unit.measure

			for index = 1, #payloads do
				local payload = payloads[index]

				size += measure(payload)
			end
		end
	end

	local cursor = batch.size

	if cursor == 0 and size > batch.capacity then
		batch.capacity = size
		batch.data = createBuffer(size)
	else
		PackedStore.reserve(batch, cursor + size)
	end

	local writeMany = unit.writeMany

	if writeMany then
		cursor = writeMany(batch.data, cursor, payloads)
	else
		local write = unit.write

		for index = 1, #payloads do
			local payload = payloads[index]

			cursor = write(batch.data, cursor, payload)
		end
	end

	batch.size = cursor
	batch.count += #payloads
end

function PackedStore.read(batch: PackedBatch): buffer
	if batch.size == 0 then
		return EMPTY_BUFFER
	end

	if batch.size == batch.capacity then
		local source = batch.data
		return source
	end

	local data = createBuffer(batch.size)
	copyBuffer(data, 0, batch.data, 0, batch.size)

	batch.capacity = batch.size
	batch.data = data

	return data
end

return table.freeze(PackedStore)
