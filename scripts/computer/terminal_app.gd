extends VBoxContainer
## NyxOS terminal — operates ONLY on the fictional simulation network.

enum Mode { LOCAL, AUTH_USER, AUTH_PASS, CONNECTED }

const GREEN := "#37ff8b"
const CYAN := "#4dd8ff"
const RED := "#ff5c69"
const YELLOW := "#ffd166"
const DIM := "#7a8a99"

var out: RichTextLabel
var input: LineEdit
var mode: int = Mode.LOCAL
var auth_host: String = ""
var auth_user: String = ""
var auth_pass: String = ""
var connected_host: String = ""
var history: Array = []
var hist_idx: int = -1

func _ready() -> void:
        add_theme_constant_override("separation", 6)
        out = RichTextLabel.new()
        out.bbcode_enabled = true
        out.scroll_following = true
        out.size_flags_vertical = Control.SIZE_EXPAND_FILL
        out.add_theme_font_size_override("normal_font_size", 15)
        out.add_theme_font_size_override("mono_font_size", 15)
        add_child(out)
        input = LineEdit.new()
        input.add_theme_font_size_override("font_size", 15)
        input.text_submitted.connect(_on_submit)
        input.text_changed.connect(func(_t): Sfx.play("key"))
        input.gui_input.connect(_on_input_gui)
        add_child(input)
        _print("NyxOS terminal v2.1 (simulated environment)")
        _print("Type [color=%s]help[/color] to list commands." % GREEN)
        _prompt()

func _print(t: String) -> void:
        out.append_text(t + "\n")

func _prompt() -> void:
        match mode:
                Mode.LOCAL:
                        input.placeholder_text = "ari@home:~$"
                Mode.AUTH_USER:
                        input.placeholder_text = "login:"
                Mode.AUTH_PASS:
                        input.placeholder_text = "password:"
                Mode.CONNECTED:
                        input.placeholder_text = "%s@%s:~$" % [auth_user.to_lower(), connected_host]

func _on_submit(text: String) -> void:
        Sfx.play("typing")
        if text.strip_edges() != "":
                history.append(text)
        hist_idx = history.size()
        _print("[color=%s]%s[/color] %s" % [GREEN, input.placeholder_text, text])
        var line := text.strip_edges()
        match mode:
                Mode.LOCAL:
                        _exec_local(line)
                Mode.AUTH_USER:
                        auth_user = line
                        mode = Mode.AUTH_PASS
                        _prompt()
                Mode.AUTH_PASS:
                        auth_pass = line
                        _try_login()
                Mode.CONNECTED:
                        _exec_remote(line)
        input.clear()
        out.scroll_to_line(out.get_line_count())

func _on_input_gui(event: InputEvent) -> void:
        if event is InputEventKey and event.pressed:
                if event.keycode == KEY_UP and history.size() > 0:
                        hist_idx = maxi(0, hist_idx - 1)
                        input.text = str(history[hist_idx])
                        input.caret_column = input.text.length()
                        input.accept_event()
                elif event.keycode == KEY_DOWN and history.size() > 0:
                        hist_idx = mini(history.size(), hist_idx + 1)
                        input.text = str(history[hist_idx]) if hist_idx < history.size() else ""
                        input.caret_column = input.text.length()
                        input.accept_event()

