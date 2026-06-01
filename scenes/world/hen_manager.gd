extends Node2D
# Controla la creación, estado, movimiento y muerte de todas las gallinas en escena.

var hen_scene: PackedScene = preload("res://scenes/entities/hen.tscn")
var active_hens: Array = []

# Genera el lote inicial al abrir el juego y define al paciente cero
func spawn_initial_batch(count: int, survival_model: Node, is_running: bool) -> void:
	var new_hens: Array = []
	for i in range(count):
		var hen = hen_scene.instantiate()
		hen.position = Vector2(randf_range(0.0, 1000.0), randf_range(50.0, 300.0))
		add_child(hen)
		new_hens.append(hen)

	var added: int = survival_model.arrive_batch(new_hens, active_hens)

	for i in range(added):
		new_hens[i].is_moving = is_running

	# Elimina de la escena las gallinas que exceden la capacidad del galpón
	for i in range(added, new_hens.size()):
		new_hens[i].queue_free()

	# Infecta a la primera gallina (paciente cero)
	if active_hens.size() > 0:
		active_hens[0].set_state(1)

# Añade nuevas gallinas compradas por el jugador durante la partida
func spawn_purchased_batch(count: int, survival_model: Node, disease_model: Node, is_running: bool) -> int:
	var new_hens: Array = []
	for i in range(count):
		var hen = hen_scene.instantiate()
		hen.position = Vector2(randf_range(0.0, 1000.0), randf_range(50.0, 300.0))
		add_child(hen)
		new_hens.append(hen)

	var added: int = survival_model.arrive_batch(new_hens, active_hens)

	for i in range(added):
		new_hens[i].is_moving = is_running

	for i in range(added, new_hens.size()):
		new_hens[i].queue_free()
		
	disease_model.total_population += count
	return added

# Aplica los contagios y curaciones calculados por el Modelo 3
func apply_state_changes(new_sick: int, new_recovered: int) -> void:
	for _i in range(new_sick):
		var healthy: Array = active_hens.filter(func(h): return h.current_state == 0)
		if healthy.size() > 0: healthy.pick_random().set_state(1)

	for _i in range(new_recovered):
		var sick: Array = active_hens.filter(func(h): return h.current_state == 1)
		if sick.size() > 0: sick.pick_random().set_state(2)

# Actualiza la lista de gallinas vivas usando el cálculo del Modelo 4
func process_survival(survival_model: Node) -> void:
	active_hens = survival_model.process_survival_queue(active_hens)

# Marca como muertas a las gallinas sin vida y reporta la baja al Modelo 3
func notify_deads(disease_model: Node) -> void:
	for hen in active_hens:
		if hen.health <= 0 and not hen.dead:
			disease_model.report_chicken_death(hen.current_state)
			hen.dead = true

# Comprueba si el galpón se quedó completamente sin gallinas vivas
func are_all_hens_dead() -> bool:
	if active_hens.is_empty(): return false
	for hen in active_hens:
		if not hen.dead: return false
	return true

# Pausa o reanuda el movimiento de todas las gallinas vivas
func set_hens_moving(moving: bool) -> void:
	for hen in active_hens:
		if not hen.dead:
			hen.is_moving = moving
