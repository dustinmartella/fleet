local awful = require("awful")

-- tag.mt: module (class) metatable
-- tag.wmt: widget (instance) metatable
local tag = { mt = {}, wmt = {} }
tag.wmt.__index = tag

function tag.incview_with_clients (inc)
	local scr = awful.screen.focused()

	for i = 1, #scr.tags do
		awful.tag.viewidx(inc)
		if #awful.client.visible(scr) > 0 then
			 return
		end
	end
end

function tag.viewnext_with_clients ()
	tag.incview_with_clients(1)
end

function tag.viewprev_with_clients ()
	tag.incview_with_clients(-1)
end

return setmetatable(tag, tag.mt)
