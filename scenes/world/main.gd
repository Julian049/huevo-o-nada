extends Node2D
# Director: coordina managers, modelos y entradas del jugador.

@onready var disease_model  : Node = $Model3Disease
@onready var survival_model : Node = $Model4Queues
@onready var player         : Node = $Player
@onready var ui_manager     : Node = $UIManager
@onready var hen_manager    : Node = $HenManager
@onready var model5_economy : Node = $Model5Economy
@onready var model2_abm     : Node = $Model2ABM

const MAX_DAYS        : int = 30
const NUMBER_OF_HENS  : int = 3
const GALPON_CAPACITY : int = 30
const BATCH_SIZE      : int = 3

var is_running : bool = false
var day        : int  = 0

func _ready() -> void:
	disease_model.initialize_model(NUMBER_OF_HENS, GALPON_CAPACITY)
	survival_model.initialize_model(GALPON_CAPACITY)
	disease_model.day_processed.connect(_on_day_processed)

	hen_manager.spawn_initial_batch(NUMBER_OF_HENS, survival_model, is_running)

	# Modelo 2 — Roedores
	model2_abm.initialize()

	# Modelo 5 — Economía
	model5_economy.initialize()
	model5_economy.comprador_llego.connect(_on_comprador_llego)
	model5_economy.precio_actualizado.connect(_on_precio_actualizado)
	model5_economy.costo_maiz_actualizado.connect(_on_costo_maiz_actualizado)
	model5_economy.banquero_visito.connect(_on_banquero_visito)
	model5_economy.inspeccion_ocurrio.connect(_on_inspeccion_ocurrio)
	model5_economy.inspeccion_superada.connect(_on_inspeccion_superada)
	model5_economy.oferta_vacunas_disponible.connect(_on_oferta_vacunas_disponible)
	model5_economy.vecino_vendio.connect(_on_vecino_vendio)
	model5_economy.balance_actualizado.connect(_on_balance_actualizado)
	model5_economy.game_over.connect(_on_economy_game_over)

	# Señal de roedores para el banner
	model2_abm.rodents_processed.connect(_on_rodents_processed)

	player.set_physics_process(false)
	player.set_process(false)
	ui_manager.setup_initial_ui()

func _unhandled_input(event: InputEvent) -> void:
	if not is_running and event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		_start_game()
		return

	if not is_running: return

	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:  # Vacuna ($15.000)
				if model5_economy.comprar_item(15000.0):
					player.vaccine_inventory += 1
					ui_manager.update_hud(day, player)
			KEY_2:  # Medicina ($8.000)
				if model5_economy.comprar_item(8000.0):
					player.medicine_inventory += 1
					ui_manager.update_hud(day, player)
			KEY_3:  # Avanzar día
				_advance_day()
			KEY_4:  # Comprar 3 gallinas ($75.000)
				if model5_economy.comprar_item(75000.0):
					hen_manager.spawn_purchased_batch(BATCH_SIZE, survival_model, disease_model, is_running)
			KEY_5:  # Colocar trampa para roedores ($20.000)
				if model5_economy.comprar_item(20000.0):
					model2_abm.colocar_trampa()
					ui_manager.show_event_banner("🪤 Trampa colocada ($20.000)")

func _start_game() -> void:
	is_running = true
	hen_manager.set_hens_moving(true)
	player.set_physics_process(true)
	player.set_process(true)
	ui_manager.setup_running_ui()
	ui_manager.update_hud(day, player)
	ui_manager.update_economy(
		model5_economy.balance_caja,
		model5_economy.inventario_huevos,
		model5_economy.DEUDA_TOTAL - model5_economy.acumulado_ventas
	)

func _advance_day() -> void:
	var used_vaccine  : bool = player.try_use_vaccine()
	var used_medicine : bool = player.try_use_medicine()
	disease_model.process_next_day(used_vaccine, used_medicine)

