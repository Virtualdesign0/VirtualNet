--!strict

export type Connection = {
	connected: boolean,
	disconnect: (Connection) -> (),
}

local Signal = {}
Signal.__index = Signal

local END_NODE: any = table.freeze({})

function Signal.new(deferCallbacks: boolean?)
	return setmetatable({
		_defer = deferCallbacks == true,
		_head = END_NODE,
		_tail = END_NODE,
		_single = false,
	}, Signal)
end

function Signal:_refreshSingle(): ()
	local connection = self._head

	if not self._defer and connection ~= END_NODE and connection == self._tail and connection.connected then
		self._single = connection._callback
	else
		self._single = false
	end
end

function Signal:_sweep(): ()
	local node = self._head
	local previous = END_NODE

	while node ~= END_NODE do
		local nextNode = node._next

		if node.connected then
			previous = node
		elseif previous ~= END_NODE then
			previous._next = nextNode
		else
			self._head = nextNode
		end

		if self._tail == node and not node.connected then
			self._tail = previous
		end

		node = nextNode
	end

	self:_refreshSingle()
end

function Signal:connect(callback: (...any) -> ()): Connection
	if typeof(callback) ~= "function" then
		error("[VNet]: Signal callback must be a function.", 2)
	end

	local connection: any = {
		connected = true,
		_callback = callback,
		_owner = self,
		_next = END_NODE,
	}

	function connection:disconnect()
		if not self.connected then
			return
		end

		self.connected = false
		self._owner:_sweep()
	end

	if self._tail ~= END_NODE then
		self._tail._next = connection
	else
		self._head = connection
	end

	self._tail = connection
	self:_refreshSingle()

	return connection :: any
end

function Signal:once(callback: (...any) -> ()): Connection
	local connection: any

	connection = self:connect(function(...: any)
		connection:disconnect()
		callback(...)
	end)

	return connection
end

function Signal:wait(): ...any
	local bindable = Instance.new("BindableEvent")
	local connection: any

	connection = self:once(function(...: any)
		bindable:Fire(...)
	end)

	local packed = table.pack(bindable.Event:Wait())
	connection:disconnect()
	bindable:Destroy()

	return table.unpack(packed, 1, packed.n)
end

function Signal:fire(...: any): ()
	local connection = self._head
	local tail = self._tail

	if self._defer then
		while connection ~= END_NODE do
			local nextConnection = connection._next

			if connection.connected then
				task.spawn(connection._callback, ...)
			end

			if connection == tail then
				return
			end

			connection = nextConnection
		end

		return
	end

	while connection ~= END_NODE do
		local nextConnection = connection._next

		if connection.connected then
			connection._callback(...)
		end

		if connection == tail then
			return
		end

		connection = nextConnection
	end
end

function Signal:hasListeners(): boolean
	return self._head ~= END_NODE
end

function Signal:getSingleListener(): ((...any) -> ())?
	local callback = self._single

	if callback then
		return callback
	end

	return nil
end

function Signal:clear(): ()
	local connection = self._head

	while connection ~= END_NODE do
		local nextConnection = connection._next
		connection.connected = false
		connection = nextConnection
	end

	self._head = END_NODE
	self._tail = END_NODE
	self._single = false
end

return Signal
