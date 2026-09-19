extends VBoxContainer
## About NyxOS + security statement.

func _ready() -> void:
        add_theme_constant_override("separation", 10)
        add_child(UiKit.title("About NyxOS", 20))
        var info := UiKit.label(
                "NyxOS 2.1 'moonrabbit'\nA fictional operating system inside HackerLife.\n\nMachine: ARI-PC-01 (old but loyal)\nOwner: Ari, age %d\nUptime: since you woke up" % Game.age,
                14)
        add_child(info)
        add_child(UiKit.spacer(8))
        var sb := PanelContainer.new()
        sb.add_theme_stylebox_override("panel", UiKit.panel_style(Color(0.08, 0.06, 0.03), UiKit.WARN, 6))
        add_child(sb)
        var sv := VBoxContainer.new()
        sv.add_child(UiKit.label("SECURITY / SANDBOX STATEMENT", 14, UiKit.WARN))
        var txt := UiKit.label(
                "All networks, hosts, services and files in this game are fictional\nsimulations running entirely inside the game.\n\nNo real IP is scanned. No real system is contacted.\nNo real credentials are collected. No real attack code exists here.",
                13, UiKit.FG)
        txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        sv.add_child(txt)
        add_child(UiKit.spacer(8))
        add_child(UiKit.label("HackerLife v0.1.0 - an original indie prototype", 12, UiKit.FG_DIM))
