extends Node
## Scripted gameplay capture: plays through the vertical slice and records
## frames to /home/z/my-project/capture_frames (used to build the trailer MP4).

var frames_dir := "/home/z/my-project/capture_frames"
var capturing := false
var frame_idx := 0

func _ready() -> void:
        DirAccess.make_dir_recursive_absolute(frames_dir)
        # clean stale frames
        for f in DirAccess.get_files_at(frames_dir):
                DirAccess.remove_absolute(frames_dir + "/" + f)
        _run()

func _run() -> void:
        await get_tree().create_timer(1.6).timeout
        capturing = true
        _capture_loop()
        var main := get_parent()
        var world = main.world
        var player = world.get_player()
        var computer = main.computer_ui

        # 1) look around the room
        player.scripted_look(0.9, -0.15)
        await get_tree().create_timer(1.4).timeout
        player.scripted_look(-0.7, -0.05)
        await get_tree().create_timer(1.4).timeout
        player.scripted_look(0.0, -0.1)
        await get_tree().create_timer(1.0).timeout

        # 2) walk to the desk, sit at the computer
        await player.scripted_move_to(Vector3(-0.6, 0, -0.55), 6.0)
        player.scripted_look(0.0, -0.12)
        await get_tree().create_timer(0.6).timeout
        player.interacted.emit("computer")
        await get_tree().create_timer(1.2).timeout
        await _shot("01_desktop")

        # 3) files app: read the beginner notes
        computer._open_app("files")
        await get_tree().create_timer(0.9).timeout
        var files_app = computer.app_nodes.get("files")
        if files_app != null:
                files_app._open_file("notes.txt")
        await get_tree().create_timer(1.6).timeout
        await _shot("02_notes")
        computer._close_app()
        await get_tree().create_timer(0.5).timeout

        # 4) messages: mission briefing
        computer._open_app("messages")
        await get_tree().create_timer(0.9).timeout
        var msgs = computer.app_nodes.get("messages")
        if msgs != null:
                msgs._open_msg(1)
        await get_tree().create_timer(1.6).timeout
        await _shot("03_mission_brief")
        computer._close_app()
        await get_tree().create_timer(0.5).timeout

        # 5) terminal: the whole first mission
        computer._open_app("terminal")
        await get_tree().create_timer(0.8).timeout
        var term = computer.app_nodes.get("terminal")
        if term == null:
                _finish_capture()
                return
        await _type(term, "help", 1.2)
        await _type(term, "whoami", 0.8)
        await _type(term, "network", 1.4)
        await _type(term, "scan TEST-PC-01", 1.6)
        await _shot("04_scan")
        await _type(term, "connect TEST-PC-01", 1.0)
        await _type(term, "student", 0.7)
        await _type(term, "learn3r", 1.2)
        await _shot("05_connected")
        await _type(term, "ls", 1.0)
        await _type(term, "read flag.txt", 1.4)
        await _type(term, "submit HL{f1rst_c0nnect10n_ok}", 1.6)
        await _shot("06_mission_complete")
        await get_tree().create_timer(2.2).timeout
        main.hud.complete_banner.visible = false

        # 6) cyber lab: take a lesson
        computer._open_app("lab")
        await get_tree().create_timer(0.9).timeout
        var lab = computer.app_nodes.get("lab")
        if lab != null:
                lab._open_lesson(0)
                await get_tree().create_timer(1.0).timeout
                lab._answer(0, 1)
        await get_tree().create_timer(1.2).timeout
        await _shot("07_lab")
        computer._close_app()
        await get_tree().create_timer(0.6).timeout
        computer.close()
        await get_tree().create_timer(0.8).timeout

        # 7) walk to the window, look at the city
        await player.scripted_move_to(Vector3(0.3, 0, 1.1), 6.0)
        player.scripted_look(3.1416, -0.22)
        await get_tree().create_timer(2.2).timeout
        await _shot("08_window")
        player.scripted_look(2.2, -0.1)
        await get_tree().create_timer(1.6).timeout

        # 8) bed: end the day
        await player.scripted_move_to(Vector3(1.2, 0, 0.4), 6.0)
        await get_tree().create_timer(0.5).timeout
        main._do_sleep()
        await get_tree().create_timer(3.0).timeout
        await _shot("09_after_sleep")
        await get_tree().create_timer(1.0).timeout
        _finish_capture()

func _type(term, line: String, wait: float) -> void:
        term._on_submit(line)
        await get_tree().create_timer(wait).timeout

func _capture_loop() -> void:
        while capturing:
                await RenderingServer.frame_post_draw
                var img := get_viewport().get_texture().get_image()
                if img != null and not img.is_empty():
                        img.save_png("%s/f_%06d.png" % [frames_dir, frame_idx])
                        frame_idx += 1
                await get_tree().create_timer(0.12).timeout

func _shot(name_: String) -> void:
        await RenderingServer.frame_post_draw
        var img := get_viewport().get_texture().get_image()
        if img != null:
                img.save_png("%s/%s.png" % [frames_dir, name_])

func _finish_capture() -> void:
        capturing = false
        var f := FileAccess.open(frames_dir + "/capture_done.txt", FileAccess.WRITE)
        if f != null:
                f.store_string(str(frame_idx))
                f.close()
        print("CAPTURE DONE: ", frame_idx, " frames")
        await get_tree().create_timer(0.5).timeout
        get_tree().quit(0)
