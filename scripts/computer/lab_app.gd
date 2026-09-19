extends VBoxContainer
## CyberLab app: lessons with quizzes + lab status.

var lessons := [
        {
                "id": "lesson_ips",
                "title": "Lesson 1 - IP addresses & networks",
                "skill": "networking",
                "text": """An IP address (like 10.10.0.11) uniquely identifies a machine on a network.
Networks are named ranges, e.g. 10.10.0.0/24.
Before touching a machine, you map the network and find its address.""",
                "question": "What does an IP address do?",
                "choices": [
                        "Encrypts all traffic automatically",
                        "Uniquely identifies a machine on a network",
                        "Stores passwords for services",
                ],
                "answer": 1,
        },
        {
                "id": "lesson_ports",
                "title": "Lesson 2 - Ports & services",
                "skill": "networking",
                "text": """A machine can run many services at once.
Ports are numbered doors: 22 = SSH, 80 = HTTP, 443 = HTTPS.
Scanning a host reveals which doors are open - and what's behind them.""",
                "question": "SSH normally listens on which port?",
                "choices": ["80", "443", "22"],
                "answer": 2,
        },
        {
                "id": "lesson_auth",
                "title": "Lesson 3 - Authentication & logs",
                "skill": "linux",
                "text": """Services check who you are (authentication) and write down what happens (logs).
Failed logins, sessions and commands usually leave traces.
Professionals read logs to defend systems. Attackers leave evidence in them.""",
                "question": "Why do failed login attempts matter?",
                "choices": [
                        "They speed up the network",
                        "They are logged and can become evidence",
                        "They are invisible and never stored",
                ],
                "answer": 1,
        },
]

var lesson_list: VBoxContainer
var lesson_view: VBoxContainer

func _ready() -> void:
        add_theme_constant_override("separation", 10)
        var header := HBoxContainer.new()
        add_child(header)
        header.add_child(UiKit.title("CyberLab", 20))
        var sp := Control.new()
        sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        header.add_child(sp)
        header.add_child(UiKit.label("TRAINING-NET: ONLINE", 13, UiKit.ACCENT))
        var cols := HBoxContainer.new()
        cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
        cols.add_theme_constant_override("separation", 12)
        add_child(cols)
        lesson_list = VBoxContainer.new()
        lesson_list.custom_minimum_size = Vector2(300, 0)
        lesson_list.add_theme_constant_override("separation", 6)
        cols.add_child(lesson_list)
        lesson_view = VBoxContainer.new()
        lesson_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        lesson_view.add_theme_constant_override("separation", 8)
        cols.add_child(lesson_view)
        # lab status
        var status := PanelContainer.new()
        status.add_theme_stylebox_override("panel", UiKit.panel_style(Color(0.05, 0.09, 0.08), UiKit.ACCENT, 6))
        lesson_list.add_child(status)
        var sv := VBoxContainer.new()
        sv.add_child(UiKit.label("LAB MACHINES (simulated)", 13, UiKit.ACCENT))
        for h in Sim.net_summary():
                var st := "OPEN" if not h["locked"] else "LOCKED"
                var col: Color = UiKit.ACCENT if not h["locked"] else UiKit.WARN
                sv.add_child(UiKit.label("  %s  %s  [%s]" % [h["host"], h["ip"], st], 13, col))
        sv.add_child(UiKit.label("All targets are fictional. No real systems are contacted.", 11, UiKit.FG_DIM))
        lesson_list.add_child(UiKit.spacer(4))
        lesson_list.add_child(UiKit.label("LESSONS", 13, UiKit.ACCENT))
        for i in range(lessons.size()):
                var l: Dictionary = lessons[i]
                var done_mark := " [OK]" if Game.flag(l["id"]) else ""
                var b := UiKit.button(" %s%s" % [l["title"], done_mark], UiKit.ACCENT2, 13)
                b.alignment = HORIZONTAL_ALIGNMENT_LEFT
                b.pressed.connect(_open_lesson.bind(i))
                lesson_list.add_child(b)
        _show_hint()

func _show_hint() -> void:
        for c in lesson_view.get_children():
                c.queue_free()
        lesson_view.add_child(UiKit.label("Select a lesson to start learning.", 14, UiKit.FG_DIM))

func _open_lesson(i: int) -> void:
        Sfx.play("ui_click")
        var l: Dictionary = lessons[i]
        for c in lesson_view.get_children():
                c.queue_free()
        lesson_view.add_child(UiKit.title(l["title"], 16))
        var body := UiKit.label(str(l["text"]), 13)
        body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        body.custom_minimum_size = Vector2(420, 0)
        lesson_view.add_child(body)
        lesson_view.add_child(UiKit.spacer(6))
        lesson_view.add_child(UiKit.label(str(l["question"]), 14, UiKit.ACCENT2))
        for ci in range(l["choices"].size()):
                var ch: String = l["choices"][ci]
                var b := UiKit.button(" %d) %s" % [ci + 1, ch], UiKit.ACCENT, 13)
                b.alignment = HORIZONTAL_ALIGNMENT_LEFT
                b.pressed.connect(_answer.bind(i, ci))
                lesson_view.add_child(b)

func _answer(li: int, ci: int) -> void:
        var l: Dictionary = lessons[li]
        # rebuild feedback row
        for c in lesson_view.get_children():
                if c.has_meta("feedback"):
                        c.queue_free()
        if ci == int(l["answer"]):
                var ok := UiKit.label("Correct! +15 %s XP" % str(l["skill"]), 14, UiKit.ACCENT)
                ok.set_meta("feedback", true)
                lesson_view.add_child(ok)
                Sfx.play("success")
                if not Game.flag(str(l["id"])):
                        Game.set_flag(str(l["id"]))
                        Game.add_xp(str(l["skill"]), 15)
        else:
                var bad := UiKit.label("Not quite - think about the lesson text and try again.", 14, UiKit.DANGER)
                bad.set_meta("feedback", true)
                lesson_view.add_child(bad)
                Sfx.play("fail")
