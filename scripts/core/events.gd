extends Node
## Global event bus. Decouples systems (UI <-> game state <-> missions).

signal notify(text: String, kind: String)              # kind: "info" | "success" | "warn" | "fail"
signal money_changed(value: int)
signal xp_changed(skill: String, xp: int, level: int)
signal skill_up(skill: String, level: int)
signal stat_changed(stat: String, value: float)        # energy | hunger | school
signal clock_changed(minute_of_day: int, day: int)
signal mission_started(id: String)
signal objective_done(id: String, title: String)
signal mission_completed(id: String, reward_text: String)
signal evidence_changed(value: int)
signal computer_opened
signal computer_closed
