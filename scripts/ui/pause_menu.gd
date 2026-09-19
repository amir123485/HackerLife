extends CanvasLayer
## Pause menu overlay.

signal resumed
signal saved
signal main_menu_requested

var root: Control
var settings_panel: CanvasLayer

func _ready() -> void:
	layer = 25
	visible = false
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.66)
	root.add_child(dim)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(320, 0)
	panel.add_theme_stylebox_override("panel", UiKit.panel_style(UiKit.BG, UiKit.ACCENT, 8, 2))
	root.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)
	v.add_child(UiKit.title("Paused", 24))

	var resume := UiKit.button("Resume", UiKit.ACCENT)
	resume.pressed.connect(func():
		Sfx.play("ui_click")
		resumed.emit())
	v.add_child(resume)

	var save := UiKit.button("Save game", UiKit.ACCENT2)
	save.pressed.connect(func():
		Sfx.play("ui_click")
		saved.emit())
	v.add_child(save)

	var set_btn := UiKit.button("Settings", UiKit.ACCENT2)
	set_btn.pressed.connect(func():
		Sfx.play("ui_click")
		settings_panel.show_over(root))
	v.add_child(set_btn)

	var menu := UiKit.button("Main menu", UiKit.WARN)
	menu.pressed.connect(func():
		Sfx.play("ui_click")
		main_menu_requested.emit())
	v.add_child(menu)

	var quit := UiKit.button("Quit game", UiKit.DANGER)
	quit.pressed.connect(func(): get_tree().quit())
	v.add_child(quit)

	settings_panel = load("res://scripts/ui/settings_panel.gd").new()
	add_child(settings_panel)
