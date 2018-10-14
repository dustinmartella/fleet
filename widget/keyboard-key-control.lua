local pairs = pairs
local awful = require("awful")
local wibox = require("wibox")
local naughty = require("naughty")
local beautiful = require("beautiful")

-- Keyboard Key Control

-- kcontrol.mt: module (class) metatable
-- kcontrol.wmt: widget (instance) metatable
local kcontrol = { mt = {}, wmt = {} }
kcontrol.wmt.__index = kcontrol

local notification_id = 0

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

local function get_markup (font, bg, fg, name, strike)
	local strikethrough = ''

	if strike then
		strikethrough = 'strikethrough="true"'
	end

	return '<span font="'..font..'" background="'..bg..'" color="'..fg..'">'..name..'</span>'
end

local function sleep (a)
	local sec = tonumber(os.clock() + a)

	while (os.clock() < sec) do end
end

local function find_led_status (led, out)
	local led_status = string.match(out, led..":([^\\t{0}]+)"):gsub("^%s*(.-)%s*$", "%1")

	if led_status then
		return led_status
	end

	return 'err'
end

function kcontrol:notify_led_status(name, key, led, led_status, silent)
	if not silent then
		notification_id = naughty.notify({
			text = tostring(led_status),
			title = tostring(led),
			icon = beautiful.icon_dir..'/key_'..key..'_'..led_status..'.png',
			position = self.position,
			fg = self.led_status[led_status],
			preset = naughty.config.presets.low,
			replaces_id = notification_id,
		}).id
	end
end

function kcontrol:update_led_status(name, key, led, led_status, silent)
	if self.keywidgets[key] then
		local strike = false

		if 'off' == led_status then
			strike = true
		end

		self.keywidgets[key]:set_markup(get_markup(self.font, self.bg, self.led_status[led_status], name, strike))
	end
end

function kcontrol:add_key (name, key, led, nospacing)
	local spacing = self.spacing

	self.keywidgets[key] = wibox.widget.textbox()

	self.keywidgets[key]:set_markup(get_markup(self.font, self.bg, self.fg, name))

	self.keywidgets[key]:buttons(awful.util.table.join(
		awful.button({ }, 1, function() self:toggle_key(key) end),
		awful.button({ }, 2, function() self:toggle_key(key) end)
	))

	if nospacing then
		spacing = 0
	end

	self.widget:add(wibox.container.margin(self.keywidgets[key], 0, spacing, 0, 0))
end


------------------------------------------
-- Control interface
------------------------------------------

function kcontrol.new(args)
	local sw = setmetatable({}, kcontrol.wmt)

	sw.keywidgets = {}
	sw.keys = args.keys or {}
	sw.query = args.query or 'xset -q'
	sw.toggle = args.query or 'xdotool key'
	sw.position = args.position or "bottom_right"
	sw.spacing = args.spacing or "5"
	sw.bg = args.bg or "#222222"
	sw.fg = args.fg or "#FFFFFF"
	sw.font = args.font or "Monospace"

	sw.led_status = {}
	sw.led_status['on'] = args.led_on or "#00FF00"
	sw.led_status['off'] = args.led_off or "#777777"
	sw.led_status['err'] = args.led_on or "#FF0000"

	sw.widget = wibox.layout.fixed.horizontal()

	for _, k in pairs(sw.keys) do
		if k.name and k.key then
			sw:add_key(k.name, k.key, k.led, (_ == #sw.keys))
			sw:update_key(k.key, true, true)
		end
	end

	return sw
end

function kcontrol:toggle_key (key)
	awful.spawn.easy_async(self.toggle .. ' ' .. key, function (out, err, reason, code)
		if 'exit' == reason and 0 == code then
			self:update_key(key, true)
		end
	end)
end

function kcontrol:update_key ( key, nodelay, silent )
	if not nodelay then
		sleep(0.5)
	end

	for _, k in pairs(self.keys) do
		if k.key == key and k.led then
			awful.spawn.easy_async(self.query, function (out, err, reason, code)
				if 'exit' == reason and 0 == code then
					local led_status = find_led_status(k.led, out)

					self:notify_led_status(k.name, k.key, k.led, led_status, silent)
					self:update_led_status(k.name, k.key, k.led, led_status, silent)
				end
			end)
		end
	end
end

function kcontrol.mt:__call(...)
    return kcontrol.new(...)
end

return setmetatable(kcontrol, kcontrol.mt)

