local setmetatable = setmetatable
local awful = require("awful")

-- client.mt: module (class) metatable
-- client.wmt: widget (instance) metatable
local client = { mt = {}, wmt = {} }
client.wmt.__index = tag

function client.focusbyidx (inc)
	awful.client.focus.byidx(inc)
	if client.focus then
		client.focus:raise()
	end
end

function client.focusnext ()
	client.focusbyidx(1)
end

function client.focusprev ()
	client.focusbyidx(-1)
end

return setmetatable(client, client.mt)
