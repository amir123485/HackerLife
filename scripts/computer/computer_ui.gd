extends CanvasLayer
## NyxOS — the in-game computer desktop. Fullscreen overlay UI.

const APPS := [
        {"id": "terminal", "name": "Terminal", "icon": ">_"},
        {"id": "files", "name": "Files", "icon": "[_]"},
        {"id": "browser", "name": "NyxNet", "icon": "(o)"},
        {"id": "messages", "name": "Messages", "icon": "[!]"},
        {"id": "lab", "name": "CyberLab", "icon": "{*}"},
        {"id": "about", "name": "About", "icon": "(i)"},
]

var root: Control
var desktop: Control
var taskbar: PanelContainer
var clock_label: Label
var window_panel: PanelContainer
var window_title: Label
var window_content: Control
var current_app: String = ""
var app_nodes := {}

func _ready() -> void:
        layer = 20
        visible = false
        add_to_group("computer_ui")
        _build()

func _build() -> void:
        root = Control.new()
        root.set_anchors_preset(Control.PRESET_FULL_RECT)
        add_child(root)

        desktop = Control.new()
        desktop.set_anchors_preset(Control.PRESET_FULL_RECT)
        root.add_child(desktop)

        # wallpaper
        var wp := ColorRect.new()
        wp.set_anchors_preset(Control.PRESET_FULL_RECT)
        wp.color = Color(0.035, 0.05, 0.085)
        desktop.add_child(wp)
        # subtle grid lines
        var grid := ColorRect.new()
        grid.set_anchors_preset(Control.PRESET_FULL_RECT)
        grid.color = Color(0.05, 0.09, 0.13, 0.35)
        desktop.add_child(grid)
        var glowline := ColorRect.new()
        glowline.position = Vector2(0, 140)
        glowline.size = Vector2(1280, 2)
        glowline.color = Color(0.0, 0.9, 0.6, 0.25)
        desktop.add_child(glowline)
        var logo := UiKit.title("NyxOS 2.1", 44, Color(0.0, 0.9, 0.6, 0.22))
        logo.position = Vector2(60, 160)
        desktop.add_child(logo)
        var tag := UiKit.label("personal workstation - ari's room", 14, Color(0.4, 0.55, 0.6, 0.5))
        tag.position = Vector2(62, 210)
        desktop.add_child(tag)

        # desktop icons
        var icons := HBoxContainer.new()
        icons.position = Vector2(50, 280)
        icons.add_theme_constant_override("separation", 18)
        desktop.add_child(icons)
        for a in APPS:
                var btn := _icon_button(a["icon"], a["name"])
                btn.pressed.connect(_open_app.bind(a["id"]))
                icons.add_child(btn)

        # taskbar
        taskbar = PanelContainer.new()
        taskbar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
        taskbar.grow_vertical = Control.GROW_DIRECTION_BEGIN
        taskbar.add_theme_stylebox_override("panel", UiKit.panel_style(Color(0.04, 0.06, 0.1, 0.95), Color(0.1, 0.5, 0.4, 0.4), 0))
        var hb := HBoxContainer.new()
        hb.add_theme_constant_override("separation", 14)
        taskbar.add_child(hb)
        var os_label := UiKit.label("NyxOS", 14, UiKit.ACCENT)
        hb.add_child(os_label)
        var sep := UiKit.label("|", 14, UiKit.FG_DIM)
        hb.add_child(sep)
        var leave := UiKit.button("Leave computer", UiKit.DANGER, 13)
        leave.pressed.connect(close)
        hb.add_child(leave)
        var spacer := Control.new()
        spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        hb.add_child(spacer)
        clock_label = UiKit.label("", 14, UiKit.FG_DIM)
        hb.add_child(clock_label)
        root.add_child(taskbar)

        # app window (hidden) — centered via CenterContainer
        var center := CenterContainer.new()
        center.set_anchors_preset(Control.PRESET_FULL_RECT)
        center.mouse_filter = Control.MOUSE_FILTER_IGNORE
        root.add_child(center)
        window_panel = PanelContainer.new()
        window_panel.custom_minimum_size = Vector2(860, 520)
        window_panel.add_theme_stylebox_override("panel", UiKit.panel_style(UiKit.BG, UiKit.ACCENT, 8, 2))
        center.add_child(window_panel)
        var vb := VBoxContainer.new()
        vb.add_theme_constant_override("separation", 8)
        window_panel.add_child(vb)
        var title_hb := HBoxContainer.new()
        vb.add_child(title_hb)
        window_title = UiKit.title("", 18)
        title_hb.add_child(window_title)
        var tspace := Control.new()
        tspace.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        title_hb.add_child(tspace)
        var close_btn := UiKit.button("X", UiKit.DANGER, 14)
        close_btn.pressed.connect(_close_app)
        title_hb.add_child(close_btn)
        window_content = Control.new()
        window_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
        window_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        vb.add_child(window_content)
        window_panel.visible = false

