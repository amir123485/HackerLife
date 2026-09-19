extends CanvasLayer
## On-screen touch controls for mobile (Android/iOS).
## Left thumb: movement joystick -> feeds the standard move_* input actions.
## Right side: drag anywhere (outside controls) to orbit the camera.
## Buttons: E = interact, RUN = sprint toggle, PAUSE (||) = pause/menu.
## Desktop is untouched: the layer stays hidden unless a mobile feature tag
## is present or the game is launched with `-- --touch` (testing).

const JOY_AREA := 340.0          # touch zone size (square, bottom-left)
const JOY_BASE := 220.0          # visible base circle
const JOY_RADIUS := 78.0         # knob travel
const KNOB := 84.0
const DEADZONE := 0.16

var _player: Node = null
var _look_finger: int = -1
var _joy_finger: int = -1
var _joy_center: Vector2 = Vector2.ZERO
var _knob: Panel
var _joy_area: Control
var _sprint_btn: Button
var _active := false

func _ready() -> void:
        layer = 30
        visible = false
        process_mode = Node.PROCESS_MODE_ALWAYS
        if not _touch_enabled():
                set_process(false)
                set_process_unhandled_input(false)
                return
        _build_ui()

func _touch_enabled() -> bool:
        if OS.get_cmdline_user_args().has("--touch"):
                return true
        return OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios")

# ------------------------------------------------------------------ UI build
func _circle_style(d: float, bg: Color) -> StyleBoxFlat:
        var sb := StyleBoxFlat.new()
        sb.bg_color = bg
        sb.set_corner_radius_all(int(d / 2.0))
        sb.border_width_bottom = 2
        sb.border_width_top = 2
        sb.border_width_left = 2
        sb.border_width_right = 2
        sb.border_color = Color(0.30, 0.95, 0.75, 0.35)
        return sb

func _build_ui() -> void:
        # --- joystick (bottom-left) ---
        _joy_area = Control.new()
        _joy_area.position = Vector2(24, 0)
        _joy_area.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
        _joy_area.offset_top = -JOY_AREA - 24.0
        _joy_area.offset_right = JOY_AREA + 24.0
        _joy_area.offset_bottom = -24.0
        _joy_area.mouse_filter = Control.MOUSE_FILTER_STOP
        _joy_area.gui_input.connect(_on_joy_input)
        add_child(_joy_area)
        var base := Panel.new()
        base.size = Vector2(JOY_BASE, JOY_BASE)
        base.position = (Vector2(JOY_AREA, JOY_AREA) - Vector2(JOY_BASE, JOY_BASE)) / 2.0
        base.mouse_filter = Control.MOUSE_FILTER_IGNORE
        base.add_theme_stylebox_override("panel", _circle_style(JOY_BASE, Color(0.05, 0.09, 0.12, 0.45)))
        _joy_area.add_child(base)
        _knob = Panel.new()
        _knob.size = Vector2(KNOB, KNOB)
        _knob.position = _joy_knob_home()
        _knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _knob.add_theme_stylebox_override("panel", _circle_style(KNOB, Color(0.10, 0.55, 0.48, 0.60)))
        _joy_area.add_child(_knob)
        # --- action buttons (bottom-right cluster) ---
        _make_button(Vector2(-200, -196), 110.0, "E", Color(0.10, 0.55, 0.48, 0.60), _on_e_down, _on_e_up)
        _sprint_btn = _make_button(Vector2(-330, -100), 96.0, "RUN", Color(0.35, 0.30, 0.10, 0.60), _on_run_toggled, _on_run_toggled)
        _sprint_btn.toggle_mode = true
        _make_button(Vector2(-96, -110), 96.0, "||", Color(0.25, 0.25, 0.30, 0.60), _on_pause_pressed, _on_pause_pressed)
        # drag-to-look hint fades after a while (built last, sits on top)
        _build_look_zone_hint()

func _joy_knob_home() -> Vector2:
        return (Vector2(JOY_AREA, JOY_AREA) - Vector2(KNOB, KNOB)) / 2.0

func _make_button(offset: Vector2, d: float, label: String, bg: Color, on_down: Callable, on_up: Callable) -> Button:
        var b := Button.new()
        b.text = label
        b.flat = false
        b.focus_mode = Control.FOCUS_NONE
        b.add_theme_font_size_override("font_size", 34 if label != "RUN" else 24)
        b.add_theme_color_override("font_color", Color(0.85, 1.0, 0.95))
        b.add_theme_color_override("font_pressed_color", Color(1, 1, 1))
        b.add_theme_color_override("font_hover_color", Color(0.85, 1.0, 0.95))
        b.add_theme_stylebox_override("normal", _circle_style(d, bg))
        b.add_theme_stylebox_override("hover", _circle_style(d, bg.lightened(0.05)))
        b.add_theme_stylebox_override("pressed", _circle_style(d, Color(0.30, 0.95, 0.75, 0.65)))
        b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
        b.anchor_left = 1.0
        b.anchor_top = 1.0
        b.anchor_right = 1.0
        b.anchor_bottom = 1.0
        b.offset_left = offset.x - d
        b.offset_top = offset.y - d
        b.offset_right = offset.x
        b.offset_bottom = offset.y
        b.mouse_filter = Control.MOUSE_FILTER_STOP
        b.button_down.connect(on_down)
        b.button_up.connect(on_up)
        add_child(b)
        return b

