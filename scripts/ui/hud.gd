extends CanvasLayer
## In-game HUD: clock, needs, money, mission tracker, prompts, notifications.

var clock_label: Label
var energy_bar: ProgressBar
var hunger_bar: ProgressBar
var school_bar: ProgressBar
var money_label: Label
var mission_title: Label
var mission_obj: Label
var mission_prog: Label
var prompt_label: Label
var toast_layer: CanvasLayer
var toast_box: VBoxContainer
var side_panel: PanelContainer
var inv_box: VBoxContainer
var skill_box: VBoxContainer
var complete_banner: PanelContainer
var complete_label: Label

func _ready() -> void:
        layer = 10
        _build()
        Events.clock_changed.connect(func(_m, _d): _refresh_clock())
        Events.money_changed.connect(func(v): money_label.text = "%d cr" % v)
        Events.stat_changed.connect(func(_s, _v): _refresh_bars())
        Events.notify.connect(_toast)
        Events.objective_done.connect(_on_objective)
        Events.mission_started.connect(func(_id): _refresh_mission())
        Events.mission_completed.connect(_on_mission_complete)
        Events.skill_up.connect(func(_s, _l): _refresh_skills())
        _refresh_clock()
        _refresh_bars()
        _refresh_mission()
        money_label.text = "%d cr" % Game.money