func _icon_button(icon: String, name_: String) -> Button:
        var b := Button.new()
        b.custom_minimum_size = Vector2(120, 86)
        var sb := UiKit.panel_style(Color(0.07, 0.1, 0.15, 0.9), Color(0.0, 0.7, 0.5, 0.4), 8)
        var sbh := UiKit.panel_style(Color(0.09, 0.14, 0.2, 0.95), UiKit.ACCENT, 8)
        b.add_theme_stylebox_override("normal", sb)
        b.add_theme_stylebox_override("hover", sbh)
        b.add_theme_stylebox_override("pressed", sbh)
        b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
        b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
        var vb := VBoxContainer.new()
        vb.set_anchors_preset(Control.PRESET_FULL_RECT)
        vb.alignment = BoxContainer.ALIGNMENT_CENTER
        vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
        b.add_child(vb)
        var ic := UiKit.label(icon, 22, UiKit.ACCENT2)
        ic.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        vb.add_child(ic)
        var nm := UiKit.label(name_, 13)
        nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        vb.add_child(nm)
        return b

# ---------------------------------------------------------------- app mgmt
func _open_app(id: String) -> void:
        Sfx.play("ui_click")
        if current_app == id:
                return
        _close_app_instance()
        current_app = id
        window_panel.visible = true
        for a in APPS:
                if a["id"] == id:
                        window_title.text = a["name"]
        for child in window_content.get_children():
                child.queue_free()
        var app: Control = null
        match id:
                "terminal":
                        app = load("res://scripts/computer/terminal_app.gd").new()
                "files":
                        app = load("res://scripts/computer/files_app.gd").new()
                "browser":
                        app = load("res://scripts/computer/browser_app.gd").new()
                "messages":
                        app = load("res://scripts/computer/messages_app.gd").new()
                "lab":
                        app = load("res://scripts/computer/lab_app.gd").new()
                "about":
                        app = load("res://scripts/computer/about_app.gd").new()
        if app != null:
                window_content.add_child(app)
                app.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
                app_nodes[id] = app
                if id == "terminal":
                        Missions.report("terminal_opened")

func _close_app() -> void:
        Sfx.play("ui_click")
        _close_app_instance()
        current_app = ""

func _close_app_instance() -> void:
        for child in window_content.get_children():
                child.queue_free()
        window_panel.visible = false

func open() -> void:
        visible = true
        current_app = ""
        _close_app_instance()
        window_panel.visible = false
        Events.computer_opened.emit()

func close() -> void:
        Sfx.play("ui_click")
        visible = false
        Events.computer_closed.emit()

func _process(_delta: float) -> void:
        if visible and clock_label != null:
                clock_label.text = "%s  |  %s Day %d" % [TimeSys.clock_text(), TimeSys.weekday(), TimeSys.day]
