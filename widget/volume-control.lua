local awful = require("awful")
local wibox = require("wibox")

-- vcontrol.mt: module (class) metatable
-- vcontrol.wmt: widget (instance) metatable
local vcontrol = { mt = {}, wmt = {} }
vcontrol.wmt.__index = vcontrol


local function readcommand(command)
	local file = io.popen(command)
	local text = file:read('*all')
	file:close()
	return text
end

local function quote(str)
	return "'" .. string.gsub(str, "'", "'\\''") .. "'"
end

local function arg(first, ...)
	if #{...} == 0 then
		return quote(first)
	else
		return quote(first), arg(...)
	end
end

local function argv(...)
	return table.concat({arg(...)}, " ")
end



function vcontrol.new(args)
	local sw = setmetatable({}, vcontrol.wmt)

	sw.cmd = "pamixer"
	sw.step = args.step or '5'
	sw.lclick = args.lclick or "toggle"
	sw.mclick = args.mclick or "pavucontrol"
	sw.rclick = args.rclick or "pavucontrol"

	sw.widget = wibox.widget({
		max_value = 101,
		value = 0,
		forced_height = 18,
		forced_width = 80,
		paddings = 0,
		border_width = 0,
		margins = {
			top = 8,
			bottom = 8,
		},
		widget = wibox.widget.progressbar
	})

	sw.widget:buttons(awful.util.table.join(
	awful.button({}, 1, function() sw:action(sw.lclick) end),
	awful.button({}, 2, function() sw:action(sw.mclick) end),
	awful.button({}, 3, function() sw:action(sw.rclick) end),
	awful.button({}, 4, function() sw:up() end),
	awful.button({}, 5, function() sw:down() end)
	))

	sw.timer = timer({ timeout = args.timeout or 1 })
	sw.timer:connect_signal("timeout", function() sw:get() end)
	sw.timer:start()
	sw:get()

	return sw
end

function vcontrol:action(action)
	if action == nil then
		return
	end
	if type(action) == "function" then
		action(self)
	elseif type(action) == "string" then
		if self[action] ~= nil then
			self[action](self)
		else
			awful.spawn(action)
		end
	end
end

function vcontrol:update(volume, mute)
	volume = string.match(volume, "%d+")
	mute = string.find(mute, 'true');

	if volume == nil then
		return
	end

	if mute then
		self.widget.color = '#AAAAAAFF'
	else
		self.widget.color = '#8AE181FF'
	end

	self.widget:set_value(tonumber(volume))
end

function vcontrol:mixercommand(...)
	local args = awful.util.table.join(
	{self.cmd},
	{...})
	local command = argv(unpack(args))
	return readcommand(command)
end

function vcontrol:get()
	self:update(self:mixercommand("--get-volume"), self:mixercommand("--get-mute"))
end

function vcontrol:up()
	self:mixercommand("--increase", self.step)
	self:update(self:mixercommand("--get-volume"), self:mixercommand("--get-mute"))
end

function vcontrol:down()
	self:mixercommand("--decrease", self.step)
	self:update(self:mixercommand("--get-volume"), self:mixercommand("--get-mute"))
end

function vcontrol:toggle()
	self:mixercommand("--toggle-mute")
	self:update(self:mixercommand("--get-volume"), self:mixercommand("--get-mute"))
end

function vcontrol:mute()
	self:mixercommand("--mute")
	self:update(self:mixercommand("--get-volume"), self:mixercommand("--get-mute"))
end

function vcontrol.mt:__call(...)
	return vcontrol.new(...)
end

return setmetatable(vcontrol, vcontrol.mt)

