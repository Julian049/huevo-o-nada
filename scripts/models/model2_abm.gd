extends Node
# =====================================================================
# MODELO 2 — CONTROL DE PLAGAS (ABM — AGENTES ROEDORES)
# Autor: Daniel Perez Jimenez
# =====================================================================
# Cada roedor es un agente autónomo con posición (x, y), estado vivo/muerto
# y comportamiento de movimiento hacia los huevos más cercanos.
# La colonia crece exponencialmente sin intervención: N(t+1) = N(t) × λ
# Las trampas aplican Bernoulli(p_cap) por roedor por turno.
#
# Integración con otros modelos:
#   - Modelo 1: los huevos robados R(t) se descuentan de H_neto antes del Modelo 5
#   - Modelo 5 (Economía): recibe H_neto = H_dia - R(t) en process_day()
# =====================================================================

signal rodents_processed(report: Dictionary)
signal roedor_capturado(pos: Vector2)  # Para el flash visual en TrapOverlay

# --- PARÁMETROS DEL MODELO ---
const N_INICIAL        : int   = 3      # Roedores al inicio de la partida
const TASA_REPRODUCCION: float = 1.10   # Crecimiento diario sin trampas (λ)
const UMBRAL_COLONIA   : int   = 15     # Tamaño crítico: colonia incontrolable
const RADIO_MOVIMIENTO : float = 80.0   # Píxeles por turno de movimiento
const ALPHA_ROBO       : float = 0.25   # Huevos robados por roedor por turno (máx.)
const P_CAP_BASE       : float = 0.25   # Probabilidad de captura por trampa

# Límites reales del mapa (de map_background.gd)
const MAP_X_MIN      : float = 8.0
const MAP_X_MAX      : float = 1144.0
# Roedores y trampas SOLO en la zona perimetral
const MAP_Y_PERIM_START : float = 374.0   # Y_FEED_END + margen
const MAP_Y_PERIM_END   : float = 492.0   # Y_PERIM_END - margen

# --- ESTRUCTURA DE UN AGENTE ROEDOR ---
# Cada roedor es un Dictionary con los campos:
#   pos_x, pos_y : float — posición actual en el mapa
#   vivo         : bool  — falso cuando es capturado por trampa
#   id           : int   — identificador único para trazabilidad

# --- ESTADO DEL MODELO ---
var colonia       : Array = []   # Lista de agentes roedores
var trampas       : Array = []   # Lista de posiciones de trampas activas [{x, y}]
var _next_id      : int   = 0
var huevos_robados_acumulados : int = 0

# Inicializa el modelo con la colonia inicial
# Llamar desde main.gd en _ready()
func initialize() -> void:
	colonia = []
	trampas = []
	_next_id = 0
	huevos_robados_acumulados = 0
	_spawn_roedores(N_INICIAL)
	print("[Modelo 2] Inicializado. Colonia inicial: %d roedores." % colonia.size())

# =====================================================================
# FUNCIÓN PRINCIPAL — Simular un turno de la colonia
# Parámetros:
#   huevos_disponibles : int — producción del Modelo 1 antes de robos
#   dia_actual         : int — número de día (para reporte)
# Retorna: int — huevos efectivamente robados ese día
# =====================================================================
func simulate_turn(huevos_disponibles: int, dia_actual: int) -> int:
	var robos_del_dia : int = 0
	var huevos_restantes : int = huevos_disponibles

	# 1. Fase de movimiento, robo y captura por trampa
	for roedor in colonia:
		if not roedor["vivo"]:
			continue

		# Mover hacia zona central del mapa (donde están las gallinas y huevos)
		_mover_roedor(roedor)

		# Intentar robar un huevo si hay disponibles
		if huevos_restantes > 0 and randf() < ALPHA_ROBO:
			robos_del_dia     += 1
			huevos_restantes  -= 1

		# Verificar captura por cada trampa activa
		for trampa in trampas:
			var distancia : float = Vector2(roedor["pos_x"], roedor["pos_y"]).distance_to(
				Vector2(trampa["pos_x"], trampa["pos_y"])
			)
			if distancia < 60.0:
				# Bernoulli(p_cap): captura estocástica
				if randf() < P_CAP_BASE:
					roedor["vivo"] = false
					print("[Modelo 2] Roedor #%d capturado por trampa." % roedor["id"])
					emit_signal("roedor_capturado", Vector2(roedor["pos_x"], roedor["pos_y"]))
					break  # Evitar doble captura

	# 2. Eliminar roedores muertos de la colonia
	colonia = colonia.filter(func(r): return r["vivo"])

	# 3. Reproducción diaria — crecimiento exponencial discreto
	var vivos_antes : int = colonia.size()
	if vivos_antes > 0:
		var nuevos : int = int(floor(vivos_antes * (TASA_REPRODUCCION - 1.0)))
		_spawn_roedores(nuevos)

	huevos_robados_acumulados += robos_del_dia

	# 4. Evaluar estado de la colonia
	var n_vivos : int = _contar_vivos()
	var colonia_critica : bool = n_vivos >= UMBRAL_COLONIA

	if colonia_critica:
		print("[Modelo 2] ⚠️  COLONIA CRÍTICA: %d roedores. ¡Colocar trampas urgente!" % n_vivos)

	var report := {
		"dia": dia_actual,
		"roedores_vivos": n_vivos,
		"huevos_robados": robos_del_dia,
		"trampas_activas": trampas.size(),
		"colonia_critica": colonia_critica,
		"huevos_robados_total": huevos_robados_acumulados
	}

	print("[Modelo 2] Día %d — Roedores: %d | Robos: %d | Trampas: %d" % [
		dia_actual, n_vivos, robos_del_dia, trampas.size()
	])

	emit_signal("rodents_processed", report)
	return robos_del_dia

