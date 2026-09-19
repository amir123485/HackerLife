extends Node
## Headless test runner. Run with:
##   godot --headless --path . res://tests/test_main.tscn
## Exits 0 on success, 1 on failure.

var failures: Array = []

func _ready() -> void:
        await get_tree().process_frame
        _run_all()

func _check(cond: bool, name_: String) -> void:
        if cond:
                print("  [PASS] ", name_)
        else:
                failures.append(name_)
                printerr("  [FAIL] ", name_)

func _run_all() -> void:
        print("=== HackerLife automated tests ===")
        _test_game_state()
        _test_economy()
        _test_inventory()
        _test_skills()
        _test_time()
        _test_sim_network()
        _test_terminal_and_mission()
        _test_save_load()
        print("=== done: %d failures ===" % failures.size())
        if failures.size() > 0:
                for f in failures:
                        printerr("FAILED: ", f)
                get_tree().quit(1)
        else:
                print("ALL TESTS PASSED")
                get_tree().quit(0)

func _test_game_state() -> void:
        print("- game state")
        Game.reset()
        _check(Game.money == 12, "starting money is 12")
        Game.add_money(10)
        _check(Game.money == 22, "add_money works")
        _check(Game.can_afford(20), "can_afford true")
        _check(not Game.can_afford(10000), "can_afford false")
        _check(Game.spend(5), "spend succeeds")
        _check(Game.money == 17, "money after spend")
        _check(not Game.spend(9999), "overspend fails")
        _check(Game.energy == 100.0, "energy starts full")
        Game.set_energy(150.0)
        _check(Game.energy == 100.0, "energy clamped high")
        Game.set_energy(-5)
        _check(Game.energy == 0.0, "energy clamped low")
        Game.add_evidence(150)
        _check(Game.evidence == 100, "evidence clamped")
        Game.set_flag("test_flag")
        _check(Game.flag("test_flag"), "flags work")

func _test_economy() -> void:
        print("- economy")
        Game.reset()
        var start: int = Game.money
        Game.add_money(100)
        Game.spend(30)
        _check(Game.money == start + 70, "economy add/spend")

func _test_inventory() -> void:
        print("- inventory")
        Game.reset()
        Game.add_item("test_potion", 2)
        _check(Game.has_item("test_potion", 2), "has 2 potions")
        _check(Game.use_item("test_potion"), "use potion")
        _check(Game.has_item("test_potion", 1) and not Game.has_item("test_potion", 2), "potion consumed")
        _check(not Game.use_item("does_not_exist"), "cannot use missing item")

func _test_skills() -> void:
        print("- skills")
        Game.reset()
        Game.add_xp("linux", 40)
        _check(Game.skill_level("linux") == 0, "level 0 below threshold")
        Game.add_xp("linux", 20)
        _check(Game.skill_level("linux") == 1, "level 1 at 50xp")
        Game.add_xp("networking", 150)
        _check(Game.skill_level("networking") == 2, "networking level 2 at 150xp")

func _test_time() -> void:
        print("- time system")
        Game.reset()
        TimeSys.reset()
        var h0: float = Game.hunger
        for i in range(60):
                TimeSys.advance_minute()
        _check(TimeSys.minute_of_day == 8 * 60, "clock advanced one hour")
        _check(Game.hunger > h0, "hunger rises over time")
        _check(Game.energy < 100.0, "energy drains over time")
        TimeSys.reset()
        _check(TimeSys.minute_of_day == 7 * 60, "reset wakes at 07:00")
        _check(TimeSys.is_school_day(), "day 1 is a school day")
        TimeSys.school_attended_today = false
        TimeSys.attend_school()
        _check(TimeSys.school_attended_today, "attend_school marks attendance")
        _check(TimeSys.minute_of_day == 14 * 60, "school ends at 14:00")
        TimeSys.sleep_until_morning()
        _check(TimeSys.minute_of_day == 7 * 60, "sleep wakes at 07:00")
        _check(Game.energy == 100.0, "sleep restores energy")

