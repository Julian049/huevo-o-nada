extends Node

const MU_BASE : float = 25.0
const SIGMA_BASE : float = 2.0
const VACCINE_BONUS : float = 5.0
const PENALTY_SICK : float = 2.0
const DAILY_WEAR : float = 1.0

var capacity_k : int

signal hen_died(hen_node: Node, was_sick: bool)

# Establece el límite máximo de gallinas en el galpón
func initialize_model(max_capacity: int) -> void:
	capacity_k = max_capacity

# Calcula y asigna el tiempo de vida (salud) al instanciar una gallina
func initialize_hen(hen: Node, is_vaccinated: bool) -> void:
	var zi : float = _generate_standard_normal()
	var mu : float = MU_BASE + (VACCINE_BONUS if is_vaccinated else 0.0)
	var xi : float = mu + SIGMA_BASE * zi

	# Evita que la gallina muera instantáneamente al nacer
	xi = max(xi, 1.0)

	hen.max_health = xi
	hen.health = xi
	hen.age = 0

# Ingresa un nuevo grupo de gallinas respetando el cupo disponible
func arrive_batch(hens_to_add: Array, active_hens: Array) -> int:
	var space_available : int = capacity_k - active_hens.size()
	var to_add : int = min(hens_to_add.size(), space_available)

	for i in range(to_add):
		var hen : Node = hens_to_add[i]
		initialize_hen(hen, false)
		active_hens.append(hen)

	return to_add

# Aplica desgaste y penalidades por salud a cada gallina viva
func process_survival_queue(active_hens: Array) -> Array:
	var new_hens : Array = []

	for hen in active_hens:
		if hen.current_state == 3: 
			continue

		var was_sick : bool = (hen.current_state == 1)

		hen.age += 1
		hen.health -= DAILY_WEAR

		if was_sick:
			hen.health -= PENALTY_SICK
			
		print("Gallina: ", hen.name, " | Edad: ", hen.age, " | Salud: ", hen.health, "/", hen.max_health)

		# Marca a la gallina como muerta si se queda sin salud o alcanza su edad límite
		if hen.health <= 0.0 or hen.age >= int(hen.max_health):
			hen.health = 0.0
			hen.set_state(3)
			hen.is_moving = false
			hen_died.emit(hen, was_sick)
			
		new_hens.append(hen)

	return new_hens

# Retorna la edad promedio de las gallinas actualmente vivas
func get_average_age(active_hens: Array) -> float:
	if active_hens.is_empty(): return 0.0
	var total : float = 0.0
	for hen in active_hens: total += hen.age
	return total / active_hens.size()

# Retorna cuánta vida les queda en promedio a las gallinas vivas
func get_average_remaining_life(active_hens: Array) -> float:
	if active_hens.is_empty(): return 0.0
	var total : float = 0.0
	for hen in active_hens: total += hen.health
	return total / active_hens.size()

# Estima cuántas gallinas morirán por desgaste natural en un plazo de días
func forecast_deaths(active_hens: Array, days_ahead: int) -> int:
	var count : int = 0
	for hen in active_hens:
		if hen.current_state == 3: continue
		if hen.health <= float(days_ahead): count += 1
	return count

# Genera un número aleatorio con distribución normal usando el método Box-Muller
func _generate_standard_normal() -> float:
	var u1 : float = max(randf(), 0.0001)
	var u2 : float = randf()
	return sqrt(-2.0 * log(u1)) * cos(2.0 * PI * u2)
