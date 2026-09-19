extends VBoxContainer
## NyxNet browser — fictional sites only.

const PAGES := {
	"home": """[color=#4dd8ff]== NyxNet ==[/color]

Fictional sites on the simulated net:
  [color=#37ff8b]openshell.academy[/color]  - your cyber school
  [color=#37ff8b]nexacorp.example[/color]  - megacorp PR page
  [color=#37ff8b]bughunt.example[/color]   - bug bounty platform (coming soon)

Search: try typing [color=#ffd166]search cybersecurity[/color] below.""",
	"openshell": """[color=#4dd8ff]== OpenShell Academy ==[/color]

A fictional online school for young hackers who want to do it RIGHT.

Courses: Linux, Networking, Web Security, Forensics.
Labs run on simulated machines. No real targets, ever.

Graduates work as security analysts, pentesters and researchers.
Keep it legal. Keep it clean. Learn fast.""",
	"nexacorp": """[color=#4dd8ff]== NexaCorp ==[/color]

"Connecting tomorrow, responsibly." (TM)

NexaCorp is a fictional megacorporation in the HackerLife universe.
Its subsidiaries include NexaBank, NexaGrid and NexaSocial.

Their systems are legendary. Their logs are legendary too.
They sponsor bug bounty programs on [color=#37ff8b]bughunt.example[/color].""",
	"bughunt": """[color=#4dd8ff]== BugHunt ==[/color]

The fictional bug bounty platform.

[color=#ffd166]STATUS: COMING SOON (future update)[/color]

Planned programs:
  - ACME WEB SERVICES      reward 500 - 10,000 cr
  - NexaSocial API         reward 1,000 - 25,000 cr
  - CityTransit Grid       reward 750 - 15,000 cr

Researcher level determines program access.
All targets are simulated game environments.""",
}

var page: RichTextLabel
var cmd: LineEdit

func _ready() -> void:
	add_theme_constant_override("separation", 8)
	var links := HBoxContainer.new()
	links.add_theme_constant_override("separation", 8)
	add_child(links)
	for p in ["home", "openshell", "nexacorp", "bughunt"]:
		var b := UiKit.button(p + ".example", UiKit.ACCENT2, 13)
		b.pressed.connect(_goto.bind(p))
		links.add_child(b)
	page = RichTextLabel.new()
	page.bbcode_enabled = true
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_theme_font_size_override("normal_font_size", 14)
	add_child(page)
	cmd = LineEdit.new()
	cmd.placeholder_text = "search nyxnet..."
	cmd.text_submitted.connect(_on_search)
	add_child(cmd)
	_goto("home")

func _goto(p: String) -> void:
	Sfx.play("ui_click")
	page.clear()
	page.append_text(PAGES[p])

func _on_search(text: String) -> void:
	Sfx.play("typing")
	var q := text.strip_edges().to_lower().trim_prefix("search ").strip_edges()
	page.clear()
	if q == "" :
		page.append_text("[color=#7a8a99]Type something to search.[/color]")
		return
	page.append_text("[color=#4dd8ff]== NyxNet results for '%s' ==[/color]\n\n" % q)
	page.append_text("[color=#37ff8b]openshell.academy[/color] - learn cybersecurity the legal way\n")
	page.append_text("[color=#37ff8b]nexacorp.example[/color] - a very responsible megacorp\n")
	page.append_text("[color=#37ff8b]wiki.nychnet[/color] - 'IP address' article\n")
	page.append_text("\n[color=#7a8a99]3 results (simulated net)[/color]")
