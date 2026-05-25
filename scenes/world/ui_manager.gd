extends Node
# Se encarga exclusivamente de mostrar, ocultar y actualizar los textos en pantalla.

@onready var label_day: Label = $LabelDay
@onready var label_balance: Label = $LabelBalance
@onready var label_instruction: Label = $LabelInstruction
@onready var label_vaccines: Label = $LabelVaccines
@onready var label_medications: Label = $LabelMedications
@onready var label_game_over: Label = $LabelGameOver

# Prepara la interfaz antes de que el jugador presione ESPACIO
func setup_initial_ui() -> void:
	label_instruction.visible = true
	label_game_over.visible = false
	label_day.visible = false
	label_balance.visible = false
	label_vaccines.visible = false
	label_medications.visible = false

# Muestra el HUD principal una vez que arranca la simulación
func setup_running_ui() -> void:
	label_instruction.visible = false
	label_day.visible = true
	label_balance.visible = true
	label_vaccines.visible = true
	label_medications.visible = true

# Activa el cartel de fin de juego
func show_game_over() -> void:
	label_game_over.visible = true

# Refresca los textos en pantalla con los datos actuales del jugador y el día
func update_hud(day: int, player: Node) -> void:
	if label_day: label_day.text = "Day: " + str(day)
	if label_balance: label_balance.text = "Balance: $" + str(player.balance)
	if label_vaccines: label_vaccines.text = "Vacunas: " + str(player.vaccine_inventory)
	if label_medications: label_medications.text = "Medicinas: " + str(player.medicine_inventory)
