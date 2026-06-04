extends Area2D
class_name Hen

enum State { HEALTHY, SICK, RECOVERED, DEAD }

# Colores originales del equipo
const COLOR_SANA       := Color(0.961, 0.773, 0.259)   # amarillo/dorado
const COLOR_ENFERMA    := Color(0.478, 0.549, 0.416)   # verde oscuro
const COLOR_RECUPERADA := Color(0.400, 0.700, 1.000)   # AZUL (original del equipo)
const COLOR_MUERTA     := Color(0.290, 0.290, 0.290)   # gris

var current_state : int = State.HEALTHY
@onready var sprite = $AnimatedSprite2D

var health     : int
var max_health : float
var age        : int  = 0
var dead       : bool = false

var direction : Vector2 = Vector2.ZERO
var speed     : float   = 80.0
var is_moving : bool    = false

func _ready() -> void:
	direction = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
	_update_visuals()

func _process(delta: float) -> void:
	if current_state == State.DEAD:
		sprite.play("dead")
		return
	if not is_moving:
		sprite.play("idle_front")
		return
	position += direction * speed * delta
	_handle_screen_bounce()
	if abs(direction.x) > abs(direction.y):
		sprite.play("walk_side")
		sprite.flip_h = direction.x < 0
	elif direction.y > 0:
		sprite.play("walk_front")
	else:
		sprite.play("walk_back")

func set_state(new_state: int) -> void:
	if current_state != new_state:
		current_state = new_state
		_update_visuals()

func _update_visuals() -> void:
	match current_state:
		State.HEALTHY:
			modulate = COLOR_SANA
		State.SICK:
			modulate = COLOR_ENFERMA
		State.RECOVERED:
			modulate = COLOR_RECUPERADA
		State.DEAD:
			modulate = COLOR_MUERTA
			speed = 0.0
			is_moving = false

func _handle_screen_bounce() -> void:
	if position.x < -50.0 or position.x > 1050.0:
		direction.x *= -1.0
	if position.y < 45.0 or position.y > 310.0:
		direction.y *= -1.0
