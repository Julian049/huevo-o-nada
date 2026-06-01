extends Node2D

const C_SKY          : Color = Color(0.529, 0.808, 0.922)
const C_VEGETATION   : Color = Color(0.333, 0.420, 0.184)
const C_PENS         : Color = Color(0.769, 0.643, 0.420)
const C_FEEDING      : Color = Color(0.831, 0.722, 0.510)
const C_PERIMETER    : Color = Color(0.420, 0.541, 0.227)
const C_HUD_BG       : Color = Color(0.173, 0.102, 0.031)
const C_WOOD         : Color = Color(0.545, 0.271, 0.075)
const C_WOOD_DARK    : Color = Color(0.420, 0.204, 0.063)
const C_RISK         : Color = Color(0.753, 0.224, 0.169)
const C_TEXT_LIGHT   : Color = Color(1.0,   0.973, 0.906)
const C_TEXT_OCHRE   : Color = Color(0.961, 0.773, 0.259)

const SCREEN_WIDTH   : float = 1152.0
const SCREEN_HEIGHT  : float = 648.0

# Límites Y de cada zona
const Y_SKY_END        : float = 50.0
const Y_VEGETATION_END : float = 68.0
const Y_PENS_END       : float = 268.0
const Y_FEED_END       : float = 368.0
const Y_PERIM_END      : float = 498.0

@export var custom_font : Font = null

func _draw() -> void:
	_draw_zones()
	_draw_zone_borders()
	_draw_feeders_and_drinkers()
	_draw_zone_labels()


func _draw_zones() -> void:
	draw_rect(Rect2(0, 0, SCREEN_WIDTH, Y_SKY_END), C_SKY)
	draw_rect(Rect2(0, Y_SKY_END, SCREEN_WIDTH, Y_VEGETATION_END - Y_SKY_END), C_VEGETATION)
	draw_rect(Rect2(0, Y_VEGETATION_END, SCREEN_WIDTH, Y_PENS_END - Y_VEGETATION_END), C_PENS)
	draw_rect(Rect2(0, Y_PENS_END, SCREEN_WIDTH, Y_FEED_END - Y_PENS_END), C_FEEDING)
	draw_rect(Rect2(0, Y_FEED_END, SCREEN_WIDTH, Y_PERIM_END - Y_FEED_END), C_PERIMETER)
	draw_rect(Rect2(0, Y_PERIM_END, SCREEN_WIDTH, SCREEN_HEIGHT - Y_PERIM_END), C_HUD_BG)


func _draw_zone_borders() -> void:
	var thickness : float = 2.0
	draw_line(Vector2(0, Y_VEGETATION_END), Vector2(SCREEN_WIDTH, Y_VEGETATION_END), C_WOOD_DARK, thickness)
	draw_line(Vector2(0, Y_PENS_END), Vector2(SCREEN_WIDTH, Y_PENS_END), C_WOOD, 3.0)
	draw_line(Vector2(0, Y_FEED_END), Vector2(SCREEN_WIDTH, Y_FEED_END), C_WOOD_DARK, thickness)
	
	_draw_dashed_border(Rect2(8, Y_FEED_END + 6, SCREEN_WIDTH - 16, Y_PERIM_END - Y_FEED_END - 12), C_RISK, 1.5, 10.0, 6.0)
	draw_line(Vector2(0, Y_PERIM_END), Vector2(SCREEN_WIDTH, Y_PERIM_END), C_WOOD, 3.0)


func _draw_dashed_border(rect: Rect2, color: Color, thickness: float, dash_length: float, gap_length: float) -> void:
	var points : Array[Array] = [
		[rect.position,                          Vector2(rect.end.x, rect.position.y)],
		[Vector2(rect.end.x, rect.position.y),   rect.end],
		[rect.end,                               Vector2(rect.position.x, rect.end.y)],
		[Vector2(rect.position.x, rect.end.y),   rect.position],
	]
	
	for pair in points:
		var start_pos  : Vector2 = pair[0]
		var end_pos    : Vector2 = pair[1]
		var total_dist : float   = start_pos.distance_to(end_pos)
		var direction  : Vector2 = (end_pos - start_pos).normalized()
		var traveled   : float   = 0.0
		var is_drawing : bool    = true
		
		while traveled < total_dist:
			var segment_end : float = minf(traveled + (dash_length if is_drawing else gap_length), total_dist)
			if is_drawing:
				draw_line(start_pos + direction * traveled, start_pos + direction * segment_end, color, thickness)
			traveled = segment_end
			is_drawing = not is_drawing


func _draw_feeders_and_drinkers() -> void:
	var center_y : float = Y_PENS_END + (Y_FEED_END - Y_PENS_END) / 2.0
	var elements : Array[Dictionary] = [
		{"x": 180.0, "type": "feeder"},
		{"x": 420.0, "type": "drinker"},
		{"x": 700.0, "type": "feeder"},
		{"x": 940.0, "type": "drinker"},
	]

	for el in elements:
		var cx           : float = el["x"]
		var bg_color     : Color = Color(0.545, 0.271, 0.075) if el["type"] == "feeder" else Color(0.106, 0.490, 0.710)
		var border_color : Color = Color(0.420, 0.204, 0.063) if el["type"] == "feeder" else Color(0.082, 0.373, 0.541)
		var label_text   : String = "Comedero" if el["type"] == "feeder" else "Bebedero"

		var rect := Rect2(cx - 60, center_y - 18, 120, 36)
		draw_rect(rect, bg_color)
		draw_rect(rect, border_color, false, 2.0)

		if custom_font:
			draw_string(custom_font, Vector2(cx - 32, center_y + 6), label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, C_TEXT_LIGHT)


func _draw_zone_labels() -> void:
	if not custom_font:
		return

	var label_x : float = 14.0
	var data_labels : Array[Dictionary] = [
		{"y": Y_VEGETATION_END + 20, "text": "Zona de corrales",               "color": C_WOOD_DARK},
		{"y": Y_PENS_END + 20,       "text": "Zona de alimentacion",           "color": C_WOOD_DARK},
		{"y": Y_FEED_END + 22,       "text": "Zona perimetral — ABM roedores", "color": C_RISK},
		{"y": Y_PERIM_END + 24,      "text": "Interfaz HUD",                   "color": C_TEXT_OCHRE},
		{"y": 14.0,                  "text": "Cielo andino — exterior",        "color": C_WOOD_DARK},
	]

	for d in data_labels:
		draw_string(custom_font, Vector2(label_x, d["y"]), d["text"], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, d["color"])
