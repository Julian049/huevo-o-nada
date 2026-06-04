extends Node

# ═══════════════════════════════════════════════════════════════
#  UIManager — HUD con etiquetas, sin instrucciones, botón menú,
#              banners animados y game over animado
# ═══════════════════════════════════════════════════════════════

# ── HUD ───────────────────────────────────────────────────────
@onready var label_day         : Label          = $HUD/HBoxContainer/DayBox/LabelDay
@onready var label_vaccines    : Label          = $HUD/HBoxContainer/VaccineBox/LabelVaccines
@onready var label_medications : Label          = $HUD/HBoxContainer/MedBox/LabelMedications
@onready var balance_label     : Label          = $HUD/HBoxContainer/BalanceBox/BalanceLabel
@onready var inventory_label   : Label          = $HUD/HBoxContainer/EggBox/InventarioLabel
@onready var debt_label        : Label          = $HUD/HBoxContainer/DebtBox/DeudaLabel
@onready var rodent_label      : Label          = $HUD/HBoxContainer/RodentBox/RodentLabel

# ── Game over ─────────────────────────────────────────────────
@onready var label_game_over   : Label          = $GameOverPanel/VBoxContainer/LabelGameOver
@onready var restart_button    : Button         = $GameOverPanel/VBoxContainer/RestartButton
@onready var menu_button       : Button         = $GameOverPanel/VBoxContainer/MenuButton
@onready var game_over_panel   : PanelContainer = $GameOverPanel

# ── Event banner ──────────────────────────────────────────────
@onready var event_banner      : PanelContainer = $EventBanner
@onready var event_banner_label: Label          = $EventBanner/LabelEvento

# ── In-game menu button (top-right corner) ────────────────────
@onready var btn_menu_ingame   : Button         = $BtnMenuIngame

# ── Colores de eventos ────────────────────────────────────────
const COLOR_VENTA    := Color(0.247, 0.780, 0.373)
const COLOR_PRECIO   := Color(0.961, 0.773, 0.259)
const COLOR_MAIZ     := Color(0.961, 0.773, 0.259)
const COLOR_BANQUERO := Color(0.286, 0.631, 0.902)
const COLOR_MULTA    := Color(0.961, 0.247, 0.247)
const COLOR_INSP_OK  := Color(0.247, 0.780, 0.373)
const COLOR_VACUNAS  := Color(0.529, 0.808, 0.922)
const COLOR_VECINO   := Color(0.902, 0.486, 0.114)
const COLOR_ROEDOR   := Color(0.780, 0.560, 0.247)
const COLOR_DEFAULT  := Color(0.961, 0.773, 0.259)

# ── Cola de banners ───────────────────────────────────────────
var _banner_queue : Array = []
var _banner_busy  : bool  = false

const DUR_IN   := 0.30
const DUR_HOLD := 2.8
const DUR_OUT  := 0.22
const DUR_GO   := 0.50


# ═══════════════════════════════════════════════════════════════
#  SETUP
# ═══════════════════════════════════════════════════════════════

func setup_initial_ui() -> void:
	game_over_panel.visible  = false
	_set_hud_visible(false)
	event_banner.visible     = false
	event_banner.modulate.a  = 0.0
	btn_menu_ingame.visible  = false

func setup_running_ui() -> void:
	_set_hud_visible(true)
	event_banner.visible     = false
	event_banner.modulate.a  = 0.0
	btn_menu_ingame.visible  = true


# ═══════════════════════════════════════════════════════════════
#  HUD
# ═══════════════════════════════════════════════════════════════

func update_hud(day: int, player: Node) -> void:
	label_day.text         = str(day) + " / 30"
	label_vaccines.text    = str(player.vaccine_inventory)
	label_medications.text = str(player.medicine_inventory)

func update_economy(balance: float, inventory: int, remaining_debt: float) -> void:
	balance_label.text   = "$" + _format_cop(int(balance))
	inventory_label.text = str(inventory)
	debt_label.text      = "$" + _format_cop(int(max(0.0, remaining_debt)))

	if remaining_debt <= 300_000:
		debt_label.add_theme_color_override("font_color", Color(0.247, 0.780, 0.373))
	elif remaining_debt <= 800_000:
		debt_label.add_theme_color_override("font_color", Color(0.961, 0.773, 0.259))
	else:
		debt_label.add_theme_color_override("font_color", Color(0.753, 0.224, 0.169))

func update_rodents(n_vivos: int, n_trampas: int) -> void:
	rodent_label.text = str(n_vivos) + " 🐀  " + str(n_trampas) + " 🪤"


# ═══════════════════════════════════════════════════════════════
#  EVENT BANNER — cola + scale Y + fade
# ═══════════════════════════════════════════════════════════════

func show_event_banner(message: String) -> void:
	_banner_queue.push_back({"msg": message, "color": _color_for_message(message)})
	if not _banner_busy:
		_next_banner()

