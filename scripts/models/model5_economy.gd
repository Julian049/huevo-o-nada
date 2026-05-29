extends Node

# --- SEÑALES ---
signal comprador_llego(ingreso: float)
signal precio_actualizado(nuevo_precio: int)
signal costo_maiz_actualizado(nuevo_costo: int)
signal banquero_visito(deuda_restante: float)
signal inspeccion_ocurrio(multa: float)
signal oferta_vacunas_disponible()
signal vecino_vendio(nuevo_precio: int)
signal balance_actualizado(nuevo_balance: float, acumulado: float)
signal game_over(tipo: String)

# --- CONSTANTES DE RANGOS Y DISTRIBUCIONES ---
const DEUDA_TOTAL           := 1_500_000.0
const BALANCE_INICIAL       := 1_000_000.0
const PRECIO_HUEVO_INICIAL  := 800
const COSTO_ALIMENTO_INICIAL:= 140
const COSTOS_AGUA_LUZ       := 5_000.0

const PRECIO_HUEVO_MIN  := 600
const PRECIO_HUEVO_MAX  := 1200
const PRECIO_HUEVO_PASO := 50
const COSTO_MAIZ_MIN    := 80
const COSTO_MAIZ_MAX    := 200
const COSTO_MAIZ_PASO   := 20
const MULTA_MIN         := 100_000.0
const MULTA_MAX         := 500_000.0

const P_INSPECCION      := 0.15
const P_OFERTA_VACUNAS  := 0.20
const P_VECINO_VENDE    := 0.10
const PRECIO_BAJADA_VECINO := 50
const TASA_POSTURA      := 0.8

const DIAS_COMPRADOR    := [5, 10, 15, 20, 25, 30]
const DIAS_PRECIO_HUEVO := [7, 14, 21, 28]
const DIAS_COSTO_MAIZ   := [8, 16, 24]
const DIAS_BANQUERO     := [10, 20, 30]

# --- VARIABLES DE ESTADO ---
var balance_caja:       float
var inventario_huevos:  int
var precio_huevo:       int
var costo_alimento_dia: int
var acumulado_ventas:   float

# --- COLA DE EVENTOS ---
var _cola_eventos: Array

# Inicializa el modelo con los valores de la Tabla de Verdad
func initialize() -> void:
	balance_caja       = BALANCE_INICIAL
	inventario_huevos  = 0
	precio_huevo       = PRECIO_HUEVO_INICIAL
	costo_alimento_dia = COSTO_ALIMENTO_INICIAL
	acumulado_ventas   = 0.0
	_cola_eventos      = []
	_generar_cola_eventos()

# Construye la lista ordenada de todos los eventos del juego — sección 3.b.5.8
func _generar_cola_eventos() -> void:
	_cola_eventos = []

	# Eventos deterministas — sección 3.b.5.5
	for dia in DIAS_COMPRADOR:
		_cola_eventos.append({"dia": dia, "tipo": "COMPRADOR"})
	for dia in DIAS_PRECIO_HUEVO:
		_cola_eventos.append({"dia": dia, "tipo": "PRECIO_HUEVO"})
	for dia in DIAS_COSTO_MAIZ:
		_cola_eventos.append({"dia": dia, "tipo": "COSTO_MAIZ"})
	for dia in DIAS_BANQUERO:
		_cola_eventos.append({"dia": dia, "tipo": "BANQUERO"})

	# Eventos estocásticos — sección 3.b.5.5
	# Inspección: días impares, Bernoulli(0.15)
	# Oferta vacunas: días 5-25, Bernoulli(0.20)
	# Venta vecino: días pares, Bernoulli(0.10)
	for dia in range(1, 31):
		if dia % 2 != 0 and _bernoulli(P_INSPECCION):
			_cola_eventos.append({"dia": dia, "tipo": "INSPECCION"})
		if dia >= 5 and dia <= 25 and _bernoulli(P_OFERTA_VACUNAS):
			_cola_eventos.append({"dia": dia, "tipo": "OFERTA_VACUNAS"})
		if dia % 2 == 0 and _bernoulli(P_VECINO_VENDE):
			_cola_eventos.append({"dia": dia, "tipo": "VENTA_VECINO"})

	# Ordenar cronológicamente
	_cola_eventos.sort_custom(func(a, b): return a["dia"] < b["dia"])

