local mainMod = "SUPER"
local terminal = "kitty"
local fileManager = "dolphin"
local browser = "firefox"

-- Submap: Resize
hl.define_submap("resize", function()
  local directions = {
    { key = "right", vim = "l", x = 10,  y = 0 },
    { key = "left",  vim = "h", x = -10, y = 0 },
    { key = "up",    vim = "k", x = 0,   y = -10 },
    { key = "down",  vim = "j", x = 0,   y = 10 },
  }

  for _, dir in ipairs(directions) do
    hl.bind(dir.key, function() hl.dispatch(hl.dsp.window.resize({ x = dir.x, y = dir.y, relative = true })) end,
      { repeating = true })
    hl.bind(dir.vim, function() hl.dispatch(hl.dsp.window.resize({ x = dir.x, y = dir.y, relative = true })) end,
      { repeating = true })

    hl.bind("SHIFT + " .. dir.key,
      function() hl.dispatch(hl.dsp.window.resize({ x = dir.x * 10, y = dir.y * 10, relative = true })) end,
      { repeating = true })
    hl.bind("SHIFT + " .. dir.vim,
      function() hl.dispatch(hl.dsp.window.resize({ x = dir.x * 10, y = dir.y * 10, relative = true })) end,
      { repeating = true })
  end

  hl.bind("escape", function() hl.dispatch(hl.dsp.submap("reset")) end)
end)
hl.bind(mainMod .. " + S", function() hl.dispatch(hl.dsp.submap("resize")) end)

-- Core Actions
hl.bind(mainMod .. " + Q", function() hl.dispatch(hl.dsp.exec_cmd(terminal)) end)
hl.bind(mainMod .. " + C", function() hl.dispatch(hl.dsp.window.close()) end)
hl.bind(mainMod .. " + E", function() hl.dispatch(hl.dsp.exec_cmd(fileManager)) end)
hl.bind(mainMod .. " + T", function() hl.dispatch(hl.dsp.window.float({ action = "toggle" })) end)
hl.bind(mainMod .. " + R", function() hl.dispatch(hl.dsp.exec_cmd("dms ipc call spotlight toggle")) end)
hl.bind(mainMod .. " + Y", function() hl.dispatch(hl.dsp.layout("togglesplit")) end)
hl.bind(mainMod .. " + O", function() hl.dispatch(hl.dsp.exec_cmd("dms ipc call lock lock")) end)
hl.bind(mainMod .. " + escape", function() hl.dispatch(hl.dsp.exit()) end)
hl.bind(mainMod .. " + F", function() hl.dispatch(hl.dsp.exec_cmd(browser)) end)
hl.bind(mainMod .. " + space",
  function() hl.dispatch(hl.dsp.exec_cmd("hyprctl switchxkblayout usb-keyboard-usb-keyboard next")) end)

-- Hardware Controls (Audio & Brightness)
hl.bind("XF86AudioRaiseVolume", function() hl.dispatch(hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+")) end,
  { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", function() hl.dispatch(hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-")) end,
  { locked = true, repeating = true })
