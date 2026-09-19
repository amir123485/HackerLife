extends CanvasLayer
## Shared settings panel used by main menu and pause menu.

signal closed

var parent_ui: Control   # where to attach the overlay

func show_over(parent: Control) -> void:
	parent_ui = parent
	for c in parent.get_children():
		if c.has_meta("settings_overlay"):
			c.queue_free()
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.set_meta("settings_overlay", true)
	parent.add_child(dim)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(430, 0)
	panel.add_theme_stylebox_override("panel", UiKit.panel_style(UiKit.BG, UiKit.ACCENT2, 8, 2))
	dim.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)

	v.add_child(UiKit.title("Settings", 22))

	var fs_btn := UiKit.button(_fs_text(), UiKit.ACCENT2)
	fs_btn.pressed.connect(func():
		Config.set_fullscreen(not bool(Config.values.get("fullscreen", false)))
		fs_btn.text = _fs_text())
	v.add_child(fs_btn)

	var vs_btn := UiKit.button(_vs_text(), UiKit.ACCENT2)
	vs_btn.pressed.connect(func():
		Config.set_value("vsync", not bool(Config.values.get("vsync", true)))
		Config.set_vsync(bool(Config.values["vsync"]))
		vs_btn.text = _vs_text())
	v.add_child(vs_btn)

	var sh_btn := UiKit.button(_sh_text(), UiKit.ACCENT2)
	sh_btn.pressed.connect(func():
		Config.set_value("shadows", not bool(Config.values.get("shadows", true)))
		Config.set_shadows(bool(Config.values["shadows"]))
		sh_btn.text = _sh_text())
	v.add_child(sh_btn)

	var gl_btn := UiKit.button(_gl_text(), UiKit.ACCENT2)
	gl_btn.pressed.connect(func():
		Config.set_value("glow", not bool(Config.values.get("glow", true)))
		Config.set_glow(bool(Config.values["glow"]))
		gl_btn.text = _gl_text())
	v.add_child(gl_btn)

	var msaa_btn := UiKit.button(_msaa_text(), UiKit.ACCENT2)
	msaa_btn.pressed.connect(func():
		Config.set_value("msaa", (int(Config.values.get("msaa", 1)) + 1) % 3)
		Config.set_msaa(int(Config.values["msaa"]))
		msaa_btn.text = _msaa_text())
	v.add_child(msaa_btn)

	# mouse sensitivity slider
	var sens_row := HBoxContainer.new()
	sens_row.add_child(UiKit.label("Mouse sensitivity", 14))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sens_row.add_child(sp)
	var sens := HSlider.new()
	sens.min_value = 0.3
	sens.max_value = 2.5
	sens.step = 0.05
	sens.value = float(Config.values.get("mouse_sensitivity", 1.0))
	sens.custom_minimum_size = Vector2(180, 16)
	sens.value_changed.connect(func(val): Config.set_value("mouse_sensitivity", val))
	sens_row.add_child(sens)
	v.add_child(sens_row)

	# volume sliders
	var mv := HSlider.new()
	mv.min_value = 0.0
	mv.max_value = 1.0
	mv.step = 0.05
	mv.value = float(Config.values.get("master_volume", 0.8))
	mv.custom_minimum_size = Vector2(180, 16)
	mv.value_changed.connect(func(val):
		Config.set_value("master_volume", val)
		Sfx.set_volumes(val, float(Config.values.get("music_volume", 0.55)), float(Config.values.get("sfx_volume", 0.9))))
	_add_slider(v, "Master volume", mv)

	var musv := HSlider.new()
	musv.min_value = 0.0
	musv.max_value = 1.0
	musv.step = 0.05
	musv.value = float(Config.values.get("music_volume", 0.55))
	musv.custom_minimum_size = Vector2(180, 16)
	musv.value_changed.connect(func(val):
		Config.set_value("music_volume", val)
		Sfx.set_volumes(float(Config.values.get("master_volume", 0.8)), val, float(Config.values.get("sfx_volume", 0.9))))
	_add_slider(v, "Music volume", musv)

	var back := UiKit.button("Back", UiKit.DANGER)
	back.pressed.connect(func():
		Sfx.play("ui_click")
		dim.queue_free()
		closed.emit())
	v.add_child(back)

func _add_slider(parent: VBoxContainer, name_: String, slider: HSlider) -> void:
	var row := HBoxContainer.new()
	row.add_child(UiKit.label(name_, 14))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(sp)
	row.add_child(slider)
	parent.add_child(row)

func _fs_text() -> String:
	return "Display: %s" % ("Fullscreen" if bool(Config.values.get("fullscreen", false)) else "Windowed")

func _vs_text() -> String:
	return "VSync: %s" % ("On" if bool(Config.values.get("vsync", true)) else "Off")

func _sh_text() -> String:
	return "Shadows: %s" % ("On" if bool(Config.values.get("shadows", true)) else "Off")

func _gl_text() -> String:
	return "Glow/bloom: %s" % ("On" if bool(Config.values.get("glow", true)) else "Off")

func _msaa_text() -> String:
	var names := ["Off", "2x", "4x"]
	return "Anti-aliasing: %s" % names[int(Config.values.get("msaa", 1))]
