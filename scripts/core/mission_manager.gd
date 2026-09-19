extends Node
## Mission system. Prototype ships ONE mission: "FIRST CONNECTION".
## Objectives are sequential in the tracker but idempotent when reported.

const MISSION_ID := "first_connection"

var objectives: Array = [
        {"id": "find_computer", "title": "Find and use your computer"},
        {"id": "read_notes", "title": "Read the beginner notes (Files app)"},
        {"id": "open_terminal", "title": "Open the terminal"},
        {"id": "learn_basics", "title": "Learn basic commands (help + whoami)"},
        {"id": "inspect_network", "title": "Inspect the training network (network)"},
        {"id": "identify_target", "title": "Identify the target (scan TEST-PC-01)"},
        {"id": "connect_target", "title": "Connect to TEST-PC-01"},
        {"id": "inspect_files", "title": "Inspect remote files (ls)"},
        {"id": "find_token", "title": "Find the token (read flag.txt)"},
        {"id": "complete_lab", "title": "Complete the lab (submit <token>)"},
]
var done := {}          # id -> bool
var _sub := {}          # sub-flags e.g. learn_basics needs ran_help + ran_whoami
var mission_active: bool = false
var mission_complete: bool = false

func _ready() -> void:
        reset()
        Events.computer_opened.connect(func(): report("computer_opened"))
        Events.computer_closed.connect(func(): pass)

func reset() -> void:
        done = {}
        _sub = {}
        mission_active = false
        mission_complete = false

func start_mission() -> void:
        if mission_active or mission_complete:
                return
        mission_active = true
        Events.mission_started.emit(MISSION_ID)
        Events.notify.emit("New mission: FIRST CONNECTION — check your mission tracker.", "info")

func current_objective() -> Dictionary:
        for o in objectives:
                if not bool(done.get(o["id"], false)):
                        return o
        return {}

func is_done(id: String) -> bool:
        return bool(done.get(id, false))

func report(action: String) -> void:
        if not mission_active or mission_complete:
                return
        match action:
                "computer_opened":
                        _complete("find_computer")
                "read_notes":
                        _complete("read_notes")
                "terminal_opened":
                        _complete("open_terminal")
                "ran_help":
                        _sub["ran_help"] = true
                        _check_basics()
                "ran_whoami":
                        _sub["ran_whoami"] = true
                        _check_basics()
                "ran_network":
                        _complete("inspect_network")
                "ran_scan":
                        _complete("identify_target")
                "connected":
                        _complete("connect_target")
                "ran_ls_remote":
                        _complete("inspect_files")
                "read_flag":
                        _complete("find_token")
                "submitted":
                        _complete("complete_lab")
                        _finish()

func _check_basics() -> void:
        if bool(_sub.get("ran_help", false)) and bool(_sub.get("ran_whoami", false)):
                _complete("learn_basics")

func _complete(id: String) -> void:
        if is_done(id):
                return
        done[id] = true
        var title := ""
        for o in objectives:
                if o["id"] == id:
                        title = o["title"]
                        break
        Events.objective_done.emit(id, title)

func _finish() -> void:
        mission_complete = true
        mission_active = false
        Game.add_money(50)
        Game.add_xp("linux", 30)
        Game.add_xp("networking", 30)
        Game.set_flag("mission_first_connection_done")
        var txt := "+50 credits, +30 Linux XP, +30 Networking XP. Evidence: 0% (training environment)."
        Events.mission_completed.emit(MISSION_ID, txt)
        Events.notify.emit("MISSION COMPLETE — FIRST CONNECTION", "success")

func progress_text() -> String:
        var n := 0
        for o in objectives:
                if is_done(o["id"]):
                        n += 1
        return "%d/%d" % [n, objectives.size()]

# ---------------- save/load ----------------
func to_dict() -> Dictionary:
        return {
                "done": done.duplicate(true),
                "mission_active": mission_active,
                "mission_complete": mission_complete,
        }

func from_dict(d: Dictionary) -> void:
        done = {}
        var dd: Dictionary = d.get("done", {})
        for k in dd.keys():
                done[k] = bool(dd[k])
        mission_active = bool(d.get("mission_active", false))
        mission_complete = bool(d.get("mission_complete", false))
        _sub = {}