hl.bind("XF86AudioMute", function() hl.dispatch(hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")) end,
  { locked = true })
hl.bind("XF86MonBrightnessDown", function() hl.dispatch(hl.dsp.exec_cmd("brightnessctl s 5%-")) end, { repeating = true })
hl.bind("XF86MonBrightnessUp", function() hl.dispatch(hl.dsp.exec_cmd("brightnessctl s 5%+")) end, { repeating = true })

-- Utility & Screenshots
hl.bind("Print", function() hl.dispatch(hl.dsp.exec_cmd("hyprshot -z -m active -m window")) end)
hl.bind("SHIFT + Print", function() hl.dispatch(hl.dsp.exec_cmd("hyprshot -z -m region")) end)
hl.bind(mainMod .. " + V", function() hl.dispatch(hl.dsp.exec_cmd("dms ipc call clipboard toggle")) end)
hl.bind(mainMod .. " + code:95",
  function() hl.dispatch(hl.dsp.window.fullscreen({ mode = "maximized", action = "set" })) end)
hl.bind(mainMod .. " + SHIFT + code:95",
  function() hl.dispatch(hl.dsp.window.fullscreen({ mode = "fullscreen", action = "set" })) end)

-- Focus Navigation
hl.bind(mainMod .. " + left", function() hl.dispatch(hl.dsp.focus({ direction = "l" })) end)
hl.bind(mainMod .. " + right", function() hl.dispatch(hl.dsp.focus({ direction = "r" })) end)
hl.bind(mainMod .. " + up", function() hl.dispatch(hl.dsp.focus({ direction = "u" })) end)
hl.bind(mainMod .. " + down", function() hl.dispatch(hl.dsp.focus({ direction = "d" })) end)
hl.bind(mainMod .. " + H", function() hl.dispatch(hl.dsp.focus({ direction = "l" })) end)
hl.bind(mainMod .. " + J", function() hl.dispatch(hl.dsp.focus({ direction = "d" })) end)
hl.bind(mainMod .. " + K", function() hl.dispatch(hl.dsp.focus({ direction = "u" })) end)
hl.bind(mainMod .. " + L", function() hl.dispatch(hl.dsp.focus({ direction = "r" })) end)

-- Standard Workspace Navigation (1-10)
local ok, smw = pcall(require, "plugins.split-monitor-workspaces")
if ok then
  smw.setup({
    monitor_priority = { "eDP-1" },
    enable_persistent_workspaces = false
  })
  for i = 1, 10 do
    local n = tostring(i)
    if n == "10" then n = "0" end
    hl.bind(mainMod .. " + " .. n, smw.workspace(tostring(i)))
    hl.bind(mainMod .. " + SHIFT + " .. n, smw.move_to_workspace_silent(tostring(i)))
  end

  -- Mouse Wheel Navigation
  hl.bind(mainMod .. " + mouse_down", smw.cycle_workspaces("next"))
  hl.bind(mainMod .. " + mouse_up", smw.cycle_workspaces("prev"))
  hl.bind(mainMod .. " + CTRL + mouse_down", smw.move_to_workspace_silent("+1"))
  hl.bind(mainMod .. " + CTRL + mouse_up", smw.move_to_workspace_silent("-1"))
else
  for i = 1, 10 do
    local n = tostring(i)
    if n == "10" then n = "0" end
    hl.bind(mainMod .. " + " .. tostring(n), function() hl.dispatch(hl.dsp.focus({ workspace = tostring(n) })) end)
    hl.bind(mainMod .. " + SHIFT + " .. tostring(n),
      function() hl.dispatch(hl.dsp.window.move({ workspace = tostring(n) })) end)
  end

  -- Mouse Wheel Navigation
  hl.bind(mainMod .. " + mouse_down", function() hl.dispatch(hl.dsp.focus({ workspace = "e+1" })) end)
  hl.bind(mainMod .. " + mouse_up", function() hl.dispatch(hl.dsp.focus({ workspace = "e-1" })) end)
  hl.bind(mainMod .. " + CTRL + mouse_down", function() hl.dispatch(hl.dsp.window.move({ workspace = "e+1" })) end)
  hl.bind(mainMod .. " + CTRL + mouse_up", function() hl.dispatch(hl.dsp.window.move({ workspace = "e-1" })) end)
end

-- Monitor Navigation
hl.bind(mainMod .. " + CTRL + left", function() hl.dispatch(hl.dsp.focus({ monitor = "l" })) end)
hl.bind(mainMod .. " + CTRL + right", function() hl.dispatch(hl.dsp.focus({ monitor = "r" })) end)
hl.bind(mainMod .. " + CTRL + up", function() hl.dispatch(hl.dsp.focus({ monitor = "u" })) end)
hl.bind(mainMod .. " + CTRL + down", function() hl.dispatch(hl.dsp.focus({ monitor = "d" })) end)
hl.bind(mainMod .. " + CTRL + H", function() hl.dispatch(hl.dsp.focus({ monitor = "l" })) end)
hl.bind(mainMod .. " + CTRL + J", function() hl.dispatch(hl.dsp.focus({ monitor = "d" })) end)
hl.bind(mainMod .. " + CTRL + K", function() hl.dispatch(hl.dsp.focus({ monitor = "u" })) end)
hl.bind(mainMod .. " + CTRL + L", function() hl.dispatch(hl.dsp.focus({ monitor = "r" })) end)

-- Move to Monitor
hl.bind(mainMod .. " + SHIFT + CTRL + left", function() hl.dispatch(hl.dsp.window.move({ monitor = "l" })) end)
hl.bind(mainMod .. " + SHIFT + CTRL + down", function() hl.dispatch(hl.dsp.window.move({ monitor = "d" })) end)
hl.bind(mainMod .. " + SHIFT + CTRL + up", function() hl.dispatch(hl.dsp.window.move({ monitor = "u" })) end)
hl.bind(mainMod .. " + SHIFT + CTRL + right", function() hl.dispatch(hl.dsp.window.move({ monitor = "r" })) end)
hl.bind(mainMod .. " + SHIFT + CTRL + H", function() hl.dispatch(hl.dsp.window.move({ monitor = "l" })) end)
hl.bind(mainMod .. " + SHIFT + CTRL + J", function() hl.dispatch(hl.dsp.window.move({ monitor = "d" })) end)
hl.bind(mainMod .. " + SHIFT + CTRL + K", function() hl.dispatch(hl.dsp.window.move({ monitor = "u" })) end)
hl.bind(mainMod .. " + SHIFT + CTRL + L", function() hl.dispatch(hl.dsp.window.move({ monitor = "r" })) end)


-- Mouse Bindings (Drag/Resize)
hl.bind(mainMod .. " + mouse:272", function() hl.dispatch(hl.dsp.window.drag()) end, { mouse = true })
hl.bind(mainMod .. " + mouse:273", function() hl.dispatch(hl.dsp.window.resize()) end, { mouse = true })
