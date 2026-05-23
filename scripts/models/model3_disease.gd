extends Node

# =====================================================================
# MODEL 3 — SYSTEM DYNAMICS (SIN MORTALIDAD MATEMÁTICA)
# =====================================================================

signal day_processed(report: Dictionary)

var base_contagiousness : float
var base_recovery_rate  : float
var max_capacity        : float

var total_population : int
var susceptible      : int
var infected         : int
var current_day      : int

# Acumuladores exclusivos para flujos vivos
var acum_infections : float
var acum_recoveries : float

var penalty_health_base : float = 2.0 

func initialize_model(p_total_pop: int, p_contagiousness: float, p_recovery: float, p_capacity: float) -> void:
	total_population = p_total_pop
	infected = 1
	susceptible = p_total_pop - 1
	
	base_contagiousness = p_contagiousness
	base_recovery_rate = p_recovery
	max_capacity = p_capacity
	
	current_day = 0
	acum_infections = 0.0
	acum_recoveries = 0.0

func process_next_day(used_vaccine: bool, used_medicine: bool) -> void:
	if total_population <= 0:
		return
	var crowding_factor : float = float(total_population) / max_capacity
	var effective_beta  : float = base_contagiousness * 0.15 if used_vaccine else base_contagiousness
	var effective_gamma : float = base_recovery_rate + 0.70 if used_medicine else base_recovery_rate
	
	# Flujos restringidos a S (Susceptibles) e I (Infectados)
	var flow_infections : float = effective_beta * crowding_factor * float(infected) * (float(susceptible) / float(total_population))
	var flow_recoveries : float = effective_gamma * float(infected)
	
	acum_infections += flow_infections
	acum_recoveries += flow_recoveries
	
	var new_infections : int = int(floor(acum_infections))
	var new_recoveries : int = int(floor(acum_recoveries))
	
	acum_infections -= new_infections
	acum_recoveries -= new_recoveries
		
	if new_infections > susceptible:
		new_infections = susceptible
	if new_recoveries > infected:
		new_recoveries = infected
	
	infected = infected + new_infections - new_recoveries
	susceptible = susceptible - new_infections + new_recoveries

	infected = clampi(infected, 0, total_population)
	susceptible = maxi(total_population - infected, 0)
	current_day += 1
	
	var current_health_penalty = 0.0 if used_medicine else penalty_health_base
	
	var data = {
		"day": current_day,
		"S": susceptible,
		"I": infected,
		"N": total_population,
		"nuevos_contagiados": new_infections,
		"nuevas_curadas": new_recoveries,
		"penalidad_vida": current_health_penalty
	}
	
	# =========================================================
	# PRINT DETALLADO DE DEPURACIÓN (DEBUG)
	# =========================================================
	print("\n================== REPORTE DÍA %d ==================" % current_day)
	print("POBLACIÓN ACTUAL : %d gallinas | Sanas (S): %d | Enfermas (I): %d" % [total_population, susceptible, infected])
	print("FLUJO MATEMÁTICO : Contagios: +%.3f | Curaciones: +%.3f" % [flow_infections, flow_recoveries])
	print("ACCIONES HOY     : %d se contagiaron | %d se curaron" % [new_infections, new_recoveries])
	print("DECIMAL SOBRANTE : Para contagio: %.3f | Para curación: %.3f" % [acum_infections, acum_recoveries])
	print("PENALIDAD A VIDA : -%.1f puntos de vida extra por enfermedad" % current_health_penalty)
	print("====================================================\n")
	
	day_processed.emit(data)

# Hook externo: Recibe la señal de muerte física dictada por el Main / Modelo 4
func report_chicken_death(state: Hen.State) -> void:
	if total_population <= 0: return
	
	total_population -= 1
	if state == Hen.State.SICK:
		infected = maxi(infected - 1, 0)
	elif state == Hen.State.HEALTHY:
		susceptible = maxi(susceptible - 1, 0)
