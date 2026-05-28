extends Node2D
# Actúa como director: escucha el teclado y coordina a los managers y modelos.

@onready var disease_model  : Node = $Model3Disease
@onready var survival_model : Node = $Model4Queues
@onready var player         : Node = $Player
@onready var ui_manager     : Node = $UIManager
@onready var hen_manager    : Node = $HenManager

const MAX_DAYS : int = 30
const NUMBER_OF_HENS  : int = 3
const GALPON_CAPACITY : int = 30
const BATCH_SIZE : int = 3

var is_running  : bool = false
var day : int = 0

# Inicializa modelos, crea las gallinas y prepara la interfaz
func _ready() -> void:
	disease_model.initialize_model(NUMBER_OF_HENS, GALPON_CAPACITY)
	survival_model.initialize_model(GALPON_CAPACITY)
	disease_model.day_processed.connect(_on_day_processed)

	hen_manager.spawn_initial_batch(NUMBER_OF_HENS, survival_model, is_running)

	# Bloquea al jugador hasta que inicie el juego
	player.set_physics_process(false)
	player.set_process(false)
	ui_manager.setup_initial_ui()

# Captura los inputs del jugador (iniciar, comprar, avanzar día)
func _unhandled_input(event: InputEvent) -> void:
	# Arranca el juego con ESPACIO
	if not is_running and event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		_start_game()
		return
		
	if not is_running: return
	
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1: # Compra vacunas
				if player.buy_item(50.0, true): ui_manager.update_hud(day, player)
			KEY_2: # Compra medicinas
				if player.buy_item(30.0, false): ui_manager.update_hud(day, player)
			KEY_3: # Avanza un día
				_advance_day()
			KEY_4: # Compra un nuevo lote de gallinas
				hen_manager.spawn_purchased_batch(BATCH_SIZE, survival_model, disease_model, is_running)

# Desbloquea el movimiento general y actualiza la interfaz para jugar
func _start_game() -> void:
	is_running = true
	hen_manager.set_hens_moving(true)
	player.set_physics_process(true)
	player.set_process(true)
	ui_manager.setup_running_ui()
	ui_manager.update_hud(day, player)

# Dispara el tick diario enviando el estado de vacunas/medicinas al modelo
func _advance_day() -> void:
	var used_vaccine  : bool = player.try_use_vaccine()
	var used_medicine : bool = player.try_use_medicine()
	disease_model.process_next_day(used_vaccine, used_medicine)

# Callback ejecutado cuando el Modelo 3 termina de calcular un día
func _on_day_processed(report: Dictionary) -> void:
	# Coordina las actualizaciones en cascada
	hen_manager.apply_state_changes(report["nuevos_contagiados"], report["nuevas_curadas"])
	hen_manager.process_survival(survival_model)
	hen_manager.notify_deads(disease_model)

	day = int(report["day"])
	ui_manager.update_hud(day, player)
	
	_validate_game_over()
	_print_debug_state(day)

# Verifica si se alcanzó el límite de días o si murieron todas las gallinas
func _validate_game_over() -> void:
	if day >= MAX_DAYS or hen_manager.are_all_hens_dead():
		is_running = false
		ui_manager.show_game_over()
		hen_manager.set_hens_moving(false)
		player.set_physics_process(false)
		player.set_process(false)

# Imprime un log en consola para monitorear las variables internamente
func _print_debug_state(current_day: int) -> void:
	print("\n---------- ESTADO DE GALLINAS — Día %d ----------" % current_day)
	print("-------------------------------------------------\n")
