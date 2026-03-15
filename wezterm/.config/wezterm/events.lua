local wezterm = require("wezterm")
local mux = wezterm.mux

wezterm.on("gui-startup", function()
  mux.spawn_window({})
end)

local active_bg = "#7a9970"
local inactive_bg = "#3b3b3b"

wezterm.on("update-status", function(window, pane)
  local overrides = window:get_config_overrides() or {}
  overrides.colors = overrides.colors or {}
  overrides.colors.split = active_bg
  window:set_config_overrides(overrides)

  local cwd_uri = pane:get_current_working_dir()
  local branch = ""
  if cwd_uri then
    local cwd = cwd_uri.file_path or ""
    local success, stdout = wezterm.run_child_process({
      "git", "-C", cwd, "rev-parse", "--abbrev-ref", "HEAD",
    })
    if success and stdout then
      branch = stdout:gsub("%s+$", "")
    end
    if branch == "" then
      local ok, wt_out = wezterm.run_child_process({
        "git", "-C", cwd, "worktree", "list", "--porcelain",
      })
      if ok and wt_out then
        for line in wt_out:gmatch("[^\n]+") do
          if line:match("^worktree " .. cwd) then
            local next_branch = wt_out:match("branch refs/heads/(%S+)", line:len())
            if next_branch then
              branch = next_branch
            end
          end
        end
      end
    end
  end

  if branch ~= "" then
    window:set_right_status(wezterm.format({
      { Background = { Color = "#7a9970" } },
      { Foreground = { Color = "#1a1a1a" } },
      { Attribute = { Intensity = "Bold" } },
      { Text = "  " .. branch .. "  " },
    }))
  else
    window:set_right_status("")
  end
end)

wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
  local tab_num = tab.tab_index + 1
  local title = tab.active_pane.title
  if title and #title > 20 then
    title = title:sub(1, 20) .. ".."
  end

  local is_active = tab.is_active
  local bar_bg = "#1e1e1e"

  if is_active then
    return {
      { Background = { Color = bar_bg } },
      { Text = " " },
      { Background = { Color = "#7a9970" } },
      { Foreground = { Color = "#1a1a1a" } },
      { Attribute = { Intensity = "Bold" } },
      { Text = " " .. tostring(tab_num) .. " " },
      { Background = { Color = "#2a2a2a" } },
      { Foreground = { Color = "#e0e0e0" } },
      { Attribute = { Intensity = "Bold" } },
      { Text = " " .. title .. " " },
      { Background = { Color = bar_bg } },
      { Text = " " },
    }
  else
    return {
      { Background = { Color = bar_bg } },
      { Text = " " },
      { Background = { Color = "#3b3b3b" } },
      { Foreground = { Color = "#909090" } },
      { Text = " " .. tostring(tab_num) .. " " },
      { Background = { Color = bar_bg } },
      { Foreground = { Color = "#666666" } },
      { Text = " " .. title .. " " },
    }
  end
end)