# ---------------------------------------------------------------- local
func _exec_local(line: String) -> void:
        var parts := line.split(" ", false)
        if parts.size() == 0 or parts[0] == "":
                return
        var cmd := parts[0].to_lower()
        match cmd:
                "help":
                        _print("Available commands:")
                        _print("  [color=%s]whoami[/color]        - who am i" % GREEN)
                        _print("  [color=%s]network[/color]       - show the training network" % GREEN)
                        _print("  [color=%s]scan <host>[/color]  - probe a machine for open ports" % GREEN)
                        _print("  [color=%s]connect <host>[/color] - open a session (asks for login)" % GREEN)
                        _print("  [color=%s]ls[/color]            - list files on this PC" % GREEN)
                        _print("  [color=%s]read <file>[/color] - read a local file" % GREEN)
                        _print("  [color=%s]skills[/color] money  date  echo  clear  exit" % GREEN)
                        if not Game.flag("xp_help"):
                                Game.set_flag("xp_help")
                                Game.add_xp("linux", 5)
                        Missions.report("ran_help")
                "clear":
                        out.clear()
                "whoami":
                        _print("ari (student, age %d) - nyxos local user" % Game.age)
                        if not Game.flag("xp_whoami"):
                                Game.set_flag("xp_whoami")
                                Game.add_xp("linux", 5)
                        Missions.report("ran_whoami")
                "date":
                        _print("%s, day %d, %s" % [TimeSys.weekday(), TimeSys.day, TimeSys.clock_text()])
                "skills":
                        for s in Game.xp.keys():
                                _print("  %-12s lvl %d  (%d xp)" % [s, Game.skill_level(s), Game.xp[s]])
                "money":
                        _print("credits: %d" % Game.money)
                "echo":
                        parts.remove_at(0)
                        _print(" ".join(parts))
                "ls":
                        var files := Sim.local_files()
                        for f in files.keys():
                                _print("  " + str(f))
                "read":
                        if parts.size() < 2:
                                _print("[color=%s]read: missing file name[/color]" % RED)
                                return
                        var files := Sim.local_files()
                        var fname := parts[1]
                        if files.has(fname):
                                _print("[color=%s]--- %s ---[/color]" % [CYAN, fname])
                                _print(str(files[fname]))
                                if fname == "notes.txt" and not Game.flag("read_notes_done"):
                                        Game.set_flag("read_notes_done")
                                        Game.add_xp("linux", 5)
                                        Missions.report("read_notes")
                        else:
                                _print("[color=%s]read: no such file '%s'[/color]" % [RED, fname])
                "network":
                        _print("[color=%s]%s[/color]" % [CYAN, Sim.LAB_NET])
                        for h in Sim.net_summary():
                                var status := "[color=%s]OPEN[/color]" % GREEN if not h["locked"] else "[color=%s]LOCKED[/color]" % YELLOW
                                _print("  %-14s %-12s %s" % [h["host"], h["ip"], status])
                        Game.add_xp("networking", 8)
                        Missions.report("ran_network")
                "scan":
                        if parts.size() < 2:
                                _print("[color=%s]scan: usage: scan <host>  (see: network)[/color]" % RED)
                                return
                        var res := Sim.scan_host(parts[1])
                        if not res["ok"]:
                                _print("[color=%s]%s[/color]" % [RED, res["msg"]])
                                return
                        _print("[color=%s]TARGET: %s (%s)[/color]" % [CYAN, res["host"], res["ip"]])
                        _print("OS: " + str(res["os"]))
                        _print("PORT   SERVICE   BANNER")
                        for p in res["ports"]:
                                _print("%-6d %-9s %s" % [p["port"], p["name"], p["banner"]])
                        Game.add_xp("networking", 10)
                        if str(res["host"]) == "TEST-PC-01":
                                Missions.report("ran_scan")
                "connect":
                        if parts.size() < 2:
                                _print("[color=%s]connect: usage: connect <host>[/color]" % RED)
                                return
                        var host := parts[1].to_upper()
                        if not Sim.host_exists(host):
                                _print("[color=%s]connect: unknown host '%s'[/color]" % [RED, host])
                                return
                        if Sim.is_locked(host):
                                _print("[color=%s]connect: %s is locked in this prototype. Try TEST-PC-01.[/color]" % [YELLOW, host])
                                return
                        auth_host = host
                        mode = Mode.AUTH_USER
                        _print("connecting to %s ... ok" % host)
                        _print("authentication required.")
                        _prompt()
                "exit":
                        _print("bye.")
                        var ui := get_tree().get_first_node_in_group("computer_ui")
                        if ui != null:
                                ui.call_deferred("_close_app")
                _:
                        _print("[color=%s]%s: command not found (try: help)[/color]" % [RED, cmd])

# ---------------------------------------------------------------- remote
func _try_login() -> void:
        var res := Sim.try_login(auth_host, auth_user, auth_pass)
        if res["ok"]:
                mode = Mode.CONNECTED
                connected_host = auth_host
                _print("[color=%s]%s[/color]" % [GREEN, res["msg"]])
                Game.add_xp("networking", 15)
                Missions.report("connected")
                _prompt()
        else:
                _print("[color=%s]%s[/color]" % [RED, res["msg"]])
                mode = Mode.LOCAL
                _prompt()

func _exec_remote(line: String) -> void:
        var parts := line.split(" ", false)
        if parts.size() == 0 or parts[0] == "":
                return
        var cmd := parts[0].to_lower()
        match cmd:
                "ls":
                        for f in Sim.remote_files(connected_host):
                                _print("  " + str(f))
                        Missions.report("ran_ls_remote")
                "read":
                        if parts.size() < 2:
                                _print("[color=%s]read: missing file name[/color]" % RED)
                                return
                        var res := Sim.read_remote_file(connected_host, parts[1])
                        if res["ok"]:
                                _print("[color=%s]--- %s ---[/color]" % [CYAN, parts[1]])
                                _print(str(res["content"]))
                                if parts[1] == "flag.txt":
                                        Missions.report("read_flag")
                                        Game.add_xp("linux", 10)
                        else:
                                _print("[color=%s]%s[/color]" % [RED, res["msg"]])
                "submit":
                        if parts.size() < 2:
                                _print("[color=%s]submit: usage: submit <token>[/color]" % RED)
                                return
                        if parts[1] == Sim.lab_token:
                                _print("[color=%s]token accepted. lab complete![/color]" % GREEN)
                                Missions.report("submitted")
                        else:
                                _print("[color=%s]submit: invalid token. hint: read flag.txt again.[/color]" % RED)
                "disconnect":
                        _print("session closed.")
                        _disconnect()
                "scan":
                        _print("[color=%s]scan: run from your home terminal (disconnect first)[/color]" % YELLOW)
                "exit":
                        _print("session closed. bye.")
                        _disconnect()
                        var ui := get_tree().get_first_node_in_group("computer_ui")
                        if ui != null:
                                ui.call_deferred("_close_app")
                _:
                        _print("[color=%s]%s: command not found on remote (try: ls, read, submit, disconnect)[/color]" % [RED, cmd])

func _disconnect() -> void:
        mode = Mode.LOCAL
        connected_host = ""
        auth_user = ""
        auth_pass = ""
        auth_host = ""
        _prompt()