func _build() -> void:
        # ---- top-left: clock + needs
        var tl := PanelContainer.new()
        tl.position = Vector2(14, 14)
        tl.add_theme_stylebox_override("panel", UiKit.panel_style(Color(0.04, 0.06, 0.1, 0.85), Color(0.1, 0.5, 0.4, 0.35)))
        add_child(tl)
        var tvb := VBoxContainer.new()
        tvb.add_theme_constant_override("separation", 5)
        tl.add_child(tvb)
        clock_label = UiKit.title("07:00  Mon Day 1", 17)
        tvb.add_child(clock_label)
        money_label = UiKit.label("0 cr", 14, UiKit.WARN)
        tvb.add_child(money_label)
        var e_row := HBoxContainer.new()
        e_row.add_child(UiKit.label("EN", 12, UiKit.FG_DIM))
        energy_bar = UiKit.bar(UiKit.ACCENT)
        energy_bar.custom_minimum_size = Vector2(150, 9)
        e_row.add_child(energy_bar)
        tvb.add_child(e_row)
        var h_row := HBoxContainer.new()
        h_row.add_child(UiKit.label("HU", 12, UiKit.FG_DIM))
        hunger_bar = UiKit.bar(UiKit.WARN)
        hunger_bar.custom_minimum_size = Vector2(150, 9)
        h_row.add_child(hunger_bar)
        tvb.add_child(h_row)
        var s_row := HBoxContainer.new()
        s_row.add_child(UiKit.label("SC", 12, UiKit.FG_DIM))
        school_bar = UiKit.bar(UiKit.ACCENT2)
        school_bar.custom_minimum_size = Vector2(150, 9)
        s_row.add_child(school_bar)
        tvb.add_child(s_row)
        var hint := UiKit.label("Tab: stats/inventory   Esc: pause", 11, UiKit.FG_DIM)
        tvb.add_child(hint)

        # ---- top-right: mission tracker
        var tr := PanelContainer.new()
        tr.set_anchors_preset(Control.PRESET_TOP_RIGHT)
        tr.position = Vector2(-306, 14)
        tr.grow_horizontal = Control.GROW_DIRECTION_BEGIN
        tr.custom_minimum_size = Vector2(292, 0)
        tr.add_theme_stylebox_override("panel", UiKit.panel_style(Color(0.04, 0.08, 0.07, 0.88), UiKit.ACCENT, 6))
        add_child(tr)
        var mv := VBoxContainer.new()
        mv.add_theme_constant_override("separation", 4)
        tr.add_child(mv)
        mv.add_child(UiKit.label("MISSION  [FIRST CONNECTION]", 12, UiKit.ACCENT))
        mission_title = UiKit.label("", 14)
        mission_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        mv.add_child(mission_title)
        mission_obj = UiKit.label("", 12, UiKit.FG_DIM)
        mission_obj.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        mv.add_child(mission_obj)
        mission_prog = UiKit.label("", 11, UiKit.ACCENT2)
        mv.add_child(mission_prog)

        # ---- bottom prompt
        prompt_label = UiKit.title("", 17, UiKit.ACCENT)
        prompt_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
        prompt_label.anchor_top = 1.0
        prompt_label.anchor_bottom = 1.0
        prompt_label.offset_top = -86.0
        prompt_label.offset_left = -200.0
        prompt_label.offset_right = 200.0
        prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        prompt_label.add_theme_constant_override("shadow_offset_y", 1)
        add_child(prompt_label)

        # ---- toasts + mission banner live on a HIGHER layer (above computer UI)
        toast_layer = CanvasLayer.new()
        toast_layer.layer = 30
        add_child(toast_layer)
        toast_box = VBoxContainer.new()
        toast_box.set_anchors_preset(Control.PRESET_CENTER_TOP)
        toast_box.anchor_left = 0.5
        toast_box.anchor_right = 0.5
        toast_box.offset_left = -220
        toast_box.offset_right = 220
        toast_box.offset_top = 16
        toast_box.add_theme_constant_override("separation", 6)
        toast_layer.add_child(toast_box)

        # ---- side panel (Tab)
        side_panel = PanelContainer.new()
        side_panel.position = Vector2(14, 210)
        side_panel.custom_minimum_size = Vector2(320, 0)
        side_panel.visible = false
        side_panel.add_theme_stylebox_override("panel", UiKit.panel_style(Color(0.05, 0.07, 0.11, 0.95), UiKit.ACCENT2, 6))
        add_child(side_panel)
        var spv := VBoxContainer.new()
        spav_add(spv)

        # ---- mission complete banner (high layer so it shows over the computer UI)
        var banner_holder := Control.new()
        banner_holder.set_anchors_preset(Control.PRESET_FULL_RECT)
        banner_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
        toast_layer.add_child(banner_holder)
        var banner_center := CenterContainer.new()
        banner_center.set_anchors_preset(Control.PRESET_FULL_RECT)
        banner_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
        banner_holder.add_child(banner_center)
        complete_banner = PanelContainer.new()
        complete_banner.visible = false
        complete_banner.add_theme_stylebox_override("panel", UiKit.panel_style(Color(0.03, 0.1, 0.07, 0.97), UiKit.ACCENT, 8, 2))
        banner_center.add_child(complete_banner)
        var cv := VBoxContainer.new()
        complete_banner.add_child(cv)
        var t1 := UiKit.title("MISSION COMPLETE", 26)
        t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        cv.add_child(t1)
        complete_label = UiKit.label("", 15)
        complete_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        cv.add_child(complete_label)
        var ok := UiKit.button("Nice", UiKit.ACCENT)
        ok.pressed.connect(func():
                complete_banner.visible = false
                Sfx.play("ui_click"))
        var ok_wrap := HBoxContainer.new()
        ok_wrap.alignment = BoxContainer.ALIGNMENT_CENTER
        ok_wrap.add_child(ok)
        cv.add_child(ok_wrap)

func spav_add(spv: VBoxContainer) -> void:
        side_panel.add_child(spv)
        var t := UiKit.title("Ari - age %d" % Game.age, 16)
        spv.add_child(t)
        skill_box = VBoxContainer.new()
        spv.add_child(skill_box)
        inv_box = VBoxContainer.new()
        spv.add_child(inv_box)
        spv.add_child(UiKit.label("School performance shown as SC.", 11, UiKit.FG_DIM))
        _refresh_skills()
        _refresh_inventory()

const ITEM_NAMES := {
        "snack": "Snack (+hunger, +energy)",
        "energy_drink": "Energy drink (+25 energy)",
        "usb_drive": "USB drive (2GB of dreams)",
}

func _refresh_skills() -> void:
        if skill_box == null:
                return
        for c in skill_box.get_children():
                c.queue_free()
        skill_box.add_child(UiKit.label("SKILLS", 12, UiKit.ACCENT2))
        for s in Game.xp.keys():
                skill_box.add_child(UiKit.label("  %s  lvl %d  (%d xp)" % [s.capitalize(), Game.skill_level(s), Game.xp[s]], 13))

