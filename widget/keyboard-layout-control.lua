local awful = require("awful")
local wibox = require("wibox")

-- indicator.mt: module (class) metatable
-- indicator.wmt: widget (instance) metatable
local indicator = { mt = {}, wmt = {} }
indicator.wmt.__index = indicator

local notification_id = 0

function indicator.new ( layouts )
	local sw = setmetatable({}, indicator.wmt)

	sw.keywidgets = {}

	sw.cmd = "setxkbmap"
	sw.layouts = layouts or {}

	sw.index = 1
	sw.current = nil

	sw.widget = wibox.layout.fixed.horizontal()

	sw.layoutwidget = wibox.widget.textbox()
	sw.layoutwidget.set_align("right")

	sw.layoutwidget:buttons(awful.util.table.join(
		awful.button({ }, 1, function() sw:next() end),
		awful.button({ }, 3, function() sw:prev() end),
		awful.button({ }, 4, function() sw:prev() end),
		awful.button({ }, 5, function() sw:next() end)
	))

	sw.widget:add(sw.layoutwidget)
	sw:set(sw.index)

	return sw
end

function indicator:set(i)
	-- set current index
	self.index = ((i-1)+#(self.layouts)) % #(self.layouts) + 1
	self.current = self.layouts[self.index]
	self:update()
	-- execute command
	local cmd
	if self.current.command then
		cmd = self.current.command
	else
		cmd = self.cmd .. " " .. self.current.layout
		if self.current.variant then
			cmd = cmd .. " " .. self.current.variant
		end
	end
	os.execute( cmd )
	os.execute("xmodmap ~/.Xmodmap")
end

function indicator:update()
	-- update layoutwidget text
	local text = ""..self.current.name..""

	if self.current.color and self.current.color ~= nil then
		local w_markup = '<span color="'..self.current.color..'">'..text..'</span>'
		self.layoutwidget:set_markup(w_markup)
	else
		self.layoutwidget:set_text(text)
	end
end

function indicator:get(i)
	-- parse current layout from setxkbmap
	local status_cmd = io.popen(self.cmd .. " -query")
	local status = status_cmd:read("*a")
	local layout = string.match(status, "layout:([^\n]*)")
	local variant = string.match(status, "variant:([^\n]*)")
	-- find layout in self.layouts
	local index = findindex(self.layouts,
	function (v)
		return v.layout==layout and v.variant == variant
	end)
	if index == nil then
		self.current = {color="yellow"}
		if variant then
			self.current.name = layout.."/"..variant
		else
			self.current.name = layout
		end
	else
		self.index = tonumber(index)
		self.current = self.layouts[index]
	end
	-- update layoutwidget
	self:update()
end

function indicator:next()
	self:set(self.index + 1)
end

function indicator:prev()
	self:set(self.index - 1)
end

function indicator.mt:__call(...)
	return indicator.new(...)
end

return setmetatable(indicator, indicator.mt)
