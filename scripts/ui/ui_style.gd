# ============================================================
# UI 工具样式集
# 封装所有UI控件的统一样式，确保全局视觉一致。
# 使用: 在创建UI控件时调用对应的样式函数。
#
# 规范参考: res://ui_prototypes/UI_STYLE.md
# ============================================================
extends RefCounted

# ===== 色彩常量 =====
const COLOR_PANEL_BG = Color(0.039, 0.039, 0.098, 0.95)
const COLOR_BORDER = Color(1, 1, 1, 0.15)
const COLOR_BORDER_STRONG = Color(1, 1, 1, 0.2)
const COLOR_TEXT_MAIN = Color(0.8, 0.8, 0.8)
const COLOR_TEXT_BRIGHT = Color(1, 1, 1)
const COLOR_TEXT_DIM = Color(0.53, 0.53, 0.53)
const COLOR_TEXT_WEAK = Color(0.33, 0.33, 0.33)

const COLOR_FRIENDLY = Color(0.27, 0.67, 0.53)
const COLOR_ENEMY = Color(0.8, 0.27, 0.27)
const COLOR_HIGHLIGHT = Color(0.47, 0.67, 1.0)
const COLOR_WARN = Color(1.0, 0.67, 0.27)

const COLOR_MORALE_NORMAL = Color(0.27, 0.53, 0.27)
const COLOR_MORALE_HIGH = Color(0.53, 0.53, 0.27)
const COLOR_MORALE_CONFUSED = Color(0.53, 0.4, 0.27)
const COLOR_MORALE_BROKEN = Color(0.53, 0.27, 0.27)
const COLOR_MORALE_FRENZY = Color(0.8, 0.53, 0.0)

const COLOR_CQB = Color(0.27, 0.67, 0.27)

# 指挥官技能色
const COLOR_SKILL_BG = Color(0.33, 0.8, 0.33)
const COLOR_SKILL_TALENT = Color(0.4, 0.53, 1.0)
const COLOR_SKILL_QUALITY = Color(1.0, 0.67, 0.4)
const COLOR_SKILL_LEVEL = Color(1.0, 1.0, 0.4)

# 品质标签
const COLOR_CMD_BG = Color(0.6, 1.0, 0.6)
const COLOR_CMD_TALENT = Color(0.4, 0.5, 0.6)
const COLOR_CMD_QUALITY = Color(1.0, 0.67, 0.4)
const COLOR_CMD_LEVEL = Color(1.0, 1.0, 0.4)

# ===== 字号 =====
const FONT_TITLE = 14
const FONT_SECTION = 12
const FONT_BODY = 11
const FONT_SMALL = 10
const FONT_TINY = 9
const FONT_MINI = 8

# ===== 通用StyleBox工具 =====

static func make_panel_bg(corner: int = 6, border_alpha: float = 0.15) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = COLOR_PANEL_BG
	sb.set_corner_radius_all(corner)
	sb.set_border_width_all(1)
	sb.set_border_color(Color(1, 1, 1, border_alpha))
	return sb

static func make_card_bg(corner: int = 4) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1, 0.04)
	sb.set_corner_radius_all(corner)
	sb.set_border_width_all(1)
	sb.set_border_color(Color(1, 1, 1, 0.06))
	return sb

static func make_skill_bg(alpha: float = 0.06, border_alpha: float = 0.1) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1, alpha)
	sb.set_corner_radius_all(4)
	sb.set_border_width_all(1)
	sb.set_border_color(Color(1, 1, 1, border_alpha))
	return sb

static func make_hp_bar_bg() -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1, 0.06)
	sb.set_corner_radius_all(3)
	return sb

# ===== 按钮样式 =====

static func style_button(btn: Button, bg_color: Color = Color(0.27, 0.27, 0.33, 1.0)) -> void:
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg_color
	sb.set_corner_radius_all(4)
	sb.set_border_width_all(1)
	sb.set_border_color(Color(1, 1, 1, 0.2))
	btn.add_theme_stylebox_override("normal", sb)
	# hover
	var sb_h = StyleBoxFlat.new()
	sb_h.bg_color = Color(bg_color.r + 0.05, bg_color.g + 0.05, bg_color.b + 0.05, 1.0)
	sb_h.set_corner_radius_all(4)
	sb_h.set_border_width_all(1)
	sb_h.set_border_color(Color(1, 1, 1, 0.3))
	btn.add_theme_stylebox_override("hover", sb_h)

# ===== 标签样式 =====

static func style_label(lbl: Label, size: int = FONT_BODY, color: Color = COLOR_TEXT_MAIN) -> void:
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", color)

static func colorize_skill_label(lbl: Label, skill_type: String) -> void:
	match skill_type:
		"background": lbl.add_theme_color_override("font_color", COLOR_SKILL_BG)
		"talent": lbl.add_theme_color_override("font_color", COLOR_SKILL_TALENT)
		"quality": lbl.add_theme_color_override("font_color", COLOR_SKILL_QUALITY)
		"level": lbl.add_theme_color_override("font_color", COLOR_SKILL_LEVEL)
		_: lbl.add_theme_color_override("font_color", COLOR_TEXT_MAIN)

# ===== 士气状态标签 =====

static func get_morale_badge(morale: int) -> Dictionary:
	if morale <= 0:   return {"text": "溃败", "color": COLOR_MORALE_BROKEN}
	if morale <= 20:  return {"text": "混乱", "color": COLOR_MORALE_CONFUSED}
	if morale <= 70:  return {"text": "正常", "color": COLOR_MORALE_NORMAL}
	if morale <= 90:  return {"text": "高昂", "color": COLOR_MORALE_HIGH}
	return {"text": "狂热", "color": COLOR_MORALE_FRENZY}

static func apply_morale_badge(lbl: Label, morale: int) -> void:
	var badge = get_morale_badge(morale)
	lbl.text = badge["text"]
	var sb = StyleBoxFlat.new()
	sb.bg_color = badge["color"]
	sb.set_corner_radius_all(3)
	lbl.add_theme_stylebox_override("normal", sb)
	lbl.add_theme_color_override("font_color", Color(1, 1, 1))
	lbl.add_theme_font_size_override("font_size", FONT_TINY)
