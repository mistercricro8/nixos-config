local mainMod = "SUPER"
local terminal = "kitty"
local fileManager = "dolphin"
local browser = "firefox"

local function bind_nav(keys, action_fn, options)
  local opts = options or {}
  local mod = keys.mod or (mainMod .. " + ")
  hl.bind(mod .. keys.arrow, action_fn, opts)
  hl.bind(mod .. keys.vim, action_fn, opts)
end

local directions = {
  { arrow = "left",  vim = "H", code = "l", x = -10, y = 0 },
  { arrow = "down",  vim = "J", code = "d", x = 0,   y = 10 },
  { arrow = "up",    vim = "K", code = "u", x = 0,   y = -10 },
  { arrow = "right", vim = "L", code = "r", x = 10,  y = 0 },
}

hl.define_submap("resize", function()
  for _, dir in ipairs(directions) do
    local v_key = dir.vim:lower()
    local resize_normal = function() hl.dispatch(hl.dsp.window.resize({ x = dir.x, y = dir.y, relative = true })) end
    hl.bind(dir.arrow, resize_normal, { repeating = true })
    hl.bind(v_key, resize_normal, { repeating = true })

    local resize_fast = function() hl.dispatch(hl.dsp.window.resize({ x = dir.x * 10, y = dir.y * 10, relative = true })) end
    hl.bind("SHIFT + " .. dir.arrow, resize_fast, { repeating = true })
    hl.bind("SHIFT + " .. v_key, resize_fast, { repeating = true })
  end

  hl.bind("escape", function() hl.dispatch(hl.dsp.submap("reset")) end)
end)
hl.bind(mainMod .. " + S", function() hl.dispatch(hl.dsp.submap("resize")) end)

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
  function() hl.dispatch(hl.dsp.exec_cmd("hyprctl switchxkblayout at-translated-set-2-keyboard next")) end)

hl.bind("XF86AudioRaiseVolume", function() hl.dispatch(hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+")) end,
  { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", function() hl.dispatch(hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-")) end,
  { locked = true, repeating = true })
hl.bind("XF86AudioMute", function() hl.dispatch(hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")) end,
  { locked = true })
hl.bind("XF86MonBrightnessDown", function() hl.dispatch(hl.dsp.exec_cmd("brightnessctl s 5%-")) end, { repeating = true })
hl.bind("XF86MonBrightnessUp", function() hl.dispatch(hl.dsp.exec_cmd("brightnessctl s 5%+")) end, { repeating = true })

hl.bind("Print", function() hl.dispatch(hl.dsp.exec_cmd("hyprshot -z -m active -m window")) end)
hl.bind("SHIFT + Print", function() hl.dispatch(hl.dsp.exec_cmd("hyprshot -z -m region")) end)
hl.bind(mainMod .. " + V", function() hl.dispatch(hl.dsp.exec_cmd("dms ipc call clipboard toggle")) end)
hl.bind(mainMod .. " + code:95",
  function() hl.dispatch(hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" })) end)
hl.bind(mainMod .. " + SHIFT + code:95",
  function() hl.dispatch(hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" })) end)

for _, dir in ipairs(directions) do
  bind_nav({ mod = mainMod .. " + ", arrow = dir.arrow, vim = dir.vim }, function()
    hl.dispatch(hl.dsp.focus({ direction = dir.code }))
  end)

  bind_nav({ mod = mainMod .. " + CTRL + ", arrow = dir.arrow, vim = dir.vim }, function()
    hl.dispatch(hl.dsp.focus({ monitor = dir.code }))
  end)

  bind_nav({ mod = mainMod .. " + SHIFT + CTRL + ", arrow = dir.arrow, vim = dir.vim }, function()
    hl.dispatch(hl.dsp.window.move({ monitor = dir.code }))
  end)
end

local ok, smw = pcall(require, "plugins.split-monitor-workspaces")
if ok then
  smw.setup({
    monitor_priority = { "eDP-1" },
    enable_persistent_workspaces = false
  })
  for i = 1, 10 do
    local n = (i == 10) and "0" or tostring(i)
    hl.bind(mainMod .. " + " .. n, smw.workspace(tostring(i)))
    hl.bind(mainMod .. " + SHIFT + " .. n, smw.move_to_workspace(tostring(i)))
  end

  hl.bind(mainMod .. " + mouse_down", smw.cycle_workspaces("next"))
  hl.bind(mainMod .. " + mouse_up", smw.cycle_workspaces("prev"))
  hl.bind(mainMod .. " + CTRL + mouse_down", smw.move_to_workspace("+1"))
  hl.bind(mainMod .. " + CTRL + mouse_up", smw.move_to_workspace("-1"))
else
  for i = 1, 10 do
    local n = (i == 10) and "0" or tostring(i)
    hl.bind(mainMod .. " + " .. n, function() hl.dispatch(hl.dsp.focus({ workspace = n })) end)
    hl.bind(mainMod .. " + SHIFT + " .. n, function() hl.dispatch(hl.dsp.window.move({ workspace = n })) end)
  end

  hl.bind(mainMod .. " + mouse_down", function() hl.dispatch(hl.dsp.focus({ workspace = "e+1" })) end)
  hl.bind(mainMod .. " + mouse_up", function() hl.dispatch(hl.dsp.focus({ workspace = "e-1" })) end)
  hl.bind(mainMod .. " + CTRL + mouse_down", function() hl.dispatch(hl.dsp.window.move({ workspace = "e+1" })) end)
  hl.bind(mainMod .. " + CTRL + mouse_up", function() hl.dispatch(hl.dsp.window.move({ workspace = "e-1" })) end)
end

hl.bind(mainMod .. " + mouse:272", function() hl.dispatch(hl.dsp.window.drag()) end, { mouse = true })
hl.bind(mainMod .. " + mouse:273", function() hl.dispatch(hl.dsp.window.resize()) end, { mouse = true })
