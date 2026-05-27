extends CharacterBody2D

# =====================================================================
# PLAYER — STATE & INVENTORY
# =====================================================================

const SPEED : float = 200.0

var vaccine_inventory   : int   = 0
var medicine_inventory  : int   = 0

func _physics_process(_delta: float) -> void:
	# Movimiento del jugador (WASD o Flechas)
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = input_dir * SPEED
	move_and_slide()
	
	# Limitar movimiento a los bordes de la pantalla
	position.x = clamp(position.x, 20.0, 1132.0)
	position.y = clamp(position.y, 20.0, 628.0)

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
