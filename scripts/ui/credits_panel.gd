extends CanvasLayer
## Credits overlay.

var parent_ui: Control

func show_over(parent: Control) -> void:
	parent_ui = parent
	for c in parent.get_children():
		if c.has_meta("credits_overlay"):
			c.queue_free()
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.78)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.set_meta("credits_overlay", true)
	parent.add_child(dim)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(520, 0)
	panel.add_theme_stylebox_override("panel", UiKit.panel_style(UiKit.BG, UiKit.ACCENT, 8, 2))
	dim.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	panel.add_child(v)

	var title := UiKit.title("Credits", 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)

	var body := UiKit.label(
		"HackerLife  v0.1.0  (prototype)\n\n" +
		"Design, code, 3D environments, UI, audio:\n  built with the Super Z AI assistant (Z.ai)\n\n" +
		"Engine: Godot 4.7.2 (MIT license)\n\n" +
		"All assets are original and procedurally generated\nfor this project. No third-party copyrighted content.\n\n" +
		"Inspired by the general mood of open-world hacking games;\ncontains no assets, story or code from any existing game.\n\n" +
		"Special thanks to every curious kid who asks 'why?'.",
		14)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(body)

	var back := UiKit.button("Back", UiKit.ACCENT)
	back.pressed.connect(func():
		Sfx.play("ui_click")
		dim.queue_free())
	var wrap := HBoxContainer.new()
	wrap.alignment = BoxContainer.ALIGNMENT_CENTER
	wrap.add_child(back)
	v.add_child(wrap)
