extends Node
## In-game clock. 1 real second = 1 game minute (a day = 24 min).
## Drives day/night light cycle, schedules, life-sim stat drains.

signal minute_tick
signal slept(wake_minute: int)

const MINUTES_PER_DAY := 1440
const REAL_SECONDS_PER_GAME_MINUTE := 1.0
const SCHOOL_START := 8 * 60
const SCHOOL_END := 14 * 60

var day: int = 1                 # day counter, day 1 = Monday
var minute_of_day: int = 7 * 60  # wake at 07:00
var running: bool = false
var school_attended_today: bool = false
var last_meal_minute: int = -999

var _acc: float = 0.0

func _ready() -> void:
	reset()

func reset() -> void:
	day = 1
	minute_of_day = 7 * 60
	running = false
	school_attended_today = false
	last_meal_minute = -999
	_acc = 0.0

func start() -> void:
	running = true

func stop() -> void:
	running = false

func weekday() -> String:
	var names := ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
	return names[(day - 1) % 7]

func is_school_day() -> bool:
	return (day - 1) % 7 < 5

func is_school_time() -> bool:
	return is_school_day() and minute_of_day >= SCHOOL_START and minute_of_day < SCHOOL_END

func clock_text() -> String:
	var h := minute_of_day / 60
	var m := minute_of_day % 60
	return "%02d:%02d" % [h, m]

func _process(delta: float) -> void:
	if not running:
		return
	_acc += delta * (1.0 / REAL_SECONDS_PER_GAME_MINUTE)
	while _acc >= 60.0:
		_acc -= 60.0
		advance_minute()

func advance_minute() -> void:
	minute_of_day += 1
	if minute_of_day >= MINUTES_PER_DAY:
		minute_of_day = 0
		day += 1
		school_attended_today = false
	# life-sim drains per game minute
	var hunger_rate := 100.0 / 1440.0 * 1.4          # full day ~ 1.4x
	var energy_rate := 100.0 / 1440.0 * 0.9          # awake drain
	if Game.hunger >= 85.0:
		energy_rate *= 2.0                           # starving drains you faster
	Game.set_hunger(Game.hunger + hunger_rate)
	Game.set_energy(Game.energy - energy_rate)
	Events.clock_changed.emit(minute_of_day, day)
	minute_tick.emit()

func skip_to(target_minute: int, next_day: bool = false) -> void:
	## Jump the clock (sleep / school), applying life effects in steps.
	if next_day:
		day += 1
		school_attended_today = false
	minute_of_day = target_minute
	Events.clock_changed.emit(minute_of_day, day)
	minute_tick.emit()
	slept.emit(target_minute)

func sleep_until_morning() -> void:
	Game.set_energy(100.0)
	Game.set_hunger(Game.hunger + 25.0)
	var wake := 7 * 60
	if minute_of_day < wake:
		skip_to(wake)
	else:
		skip_to(wake, true)

func attend_school() -> void:
	## Skip to end of school day; pays off in school performance.
	if school_attended_today or not is_school_day():
		return
	school_attended_today = true
	Game.set_energy(Game.energy - 18.0)
	Game.set_hunger(Game.hunger + 20.0)
	Game.add_school_perf(6.0)
	skip_to(SCHOOL_END)

func mark_meal() -> void:
	last_meal_minute = total_minutes()

func total_minutes() -> int:
	return (day - 1) * MINUTES_PER_DAY + minute_of_day

# ---------------- save/load ----------------
func to_dict() -> Dictionary:
	return {
		"day": day,
		"minute_of_day": minute_of_day,
		"school_attended_today": school_attended_today,
		"last_meal_minute": last_meal_minute,
	}

func from_dict(d: Dictionary) -> void:
	day = int(d.get("day", 1))
	minute_of_day = int(d.get("minute_of_day", 7 * 60))
	school_attended_today = bool(d.get("school_attended_today", false))
	last_meal_minute = int(d.get("last_meal_minute", -999))
	_acc = 0.0
	Events.clock_changed.emit(minute_of_day, day)
