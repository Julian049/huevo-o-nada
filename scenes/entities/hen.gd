extends Area2D
class_name Hen

# =====================================================================
# HEN — VISUAL AGENT & DATA CONTAINER (PREPARED FOR MODEL 4)
# =====================================================================

enum State { HEALTHY, SICK, RECOVERED, DEAD }

var current_state : int = State.HEALTHY
@onready var sprite = $AnimatedSprite2D

# Atributos individuales — el Modelo 4 operará directamente sobre estos valores
var health     : int
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
	# Si no se está moviendo o está muerta, reproducir animación quieta y salir
	if not is_moving or current_state == State.DEAD:
		sprite.play("idle_front")
		return
		
	# Aplicar movimiento
	position += direction * speed * delta
	_handle_screen_bounce()
	
	if abs(direction.x) > abs(direction.y):
		sprite.play("walk_side")
		sprite.flip_h = direction.x < 0
	elif direction.y > 0:
		sprite.play("walk_front")
	else:
		sprite.play("walk_back")

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
