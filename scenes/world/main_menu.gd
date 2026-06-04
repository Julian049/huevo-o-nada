extends Control

@onready var panel_instrucciones : PanelContainer = $PanelInstrucciones
@onready var panel_creditos      : PanelContainer = $PanelCreditos
@onready var pagina_uno          : Control = $PanelInstrucciones/PaginaUno
@onready var pagina_dos          : Control = $PanelInstrucciones/PaginaDos

func _ready() -> void:
	_setup_button_fx($BtnJugar)
	_setup_button_fx($BtnHistoria)
	_setup_button_fx($BtnInstrucciones)
	_setup_button_fx($BtnCreditos)
	_setup_button_fx($BtnCerrar)
	

	$BtnJugar.pressed.connect(_on_jugar)
	$BtnHistoria.pressed.connect(_on_historia)
	$BtnInstrucciones.pressed.connect(_on_instrucciones)
	$BtnCreditos.pressed.connect(_on_creditos)
	$BtnCerrar.pressed.connect(_on_cerrar)
	
	$PanelCreditos/BtnVolverCreditos.pressed.connect(_cerrar_paneles)
	$PanelInstrucciones/PaginaUno/BtnVolverUno.pressed.connect(_cerrar_paneles)
	$PanelInstrucciones/PaginaUno/BtnSiguiente.pressed.connect(_ir_pagina_dos)
	$PanelInstrucciones/PaginaDos/BtnVolverDos.pressed.connect(_ir_pagina_uno)

	_cerrar_paneles()

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

func _cerrar_paneles() -> void:
	panel_instrucciones.visible = false
	panel_creditos.visible      = false

func _ir_pagina_dos() -> void:
	pagina_uno.visible = false
	pagina_dos.visible = true

func _ir_pagina_uno() -> void:
	pagina_uno.visible = true
	pagina_dos.visible = false

func _on_jugar() -> void:
	get_tree().change_scene_to_file("res://scenes/world/main.tscn")

func _on_historia() -> void:
	get_tree().change_scene_to_file("res://scenes/StoryScreen.tscn")

func _on_instrucciones() -> void:
	_cerrar_paneles()
	pagina_uno.visible = true
	pagina_dos.visible = false
	panel_instrucciones.visible = true

func _on_creditos() -> void:
	_cerrar_paneles()
	panel_creditos.visible = true
	
func _on_cerrar() -> void:
	get_tree().quit()