func _next_banner() -> void:
	if _banner_queue.is_empty():
		_banner_busy = false
		return
	_banner_busy = true
	var item  : Dictionary = _banner_queue.pop_front()
	var msg   : String     = item["msg"]
	var color : Color      = item["color"]

	event_banner_label.text = msg
	event_banner_label.add_theme_color_override("font_color", color)
	event_banner.modulate.a  = 0.0
	event_banner.scale       = Vector2(1.0, 0.3)
	event_banner.pivot_offset = Vector2(event_banner.size.x * 0.5, event_banner.size.y)
	event_banner.visible     = true

	var tw_in := create_tween().set_parallel(true)
	tw_in.tween_property(event_banner, "scale",      Vector2(1.0, 1.0), DUR_IN)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw_in.tween_property(event_banner, "modulate:a", 1.0, DUR_IN)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	await tw_in.finished

	await get_tree().create_timer(DUR_HOLD).timeout

	var tw_out := create_tween().set_parallel(true)
	tw_out.tween_property(event_banner, "scale",      Vector2(1.0, 0.3), DUR_OUT)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tw_out.tween_property(event_banner, "modulate:a", 0.0, DUR_OUT)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	await tw_out.finished

	event_banner.visible = false
	event_banner.scale   = Vector2(1.0, 1.0)
	_next_banner()


# ═══════════════════════════════════════════════════════════════
#  GAME OVER — scale pop + blink + shake
# ═══════════════════════════════════════════════════════════════

func show_game_over(message: String = "GAME OVER") -> void:
	label_game_over.text = message
	var is_victoria : bool  = message.contains("salvada") or message.contains("Victoria")
	var title_color : Color = COLOR_INSP_OK if is_victoria else COLOR_MULTA
	label_game_over.add_theme_color_override("font_color", title_color)

	game_over_panel.visible    = true
	game_over_panel.modulate.a = 0.0
	game_over_panel.scale      = Vector2(0.0, 0.0)
	restart_button.modulate.a  = 0.0
	menu_button.modulate.a     = 0.0

	var t1 := create_tween().set_parallel(true)
	t1.tween_property(game_over_panel, "scale",      Vector2(1.08, 1.08), DUR_GO * 0.7)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t1.tween_property(game_over_panel, "modulate:a", 1.0, DUR_GO * 0.6)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	await t1.finished

	var t2 := create_tween()
	t2.tween_property(game_over_panel, "scale", Vector2(1.0, 1.0), 0.15)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SPRING)
	await t2.finished

	if not is_victoria:
		for _i in range(3):
			var ta := create_tween()
			ta.tween_property(label_game_over, "modulate", Color.WHITE, 0.07)
			await ta.finished
			var tb := create_tween()
			tb.tween_property(label_game_over, "modulate", Color(title_color), 0.07)
			await tb.finished
		label_game_over.modulate = Color.WHITE

	if not is_victoria:
		var base : float = game_over_panel.offset_left
		for i in range(10):
			var amp : float = 8.0 * (1.0 - float(i) / 10.0)
			var dir : float = 1.0 if i % 2 == 0 else -1.0
			var ts  := create_tween()
			ts.tween_property(game_over_panel, "offset_left", base + dir * amp, 0.035)
			await ts.finished
		var tr := create_tween()
		tr.tween_property(game_over_panel, "offset_left", base, 0.05)
		await tr.finished

	var t5 := create_tween().set_parallel(true)
	t5.tween_property(restart_button, "modulate:a", 1.0, 0.30)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t5.tween_property(menu_button, "modulate:a", 1.0, 0.30)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)


# ═══════════════════════════════════════════════════════════════
#  COLOR POR EVENTO
# ═══════════════════════════════════════════════════════════════

func _color_for_message(msg: String) -> Color:
	if msg.contains("Venta")    or msg.contains("🛒"): return COLOR_VENTA
	if msg.contains("Precio")   or msg.contains("📈"): return COLOR_PRECIO
	if msg.contains("alimento") or msg.contains("🌽"): return COLOR_MAIZ
	if msg.contains("Deuda")    or msg.contains("🏦") or msg.contains("Banquero"): return COLOR_BANQUERO
	if msg.contains("Multa")    or msg.contains("🚨"): return COLOR_MULTA
	if msg.contains("superada") or msg.contains("✅"): return COLOR_INSP_OK
	if msg.contains("Vacunas")  or msg.contains("💊"): return COLOR_VACUNAS
	if msg.contains("Vecino")   or msg.contains("😤"): return COLOR_VECINO
	if msg.contains("oedor")    or msg.contains("🐀") or msg.contains("Trampa") or msg.contains("🪤"): return COLOR_ROEDOR
	return COLOR_DEFAULT


# ═══════════════════════════════════════════════════════════════
#  BOTONES
# ═══════════════════════════════════════════════════════════════

func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/world/main_menu.tscn")

func _on_btn_menu_ingame_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/world/main_menu.tscn")

func _set_hud_visible(is_visible: bool) -> void:
	$HUD.visible = is_visible

func _format_cop(value: int) -> String:
	var s := str(abs(value))
	var o := ""
	var c := 0
	for i in range(s.length() - 1, -1, -1):
		if c > 0 and c % 3 == 0: o = "." + o
		o = s[i] + o
		c += 1
	return ("-" if value < 0 else "") + o