# Función principal del modelo — procesa todos los eventos del día actual
# Traduce las fórmulas de la sección 3.b.5.3 y pseudocódigo de la sección 3.b.5.8
func process_day(dia_actual: int, n_gallinas: int, produccion: int, robos: int) -> void:

	# 1. Actualizar inventario — fórmula sección 3.b.5.3:
	# inventario(t+1) = inventario(t) + produccion(t) - robos(t)
	inventario_huevos += produccion - robos

	# 2. Descontar costos fijos del día — fórmula sección 3.b.5.3:
	# costos_dia = costo_alimento_dia × N(t) + costos_agua_luz
	var costos_dia := costo_alimento_dia * n_gallinas + COSTOS_AGUA_LUZ
	balance_caja -= costos_dia

	# 3. Verificar bancarrota — condición sección 3.b.5.3:
	# Derrota bancarrota: balance_caja <= 0 en cualquier día t
	if balance_caja <= 0:
		emit_signal("game_over", "BANCARROTA")
		return

	# 4. Procesar todos los eventos de este día
	for evento in _cola_eventos:
		if evento["dia"] == dia_actual:
			_procesar_evento(evento["tipo"], dia_actual)

	# 5. Emitir estado actualizado
	emit_signal("balance_actualizado", balance_caja, acumulado_ventas)

# Procesa un evento individual según su tipo — sección 3.b.5.5
func _procesar_evento(tipo: String, dia_actual: int) -> void:
	match tipo:

		"COMPRADOR":
			# fórmula sección 3.b.5.3
			var ingreso := inventario_huevos * precio_huevo
			balance_caja     += ingreso
			acumulado_ventas += ingreso
			inventario_huevos = 0
			emit_signal("comprador_llego", float(ingreso))

		"PRECIO_HUEVO":
			# Uniforme discreta U{600,...,1200} paso 50 — sección 3.b.5.2
			precio_huevo = _uniforme_discreta(PRECIO_HUEVO_MIN, PRECIO_HUEVO_MAX, PRECIO_HUEVO_PASO)
			emit_signal("precio_actualizado", precio_huevo)

		"COSTO_MAIZ":
			# Uniforme discreta U{80,...,200} paso 20 — sección 3.b.5.2
			costo_alimento_dia = _uniforme_discreta(COSTO_MAIZ_MIN, COSTO_MAIZ_MAX, COSTO_MAIZ_PASO)
			emit_signal("costo_maiz_actualizado", costo_alimento_dia)

		"BANQUERO":
			var deuda_restante := DEUDA_TOTAL - acumulado_ventas
			emit_signal("banquero_visito", deuda_restante)
			# Condición final solo en día 30 — sección 3.b.5.3
			if dia_actual == 30:
				if acumulado_ventas >= DEUDA_TOTAL:
					emit_signal("game_over", "VICTORIA")
				else:
					emit_signal("game_over", "EMBARGO")

		"INSPECCION":
			# Uniforme continua U(500.000, 2.000.000) — sección 3.b.5.5
			var multa := _uniforme_continua(MULTA_MIN, MULTA_MAX)
			balance_caja -= multa
			emit_signal("inspeccion_ocurrio", multa)

		"OFERTA_VACUNAS":
			emit_signal("oferta_vacunas_disponible")

		"VENTA_VECINO":
			# precio_huevo = MAX(600, precio_huevo - 50) — sección 3.b.5.5
			precio_huevo = max(PRECIO_HUEVO_MIN, precio_huevo - PRECIO_BAJADA_VECINO)
			emit_signal("vecino_vendio", precio_huevo)

# --- FUNCIONES AUXILIARES DE DISTRIBUCIONES ---
# Traducción directa del pseudocódigo de la sección 3.b.5.8

# Bernoulli(p): retorna true con probabilidad p
# Fuente: sección 3.b.5.8 — "SI aleatorio() < p: 1  SINO: 0"
func _bernoulli(p: float) -> bool:
	return randf() < p

# UniformeDiscreta(a, b, s): valor aleatorio en {a, a+s, a+2s, ..., b}
# Fuente: sección 3.b.5.8 — "a + aleatorio_entero(0, (b-a)/s) * s"
func _uniforme_discreta(minimo: int, maximo: int, paso: int) -> int:
	var n := int((float(maximo) - float(minimo)) / float(paso))
	return minimo + randi_range(0, n) * paso

# UniformeContinua(a, b): valor real aleatorio en [a, b]
# Fuente: sección 3.b.5.8 — "a + aleatorio() * (b-a)"
func _uniforme_continua(minimo: float, maximo: float) -> float:
	return randf_range(minimo, maximo)

# Intenta comprar algo y descuenta del balance real del Modelo 5
func comprar_item(costo: float) -> bool:
	if balance_caja >= costo:
		balance_caja -= costo
		emit_signal("balance_actualizado", balance_caja, acumulado_ventas)
		return true
	return false
