extends CanvasLayer
## Main menu: title, new game, continue, settings, credits, quit.

signal start_game
signal continue_game

var root: Control
var settings_panel: CanvasLayer
var credits_panel: CanvasLayer

func _ready() -> void:
	layer = 30
	_build()
	Sfx.start_music()

func _build() -> void:
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.02, 0.03, 0.06)
	root.add_child(bg)
	# decorative neon lines
	for i in range(3):
		var line := ColorRect.new()
		line.color = Color(0.0, 0.8, 0.55, 0.10 + 0.05 * i)
		line.position = Vector2(0, 120 + i * 90)
		line.size = Vector2(1280, 1)
		root.add_child(line)
	var scan := ColorRect.new()
	scan.set_anchors_preset(Control.PRESET_FULL_RECT)
	scan.color = Color(0.0, 0.05, 0.02, 0.05)
	root.add_child(scan)

	var title := UiKit.title("HackerLife", 64, UiKit.ACCENT)
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.anchor_left = 0.5
	title.anchor_right = 0.5
	title.offset_left = -260
	title.offset_right = 260
	title.offset_top = 110
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title)
	var sub := UiKit.label("an original hacker-life simulation  -  prototype v0.1.0", 15, UiKit.FG_DIM)
	sub.set_anchors_preset(Control.PRESET_CENTER_TOP)
	sub.anchor_left = 0.5
	sub.anchor_right = 0.5
	sub.offset_left = -260
	sub.offset_right = 260
	sub.offset_top = 185
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(sub)

	var menu := VBoxContainer.new()
	menu.set_anchors_preset(Control.PRESET_CENTER)
	menu.anchor_top = 0.5
	menu.anchor_bottom = 0.5
	menu.anchor_left = 0.5
	menu.anchor_right = 0.5
	menu.offset_left = -110
	menu.offset_right = 110
	menu.offset_top = -10
	menu.add_theme_constant_override("separation", 10)
	root.add_child(menu)

	var new_btn := UiKit.button("NEW GAME", UiKit.ACCENT, 18)
	new_btn.pressed.connect(func():
		Sfx.play("ui_click")
		start_game.emit())
	menu.add_child(new_btn)

	var cont := UiKit.button("CONTINUE", UiKit.ACCENT2, 18)
	if not SaveIO.has_save():
		cont.disabled = true
		cont.modulate = Color(1, 1, 1, 0.4)
	cont.pressed.connect(func():
		Sfx.play("ui_click")
		continue_game.emit())
	menu.add_child(cont)

	var set_btn := UiKit.button("SETTINGS", UiKit.ACCENT2, 18)
	set_btn.pressed.connect(func():
		Sfx.play("ui_click")
		_open_settings())
	menu.add_child(set_btn)

	var cred_btn := UiKit.button("CREDITS", UiKit.ACCENT2, 18)
	cred_btn.pressed.connect(func():
		Sfx.play("ui_click")
		_open_credits())
	menu.add_child(cred_btn)

	var quit_btn := UiKit.button("QUIT", UiKit.DANGER, 18)
	quit_btn.pressed.connect(func(): get_tree().quit())
	menu.add_child(quit_btn)

	var safety := UiKit.label("All cyber targets in this game are fictional simulations. Learn, don't harm.", 12, UiKit.FG_DIM)
	safety.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	safety.anchor_top = 1.0
	safety.anchor_bottom = 1.0
	safety.offset_top = -36
	safety.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(safety)

	settings_panel = load("res://scripts/ui/settings_panel.gd").new()
	add_child(settings_panel)
	credits_panel = load("res://scripts/ui/credits_panel.gd").new()
	add_child(credits_panel)

func _open_settings() -> void:
	settings_panel.show_over(root)

func _open_credits() -> void:
	credits_panel.show_over(root)
