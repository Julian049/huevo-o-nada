extends Node

signal day_processed(report: Dictionary)

var base_contagiousness      : float
var base_recovery_rate       : float
var max_capacity             : float
var crowding_sensitivity     : float
var environmental_viral_load : float

var total_population : int
var infected         : int
var current_day      : int

var acum_infections : float
var acum_recoveries : float
var acum_inflows    : float
var acum_outflows   : float

var penalty_health_base : float = 2.0

func initialize_model(p_total_pop: int, p_capacity: float) -> void:
	total_population = p_total_pop
	infected         = 1

	base_contagiousness  = 3
	crowding_sensitivity = 0.35
	base_recovery_rate   = 0.05
	max_capacity         = p_capacity

	current_day      = 0
	acum_infections  = 0.0
	# ── FIX: arranque para que la paciente cero pueda sanar ──
	# Con gamma=0.05 e infected=1 el flujo diario es 0.05, necesitamos
	# acumular 1.0 para que floor() dé 1 → tarda 20 días sin medicina.
	# Le damos 0.0 de arranque (correcto matemáticamente) pero documentamos
	# el comportamiento esperado: sin medicinas la primera gallina tarda ~20 días.
	# CON medicina gamma sube a 0.75 → se cura en 1-2 días (correcto).
	acum_recoveries  = 0.0
	acum_outflows    = 0.0

func process_next_day(used_vaccine: bool, used_medicine: bool) -> void:
	if total_population <= 0: return

	var susceptible     : int   = maxi(total_population - infected, 0)
	var crowding_factor : float = float(total_population) / max_capacity

	environmental_viral_load += (crowding_factor * 0.05)

	if used_vaccine:
		environmental_viral_load = maxf(0.0, environmental_viral_load - 0.15)
	var effective_beta  : float = base_contagiousness * 0.15 if used_vaccine else base_contagiousness
	var effective_gamma : float = base_recovery_rate + 0.70  if used_medicine else base_recovery_rate

	var flow_direct      : float = effective_beta * crowding_factor * float(infected) * (float(susceptible) / float(total_population))
	var flow_env         : float = environmental_viral_load * float(susceptible) * 0.10
	var flow_recoveries  : float = effective_gamma * float(infected)

	acum_inflows  += flow_direct + flow_env
	acum_outflows += flow_recoveries

	var new_infections : int = int(floor(acum_inflows))
	var new_recoveries : int = int(floor(acum_outflows))

	acum_inflows  -= new_infections
	acum_outflows -= new_recoveries

	if new_infections > susceptible: new_infections = susceptible
	if new_recoveries > infected:    new_recoveries = infected

	infected    = clampi(infected + new_infections - new_recoveries, 0, total_population)
	susceptible = maxi(total_population - infected, 0)
	current_day += 1

	var current_health_penalty : float = 0.0 if used_medicine else penalty_health_base

	var data := {
		"day": current_day,
		"S": susceptible,
		"I": infected,
		"N": total_population,
		"carga_viral_ambiental":      environmental_viral_load,
		"flujo_contagio_directo":     flow_direct,
		"flujo_contagio_ambiental":   flow_env,
		"flujo_recuperacion":         flow_recoveries,
		"nuevos_contagiados":         new_infections,
		"nuevas_curadas":             new_recoveries,
		"penalidad_vida":             current_health_penalty
	}

	print("\n--- REPORTE DÍA %d ---" % current_day)
	print("Población: %d | Sanas: %d | Enfermas: %d" % [total_population, susceptible, infected])
	print("Nuevos contagios: %d | Recuperaciones: %d" % [new_infections, new_recoveries])
	print("Carga Viral Ambiental: %.2f" % environmental_viral_load)

	day_processed.emit(data)

func report_chicken_death(state: Hen.State) -> void:
	if total_population <= 0: return
	total_population -= 1
	if state == Hen.State.SICK:
		infected = maxi(infected - 1, 0)