func _refresh_inventory() -> void:
        if inv_box == null:
                return
        for c in inv_box.get_children():
                c.queue_free()
        inv_box.add_child(UiKit.label("INVENTORY", 12, UiKit.ACCENT2))
        var empty := true
        for id in Game.inventory.keys():
                empty = false
                var row := HBoxContainer.new()
                var nm: String = ITEM_NAMES.get(id, id)
                row.add_child(UiKit.label("  %s x%d" % [nm, Game.inventory[id]], 13))
                var sp := Control.new()
                sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
                row.add_child(sp)
                if id == "snack" or id == "energy_drink":
                        var b := UiKit.button("use", UiKit.ACCENT, 12)
                        b.pressed.connect(_use_item.bind(str(id)))
                        row.add_child(b)
                inv_box.add_child(row)
        if empty:
                inv_box.add_child(UiKit.label("  (empty)", 13, UiKit.FG_DIM))

func _use_item(id: String) -> void:
        if not Game.use_item(id):
                return
        Sfx.play("ui_click")
        if id == "snack":
                Game.set_hunger(Game.hunger - 35)
                Game.set_energy(Game.energy + 8)
                Events.notify.emit("You feel better.", "info")
        elif id == "energy_drink":
                Game.set_energy(Game.energy + 25)
                Events.notify.emit("Buzzing. +25 energy.", "info")
        _refresh_inventory()
        _refresh_bars()

func _unhandled_input(event: InputEvent) -> void:
        if event.is_action_pressed("panel_toggle"):
                side_panel.visible = not side_panel.visible
                Sfx.play("ui_click")
                _refresh_inventory()
                _refresh_skills()

func _refresh_clock() -> void:
        clock_label.text = "%s  %s  Day %d" % [TimeSys.clock_text(), TimeSys.weekday(), TimeSys.day]
        if complete_banner != null and complete_banner.visible:
                pass

func _refresh_bars() -> void:
        energy_bar.value = Game.energy
        hunger_bar.value = Game.hunger
        school_bar.value = Game.school_perf

func _refresh_mission() -> void:
        if Missions.mission_complete:
                mission_title.text = "FIRST CONNECTION - complete"
                mission_obj.text = "More missions coming in future updates."
                mission_prog.text = ""
                return
        if not Missions.mission_active:
                mission_title.text = "No active mission"
                mission_obj.text = "Check your Messages on the computer."
                mission_prog.text = ""
                return
        var o := Missions.current_objective()
        if o.is_empty():
                mission_title.text = "All objectives done"
                mission_obj.text = ""
        else:
                mission_title.text = str(o["title"])
                mission_obj.text = ""
        mission_prog.text = "progress " + Missions.progress_text()

func _on_objective(_id: String, _title: String) -> void:
        _refresh_mission()
        _toast("Objective complete: " + _title, "success")
        mission_prog.text = "progress " + Missions.progress_text()

func _on_mission_complete(_id: String, reward_text: String) -> void:
        _refresh_mission()
        complete_label.text = reward_text
        complete_banner.visible = true
        Sfx.play("success")
        _refresh_bars()

func set_prompt(text: String) -> void:
        prompt_label.text = text

func _toast(text: String, kind: String) -> void:
        var color := UiKit.ACCENT
        match kind:
                "success": color = UiKit.ACCENT
                "warn": color = UiKit.WARN
                "fail": color = UiKit.DANGER
                "info": color = UiKit.ACCENT2
        var p := PanelContainer.new()
        p.add_theme_stylebox_override("panel", UiKit.panel_style(Color(0.04, 0.06, 0.1, 0.92), color, 5))
        var l := UiKit.label(text, 13, color)
        l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        l.custom_minimum_size = Vector2(420, 0)
        p.add_child(l)
        toast_box.add_child(p)
        var tw := p.create_tween()
        tw.tween_interval(3.2)
        tw.tween_property(p, "modulate:a", 0.0, 0.5)
        tw.tween_callback(p.queue_free)
        # keep stack small
        while toast_box.get_child_count() > 4:
                toast_box.get_child(0).queue_free()
                toast_box.remove_child(toast_box.get_child(0))
