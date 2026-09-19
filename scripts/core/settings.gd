extends Node
## Graphics/input settings store. Applies to DisplayServer & RenderingServer.

signal settings_changed

var values: Dictionary = {}

func _ready() -> void:
	values = SaveIO.load_settings()
	apply_all()

func set_value(k: String, v) -> void:
	values[k] = v
	SaveIO.save_settings(values)
	settings_changed.emit()

func apply_all() -> void:
	set_fullscreen(bool(values.get("fullscreen", false)))
	set_vsync(bool(values.get("vsync", true)))
	set_shadows(bool(values.get("shadows", true)))
	set_glow(bool(values.get("glow", true)))
	set_msaa(int(values.get("msaa", 1)))
	settings_changed.emit()

func set_fullscreen(on: bool) -> void:
	values["fullscreen"] = on
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if on else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)

func set_vsync(on: bool) -> void:
	values["vsync"] = on
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if on else DisplayServer.VSYNC_DISABLED)

func set_shadows(on: bool) -> void:
	values["shadows"] = on
	var world = get_tree().get_first_node_in_group("world")
	if world != null and world.has_method("apply_shadows"):
		world.apply_shadows(on)

func set_glow(on: bool) -> void:
	values["glow"] = on
	var world = get_tree().get_first_node_in_group("world")
	if world != null and world.has_method("apply_glow"):
		world.apply_glow(on)

func set_msaa(level: int) -> void:
	values["msaa"] = clampi(level, 0, 2)
	var vp := get_viewport()
	if vp != null:
		match values["msaa"]:
			0: vp.msaa_3d = Viewport.MSAA_DISABLED
			1: vp.msaa_3d = Viewport.MSAA_2X
			2: vp.msaa_3d = Viewport.MSAA_4X
