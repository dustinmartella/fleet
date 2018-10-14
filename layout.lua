local pairs = pairs
local awful = require("awful")
local wibox = require("wibox")

-- client.mt: module (class) metatable
-- client.wmt: widget (instance) metatable
local layout = { mt = {}, wmt = {} }
layout.wmt.__index = layout

function layout.toggle_wibox (wiboxes)
	for _, w in pairs(wiboxes) do
		if w then
			w.visible = not w.visible
		end
	end

	awful.screen.focused():emit_signal("arrange")
end

return setmetatable(layout, layout.mt)

