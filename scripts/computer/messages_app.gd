extends HBoxContainer
## Messages app: inbox with story messages. First open starts the mission.

var list_box: VBoxContainer
var reader: RichTextLabel

var messages := [
	{"from": "Ghost", "subject": "Welcome to OpenShell", "body": """[color=#4dd8ff]From: Ghost <ghost@openshell.academy>[/color]

Hey Ari,

Welcome to the Academy's training program. I saw your forum posts - you ask good questions.

The CyberLab on this PC connects you to our [color=#37ff8b]TRAINING network[/color]. Everything there is simulated and safe. It's where you'll practice.

Check [color=#37ff8b]first_connection.txt[/color] in your Files when you're ready for your first exercise.

- Ghost"""},
	{"from": "Ghost", "subject": "MISSION: FIRST CONNECTION", "body": """[color=#4dd8ff]From: Ghost <ghost@openshell.academy>[/color]

Your first exercise: reach [color=#37ff8b]TEST-PC-01[/color] over the training network and bring back the token from [color=#ffd166]flag.txt[/color].

1. Open the Terminal
2. [color=#37ff8b]help[/color] - learn the basics
3. [color=#37ff8b]network[/color] - see the lab
4. [color=#37ff8b]scan TEST-PC-01[/color]
5. [color=#37ff8b]connect TEST-PC-01[/color] (student login is in notes.txt)
6. [color=#37ff8b]ls[/color], then [color=#37ff8b]read flag.txt[/color]
7. [color=#37ff8b]submit <token>[/color]

Slow is smooth, smooth is fast.
- Ghost"""},
	{"from": "Mom", "subject": "dinner is in the fridge", "body": """[color=#4dd8ff]From: Mom[/color]

Don't stay up all night on that computer again.
There's food in the fridge. School tomorrow!

Love you."""},
]

func _ready() -> void:
	add_theme_constant_override("separation", 10)
	list_box = VBoxContainer.new()
	list_box.custom_minimum_size = Vector2(280, 0)
	list_box.add_theme_constant_override("separation", 6)
	add_child(list_box)
	reader = RichTextLabel.new()
	reader.bbcode_enabled = true
	reader.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reader.add_theme_font_size_override("normal_font_size", 14)
	add_child(reader)
	var title := UiKit.label("inbox (%d)" % messages.size(), 13, UiKit.FG_DIM)
	list_box.add_child(title)
	for i in range(messages.size()):
		var m: Dictionary = messages[i]
		var b := UiKit.button(" %s: %s" % [m["from"], m["subject"]], UiKit.ACCENT, 13)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(_open_msg.bind(i))
		list_box.add_child(b)
	_show_hint()
	# opening messages for the first time kicks off the story
	if not Game.flag("mission_started") and not Missions.mission_complete:
		Game.set_flag("mission_started")
		Missions.start_mission()

func _show_hint() -> void:
	reader.clear()
	reader.append_text("[color=#7a8a99]Select a message.[/color]")

func _open_msg(i: int) -> void:
	Sfx.play("ui_click")
	var m: Dictionary = messages[i]
	reader.clear()
	reader.append_text(str(m["body"]))
