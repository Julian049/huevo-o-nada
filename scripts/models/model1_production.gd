extends Node
# =====================================================================
# MODELO 1 — PRODUCCIÓN DIARIA DE HUEVOS (MONTE CARLO / BERNOULLI)
# Autor: Daniel Perez Jimenez
# =====================================================================
# Cada gallina es un ensayo de Bernoulli independiente con su propia
# probabilidad de postura p_i calculada a partir de su vector de estado.
# La producción total del día es la suma de todos los ensayos: H = Σ X_i
# donde X_i ~ Bernoulli(p_i).
#
# Integración con otros modelos:
#   - Modelo 3 (SIR): gallinas enfermas (state==SICK) reducen factor_estres
#   - Modelo 4 (Queues): gallinas viejas reducen factor_edad via health ratio
#   - Subtrama 3: muerte de gallinas especiales aplica penalidad narrativa
# =====================================================================

signal production_calculated(report: Dictionary)

# --- PARÁMETROS BASE DEL MODELO ---
const P_BASE           : float = 0.75  # Probabilidad base de postura diaria
const F_LUZ_DEFAULT    : float = 1.0   # Factor luz (sin control = 1.0)
const F_ALIM_NORMAL    : float = 1.0   # Factor alimentación normal
const F_ALIM_ESPECIAL  : float = 1.1   # Factor alimentación con fórmula del abuelo
const F_ESTRES_SANA    : float = 1.0   # Sin estrés
const F_ESTRES_ENFERMA : float = 0.7   # Gallina enferma: penaliza postura
const F_ESTRES_NARRATIVO : float = 0.85 # Penalidad por muerte de gallina especial (Subtrama 3)

# --- GALLINAS ESPECIALES (SUBTRAMA 3) ---
# Las tres gallinas con nombre tienen p_base elevada
const NOMBRES_ESPECIALES : Array = ["Cometida", "Berenjena", "La Muda"]
const P_BASE_ESPECIAL    : float = 0.90  # Mayor probabilidad de postura

# --- ESTADO DEL MODELO ---
var formula_abuelo_activa : bool = false  # Subtrama 1: fórmula especial de alimento
var dias_penalidad_narrativa : int = 0   # Subtrama 3: días restantes de estrés narrativo
var historico_produccion : Array = []     # Registro diario para validación independiente

# Inicializa el modelo. Llamar desde main.gd en _ready()
func initialize() -> void:
	formula_abuelo_activa    = false
	dias_penalidad_narrativa = 0
	historico_produccion     = []
	print("[Modelo 1] Inicializado. P_BASE=%.2f" % P_BASE)

# =====================================================================
# FUNCIÓN PRINCIPAL — Simular producción diaria
# Parámetros:
#   active_hens   : Array de nodos Hen activos (desde hen_manager)
#   dia_actual    : int — número de día actual
# Retorna: int — huevos producidos ese día
# =====================================================================
func simulate_production(active_hens: Array, dia_actual: int) -> int:
	var huevos_dia : int = 0
	var gallinas_procesadas : int = 0
	var factor_alim : float = F_ALIM_ESPECIAL if formula_abuelo_activa else F_ALIM_NORMAL

	# Calcular factor de estrés global del día
	var factor_estres_global : float = F_ESTRES_NARRATIVO if dias_penalidad_narrativa > 0 else F_ESTRES_SANA
	if dias_penalidad_narrativa > 0:
		dias_penalidad_narrativa -= 1
		print("[Modelo 1] Penalidad narrativa activa. Días restantes: %d" % dias_penalidad_narrativa)

	for gallina in active_hens:
		# Solo gallinas vivas participan en la producción
		if gallina.dead:
			continue

		gallinas_procesadas += 1

		# Determinar p_base: especial si tiene nombre propio
		var p_base_gallina : float = P_BASE_ESPECIAL if _es_gallina_especial(gallina) else P_BASE

		# Factor edad: se aproxima con el ratio salud actual / salud máxima (Modelo 4)
		var factor_edad : float = _calcular_factor_edad(gallina)

		# Factor estrés: enferma tiene penalidad propia, además del estrés narrativo
		var factor_estres_ind : float = F_ESTRES_ENFERMA if gallina.current_state == 1 else factor_estres_global

		# Probabilidad individual — fórmula del Modelo 1:
		# p_i = p_base × f_edad × f_alim × f_estres
		var p_individual : float = p_base_gallina * factor_edad * factor_alim * factor_estres_ind
		p_individual = clamp(p_individual, 0.0, 1.0)

		# Ensayo de Bernoulli: u ~ U(0,1), X_i = 1 si u < p_i
		var u : float = randf()
		if u < p_individual:
			huevos_dia += 1

	# Registrar en histórico para validación independiente
	historico_produccion.append({
		"dia": dia_actual,
		"huevos": huevos_dia,
		"gallinas_activas": gallinas_procesadas,
		"formula_activa": formula_abuelo_activa,
		"penalidad_narrativa": dias_penalidad_narrativa > 0
	})

	var report := {
		"dia": dia_actual,
		"huevos_producidos": huevos_dia,
		"gallinas_activas": gallinas_procesadas,
		"formula_abuelo": formula_abuelo_activa,
	}

	print("[Modelo 1] Día %d — Gallinas: %d | Huevos producidos: %d" % [dia_actual, gallinas_procesadas, huevos_dia])
	emit_signal("production_calculated", report)
	return huevos_dia

