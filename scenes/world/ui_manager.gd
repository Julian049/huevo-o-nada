extends Node

@onready var label_day         : Label          = $HUD/HBoxContainer/LabelDay
@onready var label_vaccines    : Label          = $HUD/HBoxContainer/LabelVaccines
@onready var label_medications : Label          = $HUD/HBoxContainer/LabelMedications
@onready var balance_label     : Label          = $HUD/HBoxContainer/BalanceLabel
@onready var inventory_label   : Label          = $HUD/HBoxContainer/InventarioLabel
@onready var debt_label        : Label          = $HUD/HBoxContainer/DeudaLabel

@onready var label_instruction : Label          = $LabelInstruction

@onready var label_game_over   : Label          = $GameOverPanel/VBoxContainer/LabelGameOver
@onready var restart_button    : Button         = $GameOverPanel/VBoxContainer/RestartButton
@onready var game_over_panel   : PanelContainer = $GameOverPanel

@onready var event_banner      : PanelContainer = $EventBanner
@onready var event_banner_label: Label          = $EventBanner/LabelEvento

func setup_initial_ui() -> void:
	label_instruction.visible = true
	game_over_panel.visible   = false
	_set_hud_visible(false)
	event_banner.visible      = false

func setup_running_ui() -> void:
	label_instruction.visible = false
	_set_hud_visible(true)
	event_banner.visible      = false

func update_hud(day: int, player: Node) -> void:
	label_day.text         = "Día %d / 30" % day
	label_vaccines.text    = "%d" % player.vaccine_inventory
	label_medications.text = "%d" % player.medicine_inventory

func update_economy(balance: float, inventory: int, remaining_debt: float) -> void:
	balance_label.text   = "$%s" % _format_cop(int(balance))
	inventory_label.text = "%d" % inventory
	debt_label.text      = "Deuda: $%s" % _format_cop(int(max(0.0, remaining_debt)))

	# Colorear la deuda según urgencia
	if remaining_debt <= 300_000:
		debt_label.add_theme_color_override("font_color", Color(0.247, 0.780, 0.373))
	elif remaining_debt <= 800_000:
		debt_label.add_theme_color_override("font_color", Color(0.961, 0.773, 0.259))
	else:
		debt_label.add_theme_color_override("font_color", Color(0.753, 0.224, 0.169))

func show_event_banner(message: String) -> void:
	event_banner_label.text = message
	event_banner.visible    = true
	await get_tree().create_timer(3.0).timeout
	event_banner.visible = false

func show_game_over(message: String = "GAME OVER") -> void:
	label_game_over.text    = message
	game_over_panel.visible = true

func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()

func _set_hud_visible(is_visible: bool) -> void:
	$HUD.visible = is_visible

func _format_cop(value: int) -> String:
	# Formatea con puntos de miles: 1500000 → "1.500.000"
	var string_val := str(abs(value))
	var output     := ""
	var count      := 0
	for i in range(string_val.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			output = "." + output
		output = string_val[i] + output
		count += 1
	return ("-" if value < 0 else "") + output
