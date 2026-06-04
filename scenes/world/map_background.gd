extends Node2D

const SCREEN_WIDTH   : float = 1152.0
const SCREEN_HEIGHT  : float = 648.0
const Y_PERIM_END    : float = 498.0   # Donde empieza el HUD

# Colores que aún se necesitan encima de la imagen
const C_HUD_BG   : Color = Color(0.173, 0.102, 0.031)  # Franja HUD oscura
const C_RISK     : Color = Color(0.753, 0.224, 0.169)  # Borde rojo punteado perimetral
const C_WOOD     : Color = Color(0.545, 0.271, 0.075)  # Línea madera

# Límites de la zona perimetral (donde van roedores y trampas)
const Y_FEED_END : float = 368.0

@export var custom_font : Font = null

var _bg_texture : Texture2D = null

func _ready() -> void:
	_bg_texture = load("res://assets/sprites/farm_bg.png")
	queue_redraw()

func _draw() -> void:
	# 1. Dibujar imagen de fondo (cubre Y: 0 → 498)
	if _bg_texture:
		draw_texture_rect(
			_bg_texture,
			Rect2(0, 0, SCREEN_WIDTH, Y_PERIM_END),
			false
		)
	
	# 2. Franja HUD (Y: 498 → 648) — color oscuro encima
	draw_rect(
		Rect2(0, Y_PERIM_END, SCREEN_WIDTH, SCREEN_HEIGHT - Y_PERIM_END),
		C_HUD_BG
	)
	
	# 3. Borde punteado rojo — marca la zona perimetral de roedores
	_draw_dashed_border(
		Rect2(8, Y_FEED_END + 6, SCREEN_WIDTH - 16, Y_PERIM_END - Y_FEED_END - 12),
		C_RISK, 1.5, 10.0, 6.0
	)
	
	# 4. Línea separadora HUD
	draw_line(
		Vector2(0, Y_PERIM_END),
		Vector2(SCREEN_WIDTH, Y_PERIM_END),
		C_WOOD, 3.0
	)

func _draw_dashed_border(rect: Rect2, color: Color, thickness: float, dash_length: float, gap_length: float) -> void:
	var points : Array[Array] = [
		[rect.position,                          Vector2(rect.end.x, rect.position.y)],
		[Vector2(rect.end.x, rect.position.y),   rect.end],
		[rect.end,                               Vector2(rect.position.x, rect.end.y)],
		[Vector2(rect.position.x, rect.end.y),   rect.position],
	]
	for pair in points:
		var start_pos : Vector2 = pair[0]
		var end_pos   : Vector2 = pair[1]
		var total_len : float = start_pos.distance_to(end_pos)
		var direction : Vector2 = (end_pos - start_pos).normalized()
		var pos       : float = 0.0
		var drawing   : bool = true
		while pos < total_len:
			var seg_len : float = dash_length if drawing else gap_length
			var next    : float = min(pos + seg_len, total_len)
			if drawing:
				draw_line(start_pos + direction * pos, start_pos + direction * next, color, thickness)
			pos     = next
			drawing = not drawing