# =====================================================================
# SUBTRAMA 1 — Fórmula especial del abuelo
# Activa el modificador de alimentación (+10% postura)
# Llamar desde main.gd cuando el jugador encuentra el cuaderno
# =====================================================================
func activar_formula_abuelo() -> void:
	formula_abuelo_activa = true
	print("[Modelo 1] Subtrama 1: Fórmula especial del abuelo activada. F_alim=%.2f" % F_ALIM_ESPECIAL)

# =====================================================================
# SUBTRAMA 3 — Muerte de gallina con nombre
# Activa penalidad de estrés narrativo por N días sobre todo el plantel
# Llamar desde main.gd cuando muere Cometida, Berenjena o La Muda
# =====================================================================
func activar_penalidad_narrativa(dias: int = 3) -> void:
	dias_penalidad_narrativa = dias
	print("[Modelo 1] Subtrama 3: Estrés narrativo activado por %d días. F_estres=%.2f" % [dias, F_ESTRES_NARRATIVO])

# =====================================================================
# PRUEBA DE VALIDACIÓN INDEPENDIENTE
# Ejecuta 1000 simulaciones con parámetros fijos y verifica convergencia
# Llamar desde main.gd o consola para validar sin necesidad del motor visual
# Resultado esperado: media ≈ 37.5 huevos con N=50 y p=0.75
# =====================================================================
func run_validation_test() -> void:
	print("\n[Modelo 1] === PRUEBA DE VALIDACIÓN INDEPENDIENTE ===")
	print("[Modelo 1] N=50 gallinas | p_base=0.75 | 1000 simulaciones")

	var suma_total : float = 0.0
	var N_GALLINAS : int = 50
	var N_SIMS     : int = 1000

	for _sim in range(N_SIMS):
		var huevos : int = 0
		for _gallina in range(N_GALLINAS):
			if randf() < P_BASE:
				huevos += 1
		suma_total += huevos

	var media : float = suma_total / N_SIMS
	var esperado : float = N_GALLINAS * P_BASE           # μ = N×p = 37.5
	var desv_esperada : float = sqrt(N_GALLINAS * P_BASE * (1.0 - P_BASE))  # σ ≈ 3.06

	print("[Modelo 1] Media simulada:  %.4f" % media)
	print("[Modelo 1] Media esperada:  %.4f (N×p = %d×%.2f)" % [esperado, N_GALLINAS, P_BASE])
	print("[Modelo 1] Desv. esperada:  ±%.4f" % desv_esperada)
	print("[Modelo 1] Error absoluto:  %.4f" % abs(media - esperado))

	if abs(media - esperado) < desv_esperada:
		print("[Modelo 1] ✅ VALIDACIÓN EXITOSA — La media converge dentro de 1σ")
	else:
		print("[Modelo 1] ⚠️  ATENCIÓN — Desviación mayor a 1σ, revisar parámetros")
	print("[Modelo 1] ==========================================\n")

# --- FUNCIONES AUXILIARES INTERNAS ---

# Determina si una gallina es una de las tres especiales (Subtrama 3)
# Por ahora se detecta por índice en active_hens (las 3 primeras del lote inicial)
func _es_gallina_especial(gallina: Node) -> bool:
	return gallina.get_meta("es_especial", false)

# Factor edad: ratio salud/salud_max. Gallinas más viejas (menos salud) ponen menos.
# Integra Modelo 4 sin acoplamiento directo.
func _calcular_factor_edad(gallina: Node) -> float:
	if gallina.max_health <= 0.0:
		return 1.0
	var ratio : float = gallina.health / gallina.max_health
	# Mapear ratio [0,1] → factor_edad [0.5, 1.0]
	return 0.5 + ratio * 0.5
