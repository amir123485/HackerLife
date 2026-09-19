extends Node
## Versioned JSON save/load. Saves live in user://saves/save_1.json
## Version field allows future migrations.

const SAVE_VERSION := 1
const SAVE_DIR := "user://saves"
const SAVE_PATH := "user://saves/save_1.json"
const SETTINGS_PATH := "user://settings.cfg"

var last_error: String = ""

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func save_game() -> bool:
	last_error = ""
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	var data := {
		"save_version": SAVE_VERSION,
		"game": Game.to_dict(),
		"time": TimeSys.to_dict(),
		"missions": Missions.to_dict(),
		"sim": Sim.to_dict(),
		"player_transform": {},
	}
	var world = get_tree().get_first_node_in_group("world")
	if world != null and world.has_method("get_save_state"):
		data["player_transform"] = world.get_save_state()
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		last_error = "Cannot write save file: %s" % SAVE_PATH
		return false
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
	return true

func load_game() -> bool:
	last_error = ""
	if not has_save():
		last_error = "No save file found."
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		last_error = "Cannot open save file."
		return false
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		last_error = "Corrupted save file."
		return false
	var data: Dictionary = parsed
	var v := int(data.get("save_version", 0))
	if v > SAVE_VERSION:
		last_error = "Save from a newer version."
		return false
	# migration hook (future): if v < SAVE_VERSION: migrate(data)
	Game.from_dict(data.get("game", {}))
	TimeSys.from_dict(data.get("time", {}))
	Missions.from_dict(data.get("missions", {}))
	Sim.from_dict(data.get("sim", {}))
	return true

func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)

# ---------------- settings (ConfigFile) ----------------
func load_settings() -> Dictionary:
	var cfg := ConfigFile.new()
	var d := {
		"fullscreen": false,
		"vsync": true,
		"master_volume": 0.8,
		"music_volume": 0.55,
		"sfx_volume": 0.9,
		"mouse_sensitivity": 1.0,
		"shadows": true,
		"glow": true,
		"msaa": 1,
		"quality": 1,  # 0 low 1 med 2 high
	}
	if cfg.load(SETTINGS_PATH) == OK:
		for k in d.keys():
			d[k] = cfg.get_value("settings", k, d[k])
	return d

func save_settings(d: Dictionary) -> void:
	var cfg := ConfigFile.new()
	for k in d.keys():
		cfg.set_value("settings", k, d[k])
	cfg.save(SETTINGS_PATH)
