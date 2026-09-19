extends Node
## Audio manager: music loop + one-shot SFX, volume control.

const SOUNDS := {
	"ui_click": "res://assets/audio/ui_click.wav",
	"key": "res://assets/audio/key.wav",
	"footstep": "res://assets/audio/footstep.wav",
	"door": "res://assets/audio/door.wav",
	"notify": "res://assets/audio/notify.wav",
	"success": "res://assets/audio/success.wav",
	"fail": "res://assets/audio/fail.wav",
	"typing": "res://assets/audio/typing.wav",
}

var _streams := {}
var _music: AudioStreamPlayer
var _ambient: AudioStreamPlayer
var _pool: Array = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for k in SOUNDS.keys():
		var s = load(SOUNDS[k])
		if s != null:
			_streams[k] = s
	_music = AudioStreamPlayer.new()
	_music.bus = "Master"
	add_child(_music)
	_ambient = AudioStreamPlayer.new()
	_ambient.bus = "Master"
	add_child(_ambient)
	for i in range(6):
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_pool.append(p)
	set_volumes(0.8, 0.55, 0.9)

func set_volumes(master_v: float, music_v: float, sfx_v: float) -> void:
	var idx := AudioServer.get_bus_index("Master")
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(clampf(master_v, 0.0001, 1.0)))
		AudioServer.set_bus_mute(idx, master_v <= 0.001)
	if _music != null:
		_music.volume_db = linear_to_db(clampf(music_v, 0.0001, 1.0)) - 6.0
	if _ambient != null:
		_ambient.volume_db = linear_to_db(clampf(sfx_v, 0.0001, 1.0)) - 10.0
	for p in _pool:
		p.volume_db = linear_to_db(clampf(sfx_v, 0.0001, 1.0))

func play(name: String) -> void:
	if not _streams.has(name):
		return
	for p in _pool:
		if not p.playing:
			p.stream = _streams[name]
			p.play()
			return
	_pool[0].stream = _streams[name]
	_pool[0].play()

func start_music() -> void:
	if _music.playing:
		return
	var m = load("res://assets/audio/music_loop.wav")
	if m != null and m is AudioStreamWAV:
		m.loop_mode = AudioStreamWAV.LOOP_FORWARD
		m.loop_begin = 0
		m.loop_end = m.data.size() / 4  # 16-bit stereo: 4 bytes per frame
		_music.stream = m
		_music.play()

func stop_music() -> void:
	_music.stop()

func start_ambient() -> void:
	if _ambient.playing:
		return
	var a = load("res://assets/audio/hum_loop.wav")
	if a != null and a is AudioStreamWAV:
		a.loop_mode = AudioStreamWAV.LOOP_FORWARD
		a.loop_begin = 0
		a.loop_end = a.data.size() / 2  # 16-bit mono
		_ambient.stream = a
		_ambient.play()

func stop_ambient() -> void:
	_ambient.stop()
