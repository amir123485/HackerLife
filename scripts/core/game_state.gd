extends Node
## Core game state: identity, needs, economy, skills, inventory, consequences.
## All systems read/write here; UI listens to Events signals.

const START_MONEY := 12
const SKILL_LEVELS := [0, 50, 150, 320, 600]  # cumulative xp thresholds; index = level

var player_name: String = "Ari"
var age: int = 16
var money: int = START_MONEY
var energy: float = 100.0
var hunger: float = 20.0
var school_perf: float = 60.0
var reputation: int = 0          # -100 street rep .. +100 pro rep (future)
var evidence: int = 0            # 0..100 (consequence system)
var risk: int = 0
var skills := {
	"linux": 0,
	"networking": 0,
	"web": 0,
	"forensics": 0,
}
var xp := {
	"linux": 0,
	"networking": 0,
	"web": 0,
	"forensics": 0,
}
var inventory := {}              # id -> count
var flags := {}                  # one-time story/mission flags
var session := {}                # transient (not saved)

func _ready() -> void:
	reset()

func reset() -> void:
	player_name = "Ari"
	age = 16
	money = START_MONEY
	energy = 100.0
	hunger = 20.0
	school_perf = 60.0
	reputation = 0
	evidence = 0
	risk = 0
	skills = {"linux": 0, "networking": 0, "web": 0, "forensics": 0}
	xp = {"linux": 0, "networking": 0, "web": 0, "forensics": 0}
	inventory = {"snack": 2, "energy_drink": 1, "usb_drive": 1}
	flags = {}
	session = {}

# ---------------- economy ----------------
func add_money(v: int) -> void:
	money = maxi(0, money + v)
	Events.money_changed.emit(money)

func can_afford(v: int) -> bool:
	return money >= v

func spend(v: int) -> bool:
	if not can_afford(v):
		return false
	money -= v
	Events.money_changed.emit(money)
	return true

# ---------------- skills ----------------
func level_of(skill: String) -> int:
	var total: int = int(xp.get(skill, 0))
	var lv := 0
	for i in range(SKILL_LEVELS.size()):
		if total >= SKILL_LEVELS[i]:
			lv = i
	return lv

func add_xp(skill: String, amount: int) -> void:
	if not xp.has(skill):
		return
	xp[skill] += amount
	var lv := level_of(skill)
	Events.xp_changed.emit(skill, xp[skill], lv)
	if lv > skills[skill]:
		skills[skill] = lv
		Events.skill_up.emit(skill, lv)
		Events.notify.emit("Skill up: %s -> Level %d" % [skill.capitalize(), lv], "success")

func skill_level(skill: String) -> int:
	return int(skills.get(skill, 0))

# ---------------- needs ----------------
func set_energy(v: float) -> void:
	energy = clampf(v, 0.0, 100.0)
	Events.stat_changed.emit("energy", energy)

func set_hunger(v: float) -> void:
	hunger = clampf(v, 0.0, 100.0)
	Events.stat_changed.emit("hunger", hunger)

func add_school_perf(v: float) -> void:
	school_perf = clampf(school_perf + v, 0.0, 100.0)
	Events.stat_changed.emit("school", school_perf)

# ---------------- inventory ----------------
func add_item(id: String, count: int = 1) -> void:
	inventory[id] = int(inventory.get(id, 0)) + count

func has_item(id: String, count: int = 1) -> bool:
	return int(inventory.get(id, 0)) >= count

func use_item(id: String) -> bool:
	if not has_item(id):
		return false
	inventory[id] = int(inventory[id]) - 1
	if int(inventory[id]) <= 0:
		inventory.erase(id)
	return true

# ---------------- flags ----------------
func set_flag(id: String, value: bool = true) -> void:
	flags[id] = value

func flag(id: String) -> bool:
	return bool(flags.get(id, false))

# ---------------- consequence system ----------------
func add_evidence(v: int) -> void:
	evidence = clampi(evidence + v, 0, 100)
	Events.evidence_changed.emit(evidence)

# ---------------- serialization ----------------
func to_dict() -> Dictionary:
	return {
		"v": 1,
		"player_name": player_name,
		"age": age,
		"money": money,
		"energy": energy,
		"hunger": hunger,
		"school_perf": school_perf,
		"reputation": reputation,
		"evidence": evidence,
		"risk": risk,
		"skills": skills.duplicate(true),
		"xp": xp.duplicate(true),
		"inventory": inventory.duplicate(true),
		"flags": flags.duplicate(true),
	}

func from_dict(d: Dictionary) -> void:
	reset()
	player_name = str(d.get("player_name", player_name))
	age = int(d.get("age", age))
	money = int(d.get("money", money))
	energy = float(d.get("energy", energy))
	hunger = float(d.get("hunger", hunger))
	school_perf = float(d.get("school_perf", school_perf))
	reputation = int(d.get("reputation", reputation))
	evidence = int(d.get("evidence", evidence))
	risk = int(d.get("risk", risk))
	var sk: Dictionary = d.get("skills", {})
	for k in sk.keys():
		skills[k] = int(sk[k])
	var xp_d: Dictionary = d.get("xp", {})
	for k in xp_d.keys():
		xp[k] = int(xp_d[k])
	var inv: Dictionary = d.get("inventory", {})
	inventory = {}
	for k in inv.keys():
		inventory[k] = int(inv[k])
	var fl: Dictionary = d.get("flags", {})
	flags = {}
	for k in fl.keys():
		flags[k] = bool(fl[k])
