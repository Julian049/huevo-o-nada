extends Node2D
# =====================================================================
# TrapOverlay — dibuja trampas y roedores visibles en la zona perimetral
# Se conecta al Model2ABM y se redibuja cada vez que avanza el día.
# =====================================================================

# Zona perimetral (exactamente igual que map_background.gd y model2_abm.gd)
const Y_PERIM_START : float = 374.0
const Y_PERIM_END   : float = 492.0
const X_MIN         : float = 8.0
const X_MAX         : float = 1144.0

# Señal para anunciar capturas con posición (para el flash visual)
signal trampa_activada(pos: Vector2)

# Referencia al modelo — se asigna desde main.gd
var model2 : Node = null

# Estado visual interno
var _trampas_pos   : Array = []   # [{x, y}] posiciones actuales de trampas
var _roedores_pos  : Array = []   # [{x, y, vivo}] posiciones actuales de roedores
var _flashes       : Array = []   # [{x, y, t}] destellos de captura activos

# ── Colores ────────────────────────────────────────────────────────
const C_TRAMPA_BORDE : Color = Color(0.545, 0.271, 0.075)   # café madera
const C_TRAMPA_FONDO : Color = Color(0.800, 0.600, 0.200)   # ocre claro
const C_TRAMPA_ACTIV : Color = Color(0.961, 0.773, 0.259)   # amarillo brillante
const C_RATON_CUERPO : Color = Color(0.320, 0.290, 0.270)   # gris oscuro
const C_RATON_OJO    : Color = Color(0.980, 0.200, 0.200)   # rojo
const C_FLASH        : Color = Color(1.000, 0.900, 0.100, 0.85)

# =====================================================================
func _ready() -> void:
	z_index = 5  # Encima del fondo, debajo del HUD

# Llamar desde main.gd después de cada simulate_turn()
func refresh(trampas: Array, colonia: Array) -> void:
	_trampas_pos  = trampas.duplicate(true)
	_roedores_pos = colonia.duplicate(true)
	queue_redraw()

# Añade un destello en la posición de una trampa que capturó un roedor
func flash_captura(pos: Vector2) -> void:
	_flashes.append({"x": pos.x, "y": pos.y, "t": 1.0})
	queue_redraw()
	# Animar el destello bajando opacidad
	var tw := create_tween()
	tw.tween_method(_decay_flash.bind(_flashes.size() - 1), 1.0, 0.0, 0.6)
	tw.tween_callback(queue_redraw)

func _decay_flash(val: float, idx: int) -> void:
	if idx < _flashes.size():
		_flashes[idx]["t"] = val
	queue_redraw()

# =====================================================================
# DIBUJO PRINCIPAL
# =====================================================================
func _draw() -> void:
	_draw_trampas()
	_draw_roedores()
	_draw_flashes()

func _draw_trampas() -> void:
	for trampa in _trampas_pos:
		var px : float = clamp(trampa["pos_x"], X_MIN + 16, X_MAX - 16)
		var py : float = clamp(trampa["pos_y"], Y_PERIM_START + 6, Y_PERIM_END - 6)
		var center := Vector2(px, py)

		# Cuerpo de la trampa — rectángulo de madera
		var rect := Rect2(center.x - 14, center.y - 10, 28, 20)
		draw_rect(rect, C_TRAMPA_FONDO)
		draw_rect(rect, C_TRAMPA_BORDE, false, 2.0)

		# Muelle central (línea en V)
		draw_line(center + Vector2(-7, 4), center + Vector2(0, -4), C_TRAMPA_BORDE, 2.0)
		draw_line(center + Vector2(7, 4),  center + Vector2(0, -4), C_TRAMPA_BORDE, 2.0)

		# Emoji/ícono textual encima
		draw_string(
			ThemeDB.fallback_font,
			center + Vector2(-8, -14),
			"🪤", HORIZONTAL_ALIGNMENT_LEFT, -1, 13
		)

func _draw_roedores() -> void:
	for roedor in _roedores_pos:
		if not roedor.get("vivo", true):
			continue
		var px : float = clamp(roedor["pos_x"], X_MIN + 10, X_MAX - 10)
		var py : float = clamp(roedor["pos_y"], Y_PERIM_START + 6, Y_PERIM_END - 6)
		var c  := Vector2(px, py)

		# Cuerpo ovalado
		draw_ellipse_approx(c, Vector2(9, 6), C_RATON_CUERPO)

		# Cabeza
		draw_circle(c + Vector2(8, -1), 5.0, C_RATON_CUERPO)

		# Ojo
		draw_circle(c + Vector2(11, -2), 1.5, C_RATON_OJO)

		# Cola (curva aproximada con líneas)
		draw_line(c + Vector2(-9, 0), c + Vector2(-14, -4), C_RATON_CUERPO, 1.5)
		draw_line(c + Vector2(-14, -4), c + Vector2(-17, -2), C_RATON_CUERPO, 1.2)

		# Oreja
		draw_circle(c + Vector2(6, -5), 2.5, C_RATON_CUERPO)

func _draw_flashes() -> void:
	for flash in _flashes:
		var alpha : float = flash["t"]
		if alpha <= 0.01:
			continue
		var fc := C_FLASH
		fc.a = alpha * 0.85
		var fpos := Vector2(flash["x"], flash["y"])
		draw_circle(fpos, 18.0, fc)
		draw_string(
			ThemeDB.fallback_font,
			fpos + Vector2(-10, -22),
			"💥", HORIZONTAL_ALIGNMENT_LEFT, -1, 16
		)

# Aproximación de elipse con polígono
func draw_ellipse_approx(center: Vector2, radii: Vector2, color: Color) -> void:
	var pts : PackedVector2Array = []
	var steps : int = 12
	for i in range(steps):
		var angle : float = (TAU / steps) * i
		pts.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(pts, color)
