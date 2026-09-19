extends Node
## HackerLife main orchestrator: menu <-> game flow, world lifecycle,
## interactions, pause, computer, capture mode.

enum State { MENU, PLAYING }

var state: int = State.MENU
var world: Node3D
var hud: CanvasLayer
var computer_ui: CanvasLayer
var main_menu: CanvasLayer
var pause_menu: CanvasLayer
var fade_rect: ColorRect
var computer_open: bool = false

func _ready() -> void:
        process_mode = Node.PROCESS_MODE_ALWAYS
        _build_fade()
        main_menu = load("res://scripts/ui/main_menu.gd").new()
        add_child(main_menu)
        main_menu.start_game.connect(_start_new_game)
        main_menu.continue_game.connect(_continue_game)
        pause_menu = load("res://scripts/ui/pause_menu.gd").new()
        add_child(pause_menu)
        pause_menu.resumed.connect(_unpause)
        pause_menu.saved.connect(func():
                if SaveIO.save_game():
                        Events.notify.emit("Game saved.", "success")
                else:
                        Events.notify.emit("Save failed: " + SaveIO.last_error, "fail"))
        pause_menu.main_menu_requested.connect(_back_to_menu)
        Events.mission_completed.connect(func(_id, _txt):
                SaveIO.save_game())  # auto-save on mission completion
        # capture mode (used by automated gameplay capture)
        if OS.get_cmdline_user_args().has("--capture"):
                call_deferred("_start_capture")

func _build_fade() -> void:
        fade_rect = ColorRect.new()
        fade_rect.color = Color(0, 0, 0, 0)
        fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
        fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
        var layer := CanvasLayer.new()
        layer.layer = 40
        layer.add_child(fade_rect)
        add_child(layer)

func _fade(to: float, dur: float) -> void:
        var tw := create_tween()
        tw.tween_property(fade_rect, "color:a", to, dur)
        await tw.finished

# ---------------------------------------------------------------- game flow
func _start_new_game() -> void:
        Game.reset()
        TimeSys.reset()
        Missions.reset()
        Sim.reset()
        _begin_play(null)

func _continue_game() -> void:
        if not SaveIO.load_game():
                Events.notify.emit("Load failed: " + SaveIO.last_error, "fail")
                return
        _begin_play(null)

func _begin_play(save_state) -> void:
        state = State.PLAYING
        main_menu.visible = false
        # world
        world = load("res://scripts/world/world_builder.gd").new()
        add_child(world)
        # HUD
        hud = load("res://scripts/ui/hud.gd").new()
        add_child(hud)
        # computer UI
        computer_ui = load("res://scripts/computer/computer_ui.gd").new()
        add_child(computer_ui)
        # player wiring
        var player = world.get_player()
        player.interacted.connect(_on_interact)
        player.prompt_changed.connect(func(t): hud.set_prompt(t))
        if save_state != null and not (save_state as Dictionary).is_empty():
                world.set_load_state(save_state)
        # start
        player.set_mouse_captured(true)
        TimeSys.start()
        Sfx.start_music()
        Sfx.start_ambient()
        _fade(0.0, 0.8)
        if not Missions.mission_complete and not Game.flag("welcome_shown"):
                Game.set_flag("welcome_shown")
                Events.notify.emit("First day in the new room. Find your computer. [E] to interact.", "info")

func _back_to_menu() -> void:
        get_tree().paused = false
        pause_menu.visible = false
        state = State.MENU
        if computer_open:
                computer_open = false
        computer_ui = null
        hud = null
        for child in get_children():
                if child != main_menu and child != pause_menu and child != fade_rect.get_parent():
                        child.queue_free()
        main_menu.visible = true
        Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
        TimeSys.stop()
        Sfx.stop_ambient()
        Sfx.start_music()

func _on_interact(action: String) -> void:
        if state != State.PLAYING or computer_open:
                return
        match action:
                "computer":
                        _open_computer()
                "bed":
                        _do_sleep()
                "fridge":
                        _do_fridge()
                "door":
                        _do_door()
                "books":
                        _do_books()

# ---------------------------------------------------------------- interactions
func _open_computer() -> void:
        computer_open = true
        var player = world.get_player()
        player.freeze()
        player.set_mouse_captured(false)
        Sfx.play("door")
        computer_ui.open()

func _close_computer() -> void:
        computer_open = false
        var player = world.get_player()
        player.unfreeze()
        player.set_mouse_captured(true)

func _do_sleep() -> void:
        var player = world.get_player()
        player.freeze()
        await _fade(1.0, 0.7)
        TimeSys.sleep_until_morning()
        Events.notify.emit("You slept until morning. Energy restored.", "success")
        await get_tree().create_timer(0.3).timeout
        await _fade(0.0, 0.7)
        player.unfreeze()

func _do_fridge() -> void:
        var since := TimeSys.total_minutes() - TimeSys.last_meal_minute
        if since >= 240:
                TimeSys.mark_meal()
                Game.add_item("snack")
                Events.notify.emit("Grabbed a snack from the fridge (mom restocks every few hours).", "info")
                Sfx.play("door")
        else:
                Events.notify.emit("The fridge is empty for now. Give it a few hours.", "warn")

func _do_door() -> void:
        if TimeSys.is_school_day() and not TimeSys.school_attended_today:
                var player = world.get_player()
                player.freeze()
                await _fade(1.0, 0.7)
                TimeSys.attend_school()
                Events.notify.emit("You attended school. (+6 school performance)", "success")
                await get_tree().create_timer(0.3).timeout
                await _fade(0.0, 0.7)
                player.unfreeze()
        else:
                Events.notify.emit("No school right now. The city beyond this block comes in a future update.", "warn")

func _do_books() -> void:
        if TimeSys.day != int(Game.session.get("book_day", -1)):
                Game.session["book_day"] = TimeSys.day
                Game.add_xp("linux", 3)
                Events.notify.emit("You skim a networking book. (+3 Linux XP)", "info")
        else:
                Events.notify.emit("You've studied enough for today.", "warn")

# ---------------------------------------------------------------- pause
func _unhandled_input(event: InputEvent) -> void:
        if state != State.PLAYING:
                return
        if event.is_action_pressed("pause"):
                if computer_open:
                        _close_computer()
                        computer_ui.close()
                elif not get_tree().paused:
                        _pause()
                else:
                        _unpause()

func _pause() -> void:
        get_tree().paused = true
        pause_menu.visible = true
        Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
        Sfx.play("ui_click")

func _unpause() -> void:
        get_tree().paused = false
        pause_menu.visible = false
        if not computer_open and world != null:
                var player = world.get_player()
                if player != null:
                        player.set_mouse_captured(true)

# ---------------------------------------------------------------- computer events
func _process(_delta: float) -> void:
        # react to computer close event
        if computer_open and computer_ui != null and not computer_ui.visible:
                _close_computer()

# ---------------------------------------------------------------- capture
func _start_capture() -> void:
        _start_new_game()
        var director = load("res://scripts/capture/capture_director.gd").new()
        add_child(director)