func _on_day_processed(report: Dictionary) -> void:
	hen_manager.apply_state_changes(report["nuevos_contagiados"], report["nuevas_curadas"])
	hen_manager.process_survival(survival_model)
	hen_manager.notify_deads(disease_model)

	day = int(report["day"])
	ui_manager.update_hud(day, player)

	# Modelo 2 — roedores: calcular robos del día
	var produccion : int = _calcular_produccion()
	var robos      : int = model2_abm.simulate_turn(produccion, day)
	ui_manager.update_rodents(model2_abm._contar_vivos(), model2_abm.trampas.size())

	# Modelo 5 — economía
	model5_economy.process_day(
		day,
		hen_manager.active_hens.size(),
		produccion,
		robos,
		disease_model.infected
	)

	_validate_game_over()
	_print_debug_state(day)

func _calcular_produccion() -> int:
	var total := 0
	for gallina in hen_manager.active_hens:
		if gallina.current_state == 0:
			if randf() < model5_economy.TASA_POSTURA:
				total += 1
	return total

# ── CALLBACKS ECONOMÍA ────────────────────────────────────────

func _on_comprador_llego(ingreso: float) -> void:
	ui_manager.show_event_banner("🛒 Venta: $" + str(int(ingreso)))

func _on_precio_actualizado(nuevo_precio: int) -> void:
	ui_manager.show_event_banner("📈 Precio huevo: $" + str(nuevo_precio))

func _on_costo_maiz_actualizado(nuevo_costo: int) -> void:
	ui_manager.show_event_banner("🌽 Costo alimento: $" + str(nuevo_costo))

func _on_banquero_visito(deuda_restante: float) -> void:
	ui_manager.show_event_banner("🏦 Banquero — Deuda: $" + str(int(deuda_restante)))

func _on_inspeccion_ocurrio(multa: float) -> void:
	ui_manager.show_event_banner("🚨 Multa: $" + str(int(multa)))

func _on_inspeccion_superada() -> void:
	ui_manager.show_event_banner("✅ Inspección superada")

func _on_oferta_vacunas_disponible() -> void:
	ui_manager.show_event_banner("💊 ¡Vacunas con 40% descuento! [1]")

func _on_vecino_vendio(nuevo_precio: int) -> void:
	ui_manager.show_event_banner("😤 Vecino vendió primero — precio baja a $" + str(nuevo_precio))

func _on_balance_actualizado(nuevo_balance: float, acumulado: float) -> void:
	ui_manager.update_economy(nuevo_balance, model5_economy.inventario_huevos,
		model5_economy.DEUDA_TOTAL - acumulado)

func _on_rodents_processed(report: Dictionary) -> void:
	if report["colonia_critica"]:
		ui_manager.show_event_banner("🐀 ¡Colonia crítica! " + str(report["roedores_vivos"]) + " roedores. [5] trampa")
	elif report["huevos_robados"] > 0:
		ui_manager.show_event_banner("🐀 Roedores robaron " + str(report["huevos_robados"]) + " huevo(s)")

func _on_economy_game_over(tipo: String) -> void:
	is_running = false
	hen_manager.set_hens_moving(false)
	player.set_physics_process(false)
	player.set_process(false)
	match tipo:
		"BANCARROTA": ui_manager.show_game_over("¡Bancarrota! Te quedaste sin dinero.")
		"VICTORIA":   ui_manager.show_game_over("¡Granja salvada! Deuda pagada.")
		"EMBARGO":    ui_manager.show_game_over("El banquero ejecutó el embargo.")

func _validate_game_over() -> void:
	if hen_manager.are_all_hens_dead() and is_running:
		is_running = false
		ui_manager.show_game_over("¡Todas tus gallinas murieron!")
		hen_manager.set_hens_moving(false)
		player.set_physics_process(false)
		player.set_process(false)

func _print_debug_state(current_day: int) -> void:
	print("\n---------- ESTADO — Día %d ----------" % current_day)
	print("Roedores: %d | Trampas: %d" % [model2_abm._contar_vivos(), model2_abm.trampas.size()])
	print("--------------------------------------\n")