func _test_sim_network() -> void:
        print("- simulated network (fictional)")
        Sim.reset()
        _check(Sim.host_exists("test-pc-01"), "host lookup case-insensitive")
        _check(not Sim.host_exists("real-government.gov"), "no real hosts exist")
        var scan := Sim.scan_host("TEST-PC-01")
        _check(bool(scan["ok"]), "scan succeeds")
        _check(scan["ports"].size() == 2, "scan finds 2 services")
        var bad := Sim.scan_host("nope")
        _check(not bool(bad["ok"]), "unknown host fails scan")
        var ok := Sim.try_login("TEST-PC-01", "student", "learn3r")
        _check(bool(ok["ok"]), "lab login works")
        var bad_login := Sim.try_login("TEST-PC-01", "student", "wrong")
        _check(not bool(bad_login["ok"]), "wrong password rejected")
        _check(Sim.is_locked("TEST-WEB-01"), "locked lab stays locked")
        var files := Sim.remote_files("TEST-PC-01")
        _check(files.has("flag.txt"), "flag.txt exists on target")
        var flag := Sim.read_remote_file("TEST-PC-01", "flag.txt")
        _check(bool(flag["ok"]) and str(flag["content"]).contains("HL{"), "flag readable")
        var local := Sim.local_files()
        _check(local.has("notes.txt"), "local notes exist")
        _check(str(local["notes.txt"]).contains("student"), "notes contain lab creds")

func _test_terminal_and_mission() -> void:
        print("- terminal session + mission FIRST CONNECTION")
        Game.reset()
        TimeSys.reset()
        Missions.reset()
        Sim.reset()
        Missions.start_mission()
        _check(Missions.mission_active, "mission activates")
        var term = load("res://scripts/computer/terminal_app.gd").new()
        add_child(term)
        term._on_submit("help")
        _check(not Missions.is_done("learn_basics"), "help alone incomplete")
        term._on_submit("whoami")
        _check(Missions.is_done("learn_basics"), "help+whoami completes basics")
        term._on_submit("network")
        _check(Missions.is_done("inspect_network"), "network objective")
        term._on_submit("scan TEST-PC-01")
        _check(Missions.is_done("identify_target"), "scan objective")
        term._on_submit("connect TEST-PC-01")
        _check(term.mode == term.Mode.AUTH_USER, "auth prompt after connect")
        term._on_submit("student")
        term._on_submit("learn3r")
        _check(term.mode == term.Mode.CONNECTED, "login establishes session")
        _check(Missions.is_done("connect_target"), "connect objective")
        term._on_submit("ls")
        _check(Missions.is_done("inspect_files"), "ls objective")
        term._on_submit("read flag.txt")
        _check(Missions.is_done("find_token"), "token found")
        var money_before: int = Game.money
        term._on_submit("submit " + Sim.lab_token)
        _check(Missions.mission_complete, "mission completes")
        _check(Game.money == money_before + 50, "mission reward paid")
        _check(Game.skill_level("networking") >= 1, "networking leveled up")
        # wrong token rejected
        Missions.reset()
        Missions.start_mission()
        var t2 = load("res://scripts/computer/terminal_app.gd").new()
        add_child(t2)
        t2._on_submit("connect TEST-PC-01")
        t2._on_submit("student")
        t2._on_submit("learn3r")
        t2._on_submit("submit HL{wrong_token}")
        _check(not Missions.mission_complete, "invalid token rejected")
        term.queue_free()
        t2.queue_free()

func _test_save_load() -> void:
        print("- save/load roundtrip")
        Game.reset()
        TimeSys.reset()
        Missions.reset()
        Sim.reset()
        Game.add_money(77)
        Game.add_xp("linux", 99)
        Game.add_item("snack", 5)
        Game.set_flag("some_flag")
        TimeSys.day = 3
        TimeSys.minute_of_day = 15 * 60
        Missions.start_mission()
        _check(SaveIO.save_game(), "save succeeds")
        # mutate state then load back
        Game.reset()
        _check(Game.money != 89, "state reset before load")
        _check(SaveIO.load_game(), "load succeeds")
        _check(Game.money == 89, "money restored (12+77)")
        _check(Game.xp["linux"] == 99, "xp restored")
        _check(Game.has_item("snack", 5), "inventory restored")
        _check(Game.flag("some_flag"), "flags restored")
        _check(TimeSys.day == 3, "day restored")
        _check(Missions.mission_active, "mission state restored")
        SaveIO.delete_save()
