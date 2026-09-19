extends HBoxContainer
## Files app: browse and read local files.

var list_box: VBoxContainer
var reader: RichTextLabel

func _ready() -> void:
	add_theme_constant_override("separation", 10)
	list_box = VBoxContainer.new()
	list_box.custom_minimum_size = Vector2(240, 0)
	list_box.add_theme_constant_override("separation", 6)
	add_child(list_box)
	reader = RichTextLabel.new()
	reader.bbcode_enabled = true
	reader.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reader.add_theme_font_size_override("normal_font_size", 14)
	add_child(reader)
	_refresh()
	_show_hint()

func _refresh() -> void:
	for c in list_box.get_children():
		c.queue_free()
	var files := Sim.local_files()
	var title := UiKit.label("home/ari/documents", 13, UiKit.FG_DIM)
	list_box.add_child(title)
	for fname in files.keys():
		var b := UiKit.button("  " + str(fname), UiKit.ACCENT2, 13)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(_open_file.bind(str(fname)))
		list_box.add_child(b)

func _show_hint() -> void:
	reader.clear()
	reader.append_text("[color=#7a8a99]Select a file to read it.[/color]\n\n[color=#37ff8b]notes.txt[/color] contains your beginner notes.\n[color=#37ff8b]first_connection.txt[/color] is the mission briefing.\n[color=#37ff8b]lab_guide.txt[/color] explains the CyberLab.")

func _open_file(fname: String) -> void:
	Sfx.play("ui_click")
	var files := Sim.local_files()
	if not files.has(fname):
		return
	reader.clear()
	reader.append_text("[color=#4dd8ff]== %s ==[/color]\n\n" % fname)
	var content := str(files[fname]).replace("[", "[lb]")
	reader.append_text(content.replace("\n", "\n"))
	if fname == "notes.txt":
		if not Game.flag("read_notes_done"):
			Game.set_flag("read_notes_done")
			Game.add_xp("linux", 5)
		Missions.report("read_notes")
