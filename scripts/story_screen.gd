extends Node2D

# Array con todas las imágenes de la historia en orden
var story_images: Array[Texture2D] = []
var current_index: int = 0

@onready var story_image: TextureRect = $StoryImage
@onready var next_button: Button = $NextButton

func _ready() -> void:
	_setup_button_fx(next_button)
	# Carga las imágenes
	story_images = [
		preload("res://assets/story/story_01.png"),
		preload("res://assets/story/story_02.png"),
		preload("res://assets/story/story_03.png"),
		preload("res://assets/story/story_04.png"),
		preload("res://assets/story/story_05.png"),
		preload("res://assets/story/story_06.png"),
	]
	
	# Muestra la primera imagen
	current_index = 0
	story_image.texture = story_images[current_index]
	
	# Conecta el botón
	next_button.pressed.connect(_on_next_pressed)

func _on_next_pressed() -> void:
	current_index += 1
	
	if current_index >= story_images.size():
		get_tree().change_scene_to_file("res://scenes/world/main_menu.tscn")  
	else:
		story_image.texture = story_images[current_index]

func _setup_button_fx(btn: Button) -> void:
	var fx := ColorRect.new()
	fx.color = Color(1, 1, 0, 0)
	fx.size = btn.size
	fx.position = btn.position
	fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fx)
	btn.mouse_entered.connect(func():
		var tween = create_tween()
		tween.tween_property(fx, "color", Color(1, 0.85, 0, 0.25), 0.12)
	)
	btn.mouse_exited.connect(func():
		var tween = create_tween()
		tween.tween_property(fx, "color", Color(1, 1, 0, 0), 0.15)
	)
	btn.button_down.connect(func():
		var tween = create_tween()
		tween.tween_property(fx, "color", Color(1, 0.75, 0, 0.5), 0.05)
		tween.tween_property(fx, "color", Color(1, 1, 0, 0), 0.2)
	)
