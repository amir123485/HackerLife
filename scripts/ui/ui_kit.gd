class_name UiKit
## Small helper for consistent dark/neon UI styling.

const BG := Color(0.06, 0.08, 0.12, 0.98)
const BG_LIGHT := Color(0.10, 0.13, 0.19, 0.98)
const FG := Color(0.88, 0.92, 0.95)
const FG_DIM := Color(0.55, 0.62, 0.70)
const ACCENT := Color(0.0, 0.95, 0.6)
const ACCENT2 := Color(0.0, 0.75, 1.0)
const DANGER := Color(1.0, 0.35, 0.4)
const WARN := Color(1.0, 0.75, 0.3)

static func panel_style(bg: Color = BG, border: Color = Color(0.2, 0.75, 0.6, 0.5), radius := 6, border_w := 1) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	return sb

static func button(text: String, accent: Color = ACCENT, font_size := 15) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_color_override("font_color", FG)
	b.add_theme_color_override("font_hover_color", accent)
	b.add_theme_color_override("font_pressed_color", accent)
	var sb := panel_style(BG_LIGHT, Color(accent.r, accent.g, accent.b, 0.35), 4)
	var sb_h := panel_style(BG_LIGHT.lightened(0.05), accent, 4)
	var sb_p := panel_style(BG, accent, 4)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb_h)
	b.add_theme_stylebox_override("pressed", sb_p)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return b

static func label(text: String, size := 14, color: Color = FG) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l

static func title(text: String, size := 22, color: Color = ACCENT) -> Label:
	var l := label(text, size, color)
	return l

static func spacer(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c

static func bar(fg: Color) -> ProgressBar:
	var p := ProgressBar.new()
	p.custom_minimum_size = Vector2(120, 10)
	p.show_percentage = false
	var bg_sb := panel_style(Color(0.03, 0.04, 0.07), Color(0.2, 0.25, 0.3), 3)
	bg_sb.content_margin_top = 2
	bg_sb.content_margin_bottom = 2
	bg_sb.content_margin_left = 2
	bg_sb.content_margin_right = 2
	var fg_sb := panel_style(fg, fg, 3)
	p.add_theme_stylebox_override("background", bg_sb)
	p.add_theme_stylebox_override("fill", fg_sb)
	return p
