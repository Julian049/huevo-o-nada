extends Area2D
class_name Hen

# =====================================================================
# HEN — VISUAL AGENT & DATA CONTAINER (PREPARED FOR MODEL 4)
# =====================================================================

enum State { HEALTHY, SICK, RECOVERED, DEAD }

var current_state : int = State.HEALTHY

# Atributos individuales — el Modelo 4 operará directamente sobre estos valores
var health     : float
var max_health : float
var age        : int   = 0
var dead       : bool = false

# Variables de movimiento
var direction : Vector2 = Vector2.ZERO
var speed     : float   = 80.0
var is_moving : bool    = false

func _ready() -> void:
	direction = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
	_update_visuals()

func _process(delta: float) -> void:
	if not is_moving:
		return
	position += direction * speed * delta
	_handle_screen_bounce()

# main.gd usa esta función para decirle a la gallina que se enfermó
func set_state(new_state: int) -> void:
	if current_state != new_state:
		current_state = new_state
		_update_visuals()

# Actualiza el color de la gallina según su estado
func _update_visuals() -> void:
	match current_state:
		State.HEALTHY:
			modulate = Color(1.0, 1.0, 1.0) # Blanco
		State.SICK:
			modulate = Color(0.0, 1.0, 0.0) # Verde
		State.RECOVERED:
			modulate = Color(0.0, 0.0, 1.0) # Azul
		State.DEAD:
			modulate = Color(1.0, 0.0, 0.0) # Rojo

func _handle_screen_bounce() -> void:
	if position.x < 20.0 or position.x > 1000.0: direction.x *= -1.0
	if position.y < 20.0 or position.y > 550.0: direction.y *= -1.0