# =====================================================================
# COLOCAR TRAMPA — Llamar desde main.gd con KEY_5
# Coloca una trampa en una posición aleatoria del perímetro del mapa
# =====================================================================
func colocar_trampa() -> void:
	var trampa := {
		"pos_x": randf_range(MAP_X_MIN + 40.0, MAP_X_MAX - 40.0),
		"pos_y": randf_range(MAP_Y_PERIM_START, MAP_Y_PERIM_END)
	}
	trampas.append(trampa)
	print("[Modelo 2] Trampa colocada en (%.0f, %.0f). Total trampas: %d" % [
		trampa["pos_x"], trampa["pos_y"], trampas.size()
	])

# =====================================================================
# PRUEBA DE VALIDACIÓN INDEPENDIENTE
# Simula 30 turnos sin trampas y verifica que la colonia alcanza el
# umbral crítico entre los días 18-22.
# Luego simula 30 turnos con 3 trampas y verifica estabilización < 20.
# =====================================================================
func run_validation_test() -> void:
	print("\n[Modelo 2] === PRUEBA DE VALIDACIÓN INDEPENDIENTE ===")

	# --- ESCENARIO A: sin trampas ---
	print("[Modelo 2] Escenario A: N_inicial=%d, λ=%.2f, 0 trampas, 30 días" % [N_INICIAL, TASA_REPRODUCCION])
	var n_a : float = float(N_INICIAL)
	var dia_critico : int = -1
	for dia in range(1, 31):
		n_a = n_a * TASA_REPRODUCCION
		if n_a >= UMBRAL_COLONIA and dia_critico == -1:
			dia_critico = dia
	print("[Modelo 2] Colonia alcanza umbral (%d) en el día: %d" % [UMBRAL_COLONIA, dia_critico])
	if dia_critico >= 18 and dia_critico <= 22:
		print("[Modelo 2] ✅ Escenario A VALIDADO — umbral entre días 18-22")
	else:
		print("[Modelo 2] ⚠️  Escenario A fuera de rango esperado (revisar λ)")

	# --- ESCENARIO B: con 3 trampas ---
	print("[Modelo 2] Escenario B: N_inicial=%d, λ=%.2f, 3 trampas, p_cap=%.2f, 30 días" % [N_INICIAL, TASA_REPRODUCCION, P_CAP_BASE])
	var n_b : float = float(N_INICIAL)
	for _dia in range(30):
		# Captura estimada con 3 trampas
		var capturados : float = n_b * (1.0 - pow(1.0 - P_CAP_BASE, 3))
		n_b = maxf(0.0, (n_b - capturados) * TASA_REPRODUCCION)
	print("[Modelo 2] Tamaño de colonia al día 30: %.1f roedores" % n_b)
	if n_b < 20.0:
		print("[Modelo 2] ✅ Escenario B VALIDADO — colonia estabilizada < 20 roedores")
	else:
		print("[Modelo 2] ⚠️  Escenario B fuera de rango (colonia no controlada con 3 trampas)")

	print("[Modelo 2] ==========================================\n")

# --- FUNCIONES AUXILIARES INTERNAS ---

# Crea N nuevos agentes roedores en posiciones del perímetro
func _spawn_roedores(n: int) -> void:
	for _i in range(n):
		var roedor := {
			"id":    _next_id,
			"pos_x": randf_range(MAP_X_MIN, MAP_X_MAX),
			"pos_y": _elegir_borde_y(),
			"vivo":  true
		}
		colonia.append(roedor)
		_next_id += 1

# Los roedores aparecen distribuidos en la zona perimetral
func _elegir_borde_y() -> float:
	return randf_range(MAP_Y_PERIM_START, MAP_Y_PERIM_END)

# Mueve al roedor en dirección al centro del mapa (donde están las gallinas)
func _mover_roedor(roedor: Dictionary) -> void:
	var centro_x : float = (MAP_X_MIN + MAP_X_MAX) / 2.0
	var centro_y : float = (MAP_Y_PERIM_START + MAP_Y_PERIM_END) / 2.0
	var dx : float = centro_x - roedor["pos_x"]
	var dy : float = centro_y - roedor["pos_y"]
	var dist : float = sqrt(dx * dx + dy * dy)
	if dist > 1.0:
		roedor["pos_x"] += (dx / dist) * RADIO_MOVIMIENTO * randf_range(0.5, 1.0)
		roedor["pos_y"] += (dy / dist) * RADIO_MOVIMIENTO * randf_range(0.5, 1.0)
	# Mantener dentro de la zona perimetral
	roedor["pos_x"] = clamp(roedor["pos_x"], MAP_X_MIN, MAP_X_MAX)
	roedor["pos_y"] = clamp(roedor["pos_y"], MAP_Y_PERIM_START, MAP_Y_PERIM_END)

# Cuenta roedores vivos en la colonia
func _contar_vivos() -> int:
	var count : int = 0
	for r in colonia:
		if r["vivo"]: count += 1
	return count
