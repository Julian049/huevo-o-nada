extends CharacterBody2D

# =====================================================================
# PLAYER — STATE & INVENTORY
# =====================================================================

const SPEED : float = 200.0

var vaccine_inventory   : int   = 0
var medicine_inventory  : int   = 0

@onready var sprite = $AnimatedSprite2D

func _physics_process(_delta: float) -> void:
	# Movimiento del jugador (WASD o Flechas)
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = input_dir * SPEED
	
	if input_dir != Vector2.ZERO:
		# Priorizar el movimiento horizontal si se presionan en diagonal
		if abs(input_dir.x) > abs(input_dir.y): 
			sprite.play("walk_side")
			sprite.flip_h = input_dir.x < 0 # Voltea a la izquierda si es necesario
			
		# AQUÍ ESTÁ LA "S" O HACIA ABAJO: Y es mayor a 0
		elif input_dir.y > 0: 
			sprite.play("walk_front")
			
		# Si Y es menor a 0, va hacia arriba ("W")
		else: 
			sprite.play("walk_back")
	else:
		# Si no se presiona nada, se queda quieto
		sprite.play("idle_front")
		
	move_and_slide()
	
	# Limitar movimiento a los bordes de la pantalla
	position.x = clamp(position.x, 20.0, 1132.0)
	position.y = clamp(position.y, 80.0, 630.0)

# Consume una vacuna si hay en el inventario
func try_use_vaccine() -> bool:
	if vaccine_inventory > 0:
		vaccine_inventory -= 1
		return true
	return false

# Consume una medicina si hay en el inventario
func try_use_medicine() -> bool:
	if medicine_inventory > 0:
		medicine_inventory -= 1
		return true
	return false