var _hint: Label

func _build_look_zone_hint() -> void:
        _hint = Label.new()
        _hint.text = "drag right side to look around"
        _hint.add_theme_font_size_override("font_size", 15)
        _hint.add_theme_color_override("font_color", Color(0.7, 0.9, 0.85, 0.55))
        _hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
        _hint.offset_top = -70
        _hint.offset_bottom = -40
        _hint.grow_horizontal = Control.GROW_DIRECTION_BOTH
        _hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
        add_child(_hint)
        var tw := create_tween()
        tw.tween_interval(6.0)
        tw.tween_property(_hint, "modulate:a", 0.0, 2.0)

# ------------------------------------------------------------- visibility
func _process(_delta: float) -> void:
        var show := false
        var main := get_tree().current_scene
        if main != null and "state" in main and int(main.state) == 1 \
                        and not get_tree().paused and "computer_open" in main and not bool(main.computer_open):
                var world = main.get("world")
                if world != null and world.has_method("get_player"):
                        var p = world.get_player()
                        if p != null and is_instance_valid(p) and not p.frozen:
                                show = true
                                _player = p
        if show != _active:
                _active = show
                visible = show
                if not show:
                        _release_all()

# ---------------------------------------------------------------- joystick
func _on_joy_input(event: InputEvent) -> void:
        if event is InputEventScreenTouch:
                if event.pressed and _joy_finger == -1:
                        _joy_finger = event.index
                        _joy_center = _joy_area.get_global_rect().get_center()
                        _apply_joy(event.position)
                        _joy_area.accept_event()
                elif not event.pressed and event.index == _joy_finger:
                        _joy_finger = -1
                        _apply_joy(_joy_center)
                        _joy_area.accept_event()
        elif event is InputEventScreenDrag and event.index == _joy_finger:
                _apply_joy(event.position)
                _joy_area.accept_event()

func _apply_joy(touch_pos: Vector2) -> void:
        var v := touch_pos - _joy_center
        v.y = -v.y  # screen y down -> input y up
        var mag := v.length() / JOY_RADIUS
        if mag > 1.0:
                v = v.normalized()
                mag = 1.0
        if mag < DEADZONE:
                _release_moves()
                _knob.position = _joy_knob_home()
                return
        var nx := v.normalized().x if v.length() > 0.0 else 0.0
        var ny := v.normalized().y if v.length() > 0.0 else 0.0
        var scaled := (mag - DEADZONE) / (1.0 - DEADZONE)
        _set_move("move_right", maxf(0.0, nx) * scaled)
        _set_move("move_left", maxf(0.0, -nx) * scaled)
        _set_move("move_back", maxf(0.0, ny) * scaled)
        _set_move("move_forward", maxf(0.0, -ny) * scaled)
        var clamp_v := v.limit_length(JOY_RADIUS)
        _knob.position = _joy_knob_home() + Vector2(clamp_v.x, -clamp_v.y)

func _set_move(action: String, strength: float) -> void:
        if strength > 0.001:
                Input.action_press(action, strength)
        else:
                Input.action_release(action)

func _release_moves() -> void:
        for a in ["move_left", "move_right", "move_forward", "move_back"]:
                Input.action_release(a)
        _knob.position = _joy_knob_home()

# ------------------------------------------------------------------- look
func _unhandled_input(event: InputEvent) -> void:
        if not _active:
                return
        if event is InputEventScreenTouch:
                if event.pressed and _look_finger == -1:
                        _look_finger = event.index
                elif not event.pressed and event.index == _look_finger:
                        _look_finger = -1
        elif event is InputEventScreenDrag and event.index == _look_finger:
                if _player != null and is_instance_valid(_player):
                        _player.rotate_camera(event.relative.x, event.relative.y)
                get_viewport().set_input_as_handled()

# ---------------------------------------------------------------- buttons
func _parse_action(action: String, pressed: bool) -> void:
        var ev := InputEventAction.new()
        ev.action = action
        ev.pressed = pressed
        Input.parse_input_event(ev)

func _on_e_down() -> void:
        _parse_action("interact", true)

func _on_e_up() -> void:
        _parse_action("interact", false)

func _on_run_toggled() -> void:
        if _sprint_btn != null and _sprint_btn.button_pressed:
                Input.action_press("sprint")
        else:
                Input.action_release("sprint")

func _on_pause_pressed() -> void:
        _parse_action("pause", true)

# ------------------------------------------------------------- cleanup
func _release_all() -> void:
        _joy_finger = -1
        _look_finger = -1
        _release_moves()
        Input.action_release("sprint")
        if _sprint_btn != null:
                _sprint_btn.set_pressed_no_signal(false)
