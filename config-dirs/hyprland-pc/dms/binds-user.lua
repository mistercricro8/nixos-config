local mainMod = "SUPER"
local terminal = "kitty"
local fileManager = "dolphin"

-- Submap: Music
hl.define_submap("music", function()
  hl.bind("P", function() hl.dispatch(hl.dsp.exec_cmd("playerctl play-pause")) end)
  hl.bind("I", function() hl.dispatch(hl.dsp.exec_cmd("playerctl volume 0.1+")) end, { repeating = true })
  hl.bind("O", function() hl.dispatch(hl.dsp.exec_cmd("playerctl volume 0.1-")) end, { repeating = true })
  hl.bind("Right", function() hl.dispatch(hl.dsp.exec_cmd("playerctl next")) end)
  hl.bind("Left", function() hl.dispatch(hl.dsp.exec_cmd("playerctl previous")) end)
  hl.bind("S",
    function() hl.dispatch(hl.dsp.exec_cmd("mpv --shuffle=yes --loop-playlist=inf --really-quiet $MUSIC_PATH")) end)
  hl.bind("D", function() hl.dispatch(hl.dsp.exec_cmd("playerctl stop mpv")) end)
  hl.bind("escape", function() hl.dispatch(hl.dsp.submap("reset")) end)
end)
hl.bind(mainMod .. " + M", function() hl.dispatch(hl.dsp.submap("music")) end)

-- Submap: Resize
hl.define_submap("resize", function()
  hl.bind("right", function() hl.dispatch(hl.dsp.window.resize({ x = 10, y = 0, relative = true })) end,
    { repeating = true })
  hl.bind("left", function() hl.dispatch(hl.dsp.window.resize({ x = -10, y = 0, relative = true })) end,
    { repeating = true })
  hl.bind("up", function() hl.dispatch(hl.dsp.window.resize({ x = 0, y = -10, relative = true })) end,
    { repeating = true })
  hl.bind("down", function() hl.dispatch(hl.dsp.window.resize({ x = 0, y = 10, relative = true })) end,
    { repeating = true })
  hl.bind("SHIFT + right", function() hl.dispatch(hl.dsp.window.resize({ x = 100, y = 0, relative = true })) end,
    { repeating = true })
  hl.bind("SHIFT + left", function() hl.dispatch(hl.dsp.window.resize({ x = -100, y = 0, relative = true })) end,
    { repeating = true })
  hl.bind("SHIFT + up", function() hl.dispatch(hl.dsp.window.resize({ x = 0, y = -100, relative = true })) end,
    { repeating = true })
  hl.bind("SHIFT + down", function() hl.dispatch(hl.dsp.window.resize({ x = 0, y = 100, relative = true })) end,
    { repeating = true })
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
hl.bind(mainMod .. " + F", function() hl.dispatch(hl.dsp.exec_cmd("firefox")) end)
hl.bind(mainMod .. " + space",
  function() hl.dispatch(hl.dsp.exec_cmd("hyprctl switchxkblayout usb-keyboard-usb-keyboard next")) end)

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
for i = 1, 9 do
  hl.bind(mainMod .. " + " .. tostring(i), function() hl.dispatch(hl.dsp.focus({ workspace = tostring(i) })) end)
  hl.bind(mainMod .. " + SHIFT + " .. tostring(i),
    function() hl.dispatch(hl.dsp.window.move({ workspace = tostring(i) })) end)
end
hl.bind(mainMod .. " + 0", function() hl.dispatch(hl.dsp.focus({ workspace = "10" })) end)
hl.bind(mainMod .. " + SHIFT + 0", function() hl.dispatch(hl.dsp.window.move({ workspace = "10" })) end)

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

-- Mouse Wheel Navigation
hl.bind(mainMod .. " + mouse_down", function() hl.dispatch(hl.dsp.focus({ workspace = "e+1" })) end)
hl.bind(mainMod .. " + mouse_up", function() hl.dispatch(hl.dsp.focus({ workspace = "e-1" })) end)
hl.bind(mainMod .. " + CTRL + mouse_down", function() hl.dispatch(hl.dsp.window.move({ workspace = "e+1" })) end)
hl.bind(mainMod .. " + CTRL + mouse_up", function() hl.dispatch(hl.dsp.window.move({ workspace = "e-1" })) end)

-- Mouse Bindings (Drag/Resize)
hl.bind(mainMod .. " + mouse:272", function() hl.dispatch(hl.dsp.window.drag()) end, { mouse = true })
hl.bind(mainMod .. " + mouse:273", function() hl.dispatch(hl.dsp.window.resize()) end, { mouse = true })
