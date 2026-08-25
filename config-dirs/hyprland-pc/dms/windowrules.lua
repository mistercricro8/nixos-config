-- DMS Window Rules — managed by DankMaterialShell
-- Do not edit manually; changes may be overwritten

-- DMS-RULE: id=dms_rule_0, name=
hl.window_rule({ rounding = 0 })

-- DMS-RULE: id=dms_rule_1, name=
hl.window_rule({ match = { class = "^(org\\.wezfurlong\\.wezterm)$" }, tile = true })

-- DMS-RULE: id=dms_rule_2, name=
hl.window_rule({ match = { class = "^(org\\.gnome\\.)" }, rounding = 12 })

-- DMS-RULE: id=dms_rule_3, name=
hl.window_rule({ match = { class = "^(gnome-control-center)$" }, tile = true })

-- DMS-RULE: id=dms_rule_4, name=
hl.window_rule({ match = { class = "^(pavucontrol)$" }, tile = true })

-- DMS-RULE: id=dms_rule_5, name=
hl.window_rule({ match = { class = "^(nm-connection-editor)$" }, tile = true })

-- DMS-RULE: id=dms_rule_6, name=
hl.window_rule({ match = { class = "^(org\\.gnome\\.Calculator)$" }, float = true })

-- DMS-RULE: id=dms_rule_7, name=
hl.window_rule({ match = { class = "^(gnome-calculator)$" }, float = true })

-- DMS-RULE: id=dms_rule_8, name=
hl.window_rule({ match = { class = "^(galculator)$" }, float = true })

-- DMS-RULE: id=dms_rule_9, name=
hl.window_rule({ match = { class = "^(blueman-manager)$" }, float = true })

-- DMS-RULE: id=dms_rule_10, name=
hl.window_rule({ match = { class = "^(org\\.gnome\\.Nautilus)$" }, float = true })

-- DMS-RULE: id=dms_rule_11, name=
hl.window_rule({ match = { class = "^(xdg-desktop-portal)$" }, float = true })

-- DMS-RULE: id=dms_rule_12, name=
hl.window_rule({ match = { class = "^(steam)$", title = "^(notificationtoasts)" }, no_focus = true, pin = true })

-- DMS-RULE: id=dms_rule_13, name=
hl.window_rule({ match = { class = "^(firefox)$", title = "^(Picture-in-Picture)$" }, float = true })

-- DMS-RULE: id=dms_rule_14, name=
hl.window_rule({ match = { class = "^(zoom)$" }, float = true })

-- DMS-RULE: id=wr_1783293111991321389, name=com.danklinux.dms
hl.window_rule({ match = { class = "^com.danklinux.dms$" }, float = true })

-- DMS-RULE: id=wr_1784516188854621837, name=octave-gui
hl.window_rule({ match = { class = "^octave-gui$" }, float = true })
