extends Node2D

# =====================================================================
# MAIN — GAME LOOP ORCHESTRATOR (MODELOS 3 Y 4 INTEGRADOS)
# =====================================================================

@onready var disease_model  : Node = $Model3Disease
@onready var survival_model : Node = $Model4Queues
@onready var player         : Node = $Player

@onready var label_day     : Label = $LabelDay
@onready var label_balance : Label = $LabelBalance
@onready var label_instruction  : Label = $LabelInstruction
@onready var label_vaccines  : Label = $LabelVaccines
@onready var label_medications  : Label = $LabelMedications
@onready var label_game_over  : Label = $LabelGameOver

var hen_scene : PackedScene = preload("res://scenes/entities/hen.tscn")

const MAX_DAYS : int = 30
const NUMBER_OF_HENS  : int   = 15
const GALPON_CAPACITY : int   = 30
const BATCH_SIZE : int = 3;

var active_hens : Array = []
var is_running  : bool  = false
var day : int = 0


# =====================================================================
# _READY — Inicialización de la escena
# =====================================================================
func _ready() -> void:
	#Inicializamos variables del modelo 3
	# disease_model.initialize_model(NUMBER_OF_HENS, 1.50, 0.05, GALPON_CAPACITY)
	
	#PARAMETROS MAS EXAGERADOS PARA HACER PRUEBAS
	disease_model.initialize_model(NUMBER_OF_HENS, 1.50, 0.5, GALPON_CAPACITY)
	
	# Inicializar el modelo de colas con la capacidad del galpón
	survival_model.initialize_model(GALPON_CAPACITY)

	# Conectar señal del Modelo 3
	disease_model.day_processed.connect(_on_day_processed)

	# Crear el lote inicial de gallinas delegando al Modelo 4
	_spawn_initial_batch(NUMBER_OF_HENS)

	# Marcar la gallina cero (paciente cero del brote)
	if active_hens.size() > 0:
		active_hens[0].set_state(1)  # State.SICK — paciente cero
		
	player.set_physics_process(false)
	player.set_process(false)

	if label_instruction: label_instruction.visible = true
	if label_game_over:   label_game_over.visible = false
	if label_day:         label_day.visible = false
	if label_balance:     label_balance.visible = false
	if label_vaccines:    label_vaccines.visible = false
	if label_medications: label_medications.visible = false


# =====================================================================
# INPUT — Avance manual de día con ESPACIO
# =====================================================================
func _unhandled_input(event: InputEvent) -> void:
	if not is_running and event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		_start_game()
		return
		
	# Si el juego aún no inicia, bloqueamos las demás acciones (1, 2, 3)
	if not is_running:
		return
	
	# 1 — Compra vacunas
	if event is InputEventKey and event.pressed and event.keycode == KEY_1:
		if player.buy_item(50.0, true): 
			_update_ui() 

	# 2 — Compra medicamentos 
	if event is InputEventKey and event.pressed and event.keycode == KEY_2:
		if player.buy_item(30.0, false):
			_update_ui()

	# 3 — Avanza un dia
	if event is InputEventKey and event.pressed and event.keycode == KEY_3:
		_advance_day()
		
	if event is InputEventKey and event.pressed and event.keycode == KEY_4:
		spawn_purchased_batch(BATCH_SIZE)


func _start_game() -> void:
	is_running = true
	
	# 1. Despertar a todas las gallinas vivas
	for hen in active_hens:
		if not hen.dead: # Solo movemos a las que estén vivas
			hen.is_moving = true
			
	# 2. Desbloquear el movimiento del jugador
	player.set_physics_process(true)
	player.set_process(true)
	
	if label_instruction: label_instruction.visible = false
	if label_day:         label_day.visible = true
	if label_balance:     label_balance.visible = true
	if label_vaccines:    label_vaccines.visible = true
	if label_medications: label_medications.visible = true


# =====================================================================
# _ADVANCE_DAY — Dispara el tick del Modelo 3 (que luego llama al 4)
# =====================================================================
func _advance_day() -> void:
	var used_vaccine  : bool = player.try_use_vaccine()
	var used_medicine : bool = player.try_use_medicine()
	disease_model.process_next_day(used_vaccine, used_medicine)


# =====================================================================
# _ON_DAY_PROCESSED — Callback del Modelo 3; aquí se coordina todo
# =====================================================================
func _on_day_processed(report: Dictionary) -> void:
	# --- Paso 1: Reflejar contagios y curaciones del Modelo 3 en escena ---
	_apply_state_changes(report["nuevos_contagiados"], report["nuevas_curadas"])

	# --- Paso 2: Modelo 4 procesa la cola de supervivencia ---
	# penalidad_vida viene del Modelo 3:
	#   0.0 si hay medicamentos activos, 2.0 si la gallina está enferma sin medicina	
	active_hens = survival_model.process_survival_queue(active_hens)

	# --- Paso 3: Procesar bajas reportadas por el Modelo 4 ---
	_notify_deads()

	day = int(report["day"])

	# --- Paso 4: Actualizar HUD ---
	_update_ui()
	if label_day:
		label_day.text = "Day: " + str(day)

	_validate_game_over()

	# --- Paso 5: Log de depuración ---
	_print_debug_state(day)


