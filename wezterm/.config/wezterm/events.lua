local wezterm = require("wezterm")
local mux = wezterm.mux
local nf = wezterm.nerdfonts

-- Kanagawa theme colors (muted steel-blue bar to match target)
local theme = {
	bg = "#1F1F28",
	bar_bg = "#2A2A37",
	fg = "#DCD7BA",
	active = "#7E9CD8",    -- blue for active tab
	inactive = "#54546D",  -- muted blue-gray for inactive tabs
	hover = "#363646",     -- subtle hover
	dark = "#1F1F28",
}

-- Tab separators (powerline arrow style)
local TAB_LEFT = nf.pl_right_hard_divider
local TAB_RIGHT = nf.pl_left_hard_divider

-- Status bar separators (powerline style)
local SB_LEFT = nf.pl_left_hard_divider
local SB_RIGHT = nf.pl_right_hard_divider

-- Status bar gradient colors (muted steel-blue tones matching target)
local sb_colors = {
	"#54546D",  -- darkest slate
	"#6A6A8E",  -- mid slate
	"#8B8DA3",  -- lighter slate
	"#A0A2B8",  -- lightest slate
}

wezterm.on("gui-startup", function()
	mux.spawn_window({})
end)

wezterm.on("update-status", function(window, pane)
	local overrides = window:get_config_overrides() or {}
	overrides.colors = overrides.colors or {}
	overrides.colors.split = theme.active
	window:set_config_overrides(overrides)

	-- Left status: mode indicator
	local mode = window:active_key_table()
	local mode_label = ""
	local mode_bg = theme.active
	if mode == "search_mode" then
		mode_label = " " .. nf.md_magnify .. " SEARCH "
		mode_bg = "#E6C384"
	elseif mode == "copy_mode" then
		mode_label = " " .. nf.md_content_copy .. " COPY "
		mode_bg = "#98BB6C"
	end

	if mode_label ~= "" then
		window:set_left_status(wezterm.format({
			{ Background = { Color = mode_bg } },
			{ Foreground = { Color = theme.dark } },
			{ Attribute = { Intensity = "Bold" } },
			{ Text = mode_label },
			{ Background = { Color = theme.bar_bg } },
			{ Foreground = { Color = mode_bg } },
			{ Text = SB_LEFT },
		}))
	else
		window:set_left_status("")
	end

	-- Right status: cwd, git branch, time
	local cwd_uri = pane:get_current_working_dir()
	local cwd = ""
	local branch = ""

	if cwd_uri then
		cwd = cwd_uri.file_path or ""
		local home = os.getenv("HOME") or ""
		if home ~= "" and cwd:sub(1, #home) == home then
			cwd = "~" .. cwd:sub(#home + 1)
		end
		-- Shorten to last 2 path components if long
		local parts = {}
		for part in cwd:gmatch("[^/]+") do
			table.insert(parts, part)
		end
		if #parts > 2 then
			if parts[1] == "~" then
				cwd = "~/" .. parts[#parts - 1] .. "/" .. parts[#parts]
			else
				cwd = parts[#parts - 1] .. "/" .. parts[#parts]
			end
		end

		local success, stdout = wezterm.run_child_process({
			"git", "-C", cwd_uri.file_path or "", "rev-parse", "--abbrev-ref", "HEAD",
		})
		if success and stdout then
			branch = stdout:gsub("%s+$", "")
		end
	end

	local time = wezterm.strftime("%a %b %-d  %H:%M")
	local hostname = wezterm.hostname()
	-- Shorten hostname
	hostname = hostname:gsub("%..*", "")

	local status = {}

	-- Build right status segments (right-to-left visually, but we build left-to-right)
	-- Segment 1: hostname (darkest)
	table.insert(status, { Background = { Color = theme.bar_bg } })
	table.insert(status, { Foreground = { Color = sb_colors[1] } })
	table.insert(status, { Text = SB_RIGHT })
	table.insert(status, { Background = { Color = sb_colors[1] } })
	table.insert(status, { Foreground = { Color = theme.dark } })
	table.insert(status, { Text = " " .. nf.md_laptop .. " " .. hostname .. " " })

	-- Segment 2: cwd (blue, matching active tab)
	if cwd ~= "" then
		table.insert(status, { Foreground = { Color = theme.active } })
		table.insert(status, { Text = SB_RIGHT })
		table.insert(status, { Background = { Color = theme.active } })
		table.insert(status, { Foreground = { Color = theme.dark } })
		table.insert(status, { Text = " " .. nf.md_folder .. " " .. cwd .. " " })
	end

	-- Segment 3: date/time
	table.insert(status, { Foreground = { Color = sb_colors[3] } })
	table.insert(status, { Text = SB_RIGHT })
	table.insert(status, { Background = { Color = sb_colors[3] } })
	table.insert(status, { Foreground = { Color = theme.dark } })
	table.insert(status, { Text = " " .. time .. " " })

	-- Segment 4: battery (lightest)
	local battery = wezterm.battery_info()
	if battery and #battery > 0 then
		local charge = battery[1].state_of_charge * 100
		local bat_icon = nf.md_battery
		if charge >= 90 then bat_icon = nf.md_battery
		elseif charge >= 70 then bat_icon = nf.md_battery_70
		elseif charge >= 50 then bat_icon = nf.md_battery_50
		elseif charge >= 30 then bat_icon = nf.md_battery_30
		elseif charge >= 10 then bat_icon = nf.md_battery_20
		else bat_icon = nf.md_battery_10
		end
		if battery[1].state == "Charging" then
			bat_icon = nf.md_battery_charging
		end
		table.insert(status, { Foreground = { Color = sb_colors[4] } })
		table.insert(status, { Text = SB_RIGHT })
		table.insert(status, { Background = { Color = sb_colors[4] } })
		table.insert(status, { Foreground = { Color = theme.dark } })
		table.insert(status, { Text = " " .. bat_icon .. " " .. string.format("%.0f%%", charge) .. " " })
	end

	window:set_right_status(wezterm.format(status))
end)

wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
	local tab_num = tab.tab_index + 1
	local title = tab.active_pane.title
	if title and #title > 20 then
		title = title:sub(1, 20) .. ".."
	end

	local is_active = tab.is_active
	local tab_bg
	if is_active then
		tab_bg = theme.active
	elseif hover then
		tab_bg = theme.hover
	else
		tab_bg = theme.inactive
	end

	local tab_fg = theme.dark
	if hover and not is_active then
		tab_fg = theme.inactive
	end

	return {
		-- Colored number segment
		{ Background = { Color = tab_bg } },
		{ Foreground = { Color = tab_fg } },
		{ Attribute = { Intensity = is_active and "Bold" or "Normal" } },
		{ Text = " " .. tostring(tab_num) .. " " },
		-- Arrow pointing right (tab color into bar bg)
		{ Background = { Color = theme.bar_bg } },
		{ Foreground = { Color = tab_bg } },
		{ Text = nf.pl_left_hard_divider },
		-- Tab title on bar background
		{ Foreground = { Color = is_active and theme.fg or (hover and theme.fg or "#908e82") } },
		{ Text = " " .. title .. " " },
	}
end)
