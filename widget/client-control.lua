---------------------------------------------------------------------------
--- Client Control for fleet.
---------------------------------------------------------------------------

local capi = {
	screen = screen,
	client = client
}
local pairs = pairs
local setmetatable = setmetatable
local table = table
local awful = require("awful")
local util = require("awful.util")
local tag = require("awful.tag")
local beautiful = require("beautiful")

local clientcontrol = {
	widget = {},
	filter = {}
}

--- Show tooltips when hover on client control buttons (defaults to 'true')
clientcontrol.enable_tooltip = true

local instances

local function get_screen(s)
    return s and screen[s]
end

local function get_lists (args)
	local wlist = {}
	local flist = {}
	local rlist = {}

	for _, d in pairs(args) do
		local id = d.id or _

		if d.widget then
			wlist[id] = d.widget
		end

		if d.update and 'function' == type(d.update) then
			flist[id] = d.update
		end

		if d.reset and 'function' == type(d.reset) then
			rlist[id] = d.reset
		end
	end

	return wlist, flist, rlist
end

local function widget_update_no_client (w, s, filter, data, uf)
	local c = awful.client.focus.history.get(s, 0)

	if c and s and filter(c, s) and not c.hidden then
		uf(w, c, s, data[c])
	else
		w._do_widget_reset()
	end
end

local function widget_update (w, c, s, filter, data, uf)
	if c and s and c.screen == s and filter(c, s) and not c.hidden then
		uf(w, c, s, data[c])
	elseif s then
		widget_update_no_client(w, s, filter, data, uf)
	end
end

local function widget_reset (w, s, rf)
	rf(w, s)
end

local function new(screen, args, filter)
	screen = get_screen(screen)
	local filter = filter or clientcontrol.filter.currenttags
	local args = args or {}
	local sw = { widget = {} }

	local wlist, flist, rlist = get_lists(args)

	local data = setmetatable({}, { __mode = 'k' })

	for id, w in pairs(wlist) do
		function w._do_widget_update (c)
			if screen.valid then
				local uf = flist[id] or clientcontrol.update_function
				widget_update(w, c, screen, filter, data, uf)
			end
		end

		function w._do_widget_reset ()
			if screen.valid then
				local rf = rlist[id] or clientcontrol.reset_function
				widget_reset(w, s, rf)
			end
		end

		function w._unmanage (c)
			data[c] = nil
		end
	end

	if instances == nil then
		instances = setmetatable({}, { __mode = "k" })

		local function uw (s, c)
			local i = instances[get_screen(s)]

			if i then
				for _, w in pairs(i) do
					w._do_widget_update(c)
				end
			end
		end

		local function u (c)
			for s in pairs(instances) do
				if s.valid then
					uw(s, c)
				end
			end
		end

		local function um (c)
			for _, i in pairs(instances) do
				for _, w in pairs(i) do
					w._unmanage(c)
				end
			end
		end

		tag.attached_connect_signal(nil, "property::selected", function () u() end)
		tag.attached_connect_signal(nil, "property::activated", function () u() end)
		capi.client.connect_signal("property::urgent", u)
		capi.client.connect_signal("property::sticky", u)
		capi.client.connect_signal("property::ontop", u)
		capi.client.connect_signal("property::above", u)
		capi.client.connect_signal("property::below", u)
		capi.client.connect_signal("property::floating", u)
		capi.client.connect_signal("property::size", u)
		capi.client.connect_signal("property::minimized", u)
		capi.client.connect_signal("property::name", u)
		capi.client.connect_signal("property::icon_name", u)
		capi.client.connect_signal("property::icon", u)
		capi.client.connect_signal("property::skip_taskbar", u)
		capi.client.connect_signal("property::hidden", u)
		capi.client.connect_signal("tagged", u)
		capi.client.connect_signal("untagged", u)
		capi.client.connect_signal("list", u)
		capi.client.connect_signal("focus", u)
		--capi.client.connect_signal("unfocus", u)
		capi.client.connect_signal("property::screen", function (c, old_screen)
			uw(c.screen, c)
			uw(old_screen, c)
		end)
		capi.client.connect_signal("unmanage", function (c)
			u()
			um(c)
		end)
		capi.screen.connect_signal("removed", function (s)
			instances[get_screen(s)] = nil
		end)
	end

	local list = instances[screen]

	if not list then
		list = setmetatable({}, { __mode = "v" })
		instances[screen] = list
	end

	for id, w in pairs(wlist) do
		w._do_widget_reset()
		table.insert(list, w)
		sw.widget[id] = w
	end

	return sw
end

function clientcontrol.update_function (widget, client, screen, data)
end

function clientcontrol.reset_function (widget, screen)
end

function clientcontrol.fg_color (c)
	local color = beautiful.tasklist_fg_normal or beautiful.fg_normal or '#777777'

	if c.screen == awful.screen.focused({client = true, mouse = false}) then
		color = beautiful.tasklist_fg_focus or beautiful.fg_focus or '#FFFFFF'
	end

	return color
end

function clientcontrol.button_img (button, c)
	local prefix = 'normal'
	local state = 'inactive'

	if c.screen == awful.screen.focused({client = true, mouse = false}) then
		prefix = 'focus'
	end

	if c[button] then
		state = 'active'
	end

	local img = beautiful['titlebar_' .. button .. '_button_' .. prefix .. '_' .. state]
		or beautiful['titlebar_' .. button .. '_button_' .. prefix]
		or beautiful.none_normal or nil

	return img
end

function clientcontrol.bind_focus (c, w, buttons)
	if c.screen == awful.screen.focused({client = true, mouse = false}) then
		w:buttons(buttons)
	else
		w:buttons(util.table.join())
	end
end

function clientcontrol.unbind_all (w)
	w:buttons(util.table.join())
end

function clientcontrol.filter.currenttags (c, s)
	local s = s or awful.screen.focused()
	return awful.widget.tasklist.filter.currenttags(c, s)
end

function clientcontrol.filter.currenttagsnotfocused (c, s)
	local client = awful.client.focus.history.get(s, 0)

	if c == client then return false end

	return awful.widget.tasklist.filter.currenttags(c, s)
end

return setmetatable(clientcontrol, { __call = function(_, ...) return new(...) end})