func _notify_deads() -> void:
	for hen in active_hens:
		if hen.health <= 0 and not hen.dead:
			disease_model.report_chicken_death(hen.current_state)
			hen.dead = true
			
func _validate_game_over() -> void:
	if day == MAX_DAYS or _are_all_hens_dead():
		if label_game_over:   label_game_over.visible = true
		
		is_running = false
		
		for hen in active_hens:
			if not hen.dead:
				hen.is_moving = false
				
		player.set_physics_process(false)
		player.set_process(false)

func _are_all_hens_dead() -> bool:
	if active_hens.is_empty():
		return false
		
	for hen in active_hens:
		if not hen.dead:
			return false
			
	return true 
# =====================================================================
# _SPAWN_INITIAL_BATCH
# Instancia las gallinas y las registra en el Modelo 4 (arrive_batch).
# Al separar creación de inicialización, cualquier lote futuro
# (compra del jugador) reutiliza el mismo flujo.
# =====================================================================
func _spawn_initial_batch(count: int) -> void:
	var new_hens : Array = []
	for i in range(count):
		var hen = hen_scene.instantiate()
		hen.position = Vector2(randf_range(100.0, 900.0), randf_range(100.0, 500.0))
		add_child(hen)
		new_hens.append(hen)

	var added : int = survival_model.arrive_batch(new_hens, active_hens)

	# Activar movimiento en las gallinas que sí entraron
	for i in range(added):
		new_hens[i].is_moving = is_running

	# Eliminar de escena las gallinas que no cupieron en el galpón
	for i in range(added, new_hens.size()):
		new_hens[i].queue_free()


# =====================================================================
# _SPAWN_PURCHASED_BATCH
# Punto de entrada para que el jugador compre gallinas nuevas.
# Parámetros:
#   count     — cantidad solicitada
# Retorna: cuántas gallinas ingresaron realmente (puede ser < count)
# =====================================================================
func spawn_purchased_batch(count: int) -> int:
	var new_hens : Array = []
	for i in range(count):
		var hen = hen_scene.instantiate()
		hen.position = Vector2(randf_range(100.0, 900.0), randf_range(100.0, 500.0))
		add_child(hen)
		new_hens.append(hen)

	var added : int = survival_model.arrive_batch(new_hens, active_hens)

	# Activar movimiento en las gallinas que sí entraron
	for i in range(added):
		new_hens[i].is_moving = is_running

	for i in range(added, new_hens.size()):
		new_hens[i].queue_free()
		
	disease_model.total_population += count
	print("Modelo 3 actualizado:" + str(disease_model.total_population))
	print("Gallinas vivas:" + str(active_hens.size()))

	return added


# =====================================================================
# _APPLY_STATE_CHANGES — Refleja en nodos lo que el Modelo 3 calculó
# =====================================================================
func _apply_state_changes(new_sick: int, new_recovered: int) -> void:
	for _i in range(new_sick):
		var healthy : Array = active_hens.filter(func(h): return h.current_state == 0)
		if healthy.size() > 0:
			healthy.pick_random().set_state(1)

	for _i in range(new_recovered):
		var sick : Array = active_hens.filter(func(h): return h.current_state == 1)
		if sick.size() > 0:
			sick.pick_random().set_state(2)


# =====================================================================
# _UPDATE_UI — Refresca etiquetas del HUD
# =====================================================================
func _update_ui() -> void:
	if label_balance:
		label_balance.text = "Balance: $" + str(player.balance)
	if label_vaccines:
		label_vaccines.text = "Vacunas: " + str(player.vaccine_inventory)
	if label_medications:
		label_medications.text = "Medicinas: " + str(player.medicine_inventory)


# =====================================================================
# _PRINT_DEBUG_STATE — Log de consola por día
# =====================================================================
func _print_debug_state(day: int) -> void:
	print("\n---------- ESTADO DE GALLINAS — Día %d ----------" % day)
	var state_names = ["SANA", "ENFERMA", "RECUPERADA", "MUERTA"]
	
	for i in range(active_hens.size()):
		var hen = active_hens[i]
		var state_text = state_names[hen.current_state]
	
		print("  Gallina %02d | Vida: %5.1f / %5.1f | Estado: %s" % [i, hen.health, hen.max_health, state_text])
	print(
		"\n  [Modelo 4] edad⌀=%.1f | vida_rest⌀=%.1f | muertes previstas (3 días)=%d"
		% [
			survival_model.get_average_age(active_hens),
			survival_model.get_average_remaining_life(active_hens),
			survival_model.forecast_deaths(active_hens, 3)
		]
	)
	print("-------------------------------------------------\n")
