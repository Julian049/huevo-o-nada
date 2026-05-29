extends Node
# Gestor de interfaz mejorada que simula los 5 modelos de simulación
# Proporciona una experiencia visual inmersiva con narrativa integrada

@onready var label_day: Label = $LabelDay
@onready var label_instruction: Label = $LabelInstruction
@onready var label_game_over: Label = $LabelGameOver
@onready var top_bar: PanelContainer = $TopBar
@onready var side_panel: PanelContainer = $SidePanel

# Diccionarios de estado para cada modelo
var model_status = {
	"model1_production": {"huevos_hoy": 0, "gallinas_sanas": 0, "gallinas_totales": 0},
	"model2_abm": {"roedores": 0, "huevos_robados": 0, "nivel_amenaza": "BAJO"},
	"model3_disease": {"enfermas": 0, "sanas": 0, "tasa_contagio": 0.0},
	"model4_queues": {"edad_promedio": 0.0, "vida_restante": 0.0, "muertes_proximas": 0},
	"model5_economy": {"balance": 0, "ingresos": 0, "egresos": 0, "próxima_venta": 0}
}

var active_narrative_events = []
var last_day_shown = -1

# Prepara la interfaz antes de que el jugador presione ESPACIO
func setup_initial_ui() -> void:
	label_instruction.visible = true
	label_game_over.visible = false
	label_day.visible = false
	top_bar.visible = false
	side_panel.visible = false
	$DashboardPanel.visible = false
	$DebtProgressPanel.visible = false
	$NarrativePanel.visible = false

# Muestra el HUD principal una vez que arranca la simulación
func setup_running_ui() -> void:
	label_instruction.visible = false
	label_day.visible = true
	top_bar.visible = true
	side_panel.visible = true
	$DashboardPanel.visible = true
	$DebtProgressPanel.visible = true
	$NarrativePanel.visible = true

# Activa el cartel de fin de juego y el botón de reiniciar
func show_game_over(mensaje: String = "GAME OVER") -> void:
	label_game_over.text = mensaje
	label_game_over.visible = true
	$RestartButton.visible = true
	top_bar.visible = false
	side_panel.visible = false
	$DashboardPanel.visible = false
	$DebtProgressPanel.visible = false
	$NarrativePanel.visible = false

# Reinicia la escena completa
func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()

# Refresca los textos en pantalla con los datos actuales del jugador y el día
func update_hud(day: int, player: Node) -> void:
	_update_day_display(day)
	_update_inventory_display(player)

# =============== MODELO 1 - PRODUCCIÓN DE HUEVOS ===============
func update_production_status(huevos_hoy: int, gallinas_totales: int, gallinas_sanas: int) -> void:
	model_status["model1_production"]["huevos_hoy"] = huevos_hoy
	model_status["model1_production"]["gallinas_totales"] = gallinas_totales
	model_status["model1_production"]["gallinas_sanas"] = gallinas_sanas
	_update_model1_panel()

# =============== MODELO 2 - CONTROL DE PLAGAS (ABM) ===============
func update_plague_status(rodents_count: int, eggs_stolen: int) -> void:
	model_status["model2_abm"]["roedores"] = rodents_count
	model_status["model2_abm"]["huevos_robados"] = eggs_stolen
	
	# Determinar nivel de amenaza
	if rodents_count == 0:
		model_status["model2_abm"]["nivel_amenaza"] = "CONTROLADO"
	elif rodents_count < 10:
		model_status["model2_abm"]["nivel_amenaza"] = "BAJO"
	elif rodents_count < 25:
		model_status["model2_abm"]["nivel_amenaza"] = "MEDIO"
	elif rodents_count < 50:
		model_status["model2_abm"]["nivel_amenaza"] = "ALTO"
	else:
		model_status["model2_abm"]["nivel_amenaza"] = "🚨 CRÍTICO"
	
	_update_model2_panel()
	
	if rodents_count >= 50:
		_show_critical_event("⚠️ ¡COLONIA DE ROEDORES INCONTROLABLE! " + str(rodents_count) + " roedores causando estragos")

# =============== MODELO 3 - ENFERMEDAD (DINÁMICA DE SISTEMAS) ===============
func update_disease_status(enfermas: int, sanas: int, tasa_contagio: float) -> void:
	model_status["model3_disease"]["enfermas"] = enfermas
	model_status["model3_disease"]["sanas"] = sanas
	model_status["model3_disease"]["tasa_contagio"] = tasa_contagio
	_update_model3_panel()
	
	if enfermas > 5:
		_show_warning_event("🦠 Brote en el gallinero: " + str(enfermas) + " gallinas enfermas")

# =============== MODELO 4 - CICLO DE VIDA (COLAS) ===============
func update_lifecycle_status(edad_promedio: float, vida_restante: float, muertes_proximas: int) -> void:
	model_status["model4_queues"]["edad_promedio"] = edad_promedio
	model_status["model4_queues"]["vida_restante"] = vida_restante
	model_status["model4_queues"]["muertes_proximas"] = muertes_proximas
	_update_model4_panel()
	
	if muertes_proximas > 2:
		_show_warning_event("📊 " + str(muertes_proximas) + " gallinas llegando al fin de su vida útil")

# =============== MODELO 5 - ECONOMÍA (EVENTOS DISCRETOS) ===============
func update_economy(balance: float, inventario: int, deuda_restante: float, días_hasta_venta: int = 0) -> void:
	model_status["model5_economy"]["balance"] = int(balance)
	model_status["model5_economy"]["deuda_restante"] = int(deuda_restante)
	model_status["model5_economy"]["inventario"] = inventario
	model_status["model5_economy"]["próxima_venta"] = días_hasta_venta
	
	_update_model5_panel()
	_update_debt_progress(balance, deuda_restante, inventario)
	
	# Actualizar labels principales
	var balance_label: Label = $TopBar/MarginContainer/VBoxContainer/LabelBalance
	var inventario_label: Label = $TopBar/MarginContainer/VBoxContainer/HBoxInfo/InventarioLabel
	var deuda_label: Label = $TopBar/MarginContainer/VBoxContainer/HBoxInfo/DeudaLabel
	
	if balance_label: balance_label.text = "💰 Saldo: $" + _format_money(int(balance))
	if inventario_label: inventario_label.text = "🥚 Huevos: %d" % inventario
	if deuda_label: deuda_label.text = "💳 Deuda: $" + _format_money(int(deuda_restante))

# =============== EVENTOS Y NARRATIVA ===============
func show_event_banner(mensaje: String, tipo: String = "info") -> void:
	$EventBanner/Label.text = mensaje
	$EventBanner.visible = true
	
	# Cambiar color según tipo de evento
	match tipo:
		"comprador":
			$EventBanner.self_modulate = Color(0.2, 0.8, 0.2)
		"negativo":
			$EventBanner.self_modulate = Color(0.8, 0.2, 0.2)
		"info":
			$EventBanner.self_modulate = Color(0.2, 0.5, 0.8)
	
	await get_tree().create_timer(4.0).timeout
	$EventBanner.visible = false

func _show_critical_event(mensaje: String) -> void:
	_add_narrative_event(mensaje, "critical")
	await show_event_banner("🚨 " + mensaje, "negativo")

func _show_warning_event(mensaje: String) -> void:
	_add_narrative_event(mensaje, "warning")
	await show_event_banner("⚠️ " + mensaje, "info")

func _show_positive_event(mensaje: String) -> void:
	_add_narrative_event(mensaje, "positive")
	await show_event_banner("✅ " + mensaje, "comprador")

func _add_narrative_event(mensaje: String, tipo: String) -> void:
	active_narrative_events.append({
		"texto": mensaje,
		"tipo": tipo,
		"timestamp": Time.get_ticks_msec()
	})
	# Mantener solo los últimos 5 eventos
	if active_narrative_events.size() > 5:
		active_narrative_events.pop_front()
	_update_narrative_panel()

# =============== FUNCIONES DE ECONOMÍA Y EVENTOS ===============
func on_comprador_llego(ingreso: float) -> void:
	_show_positive_event("¡El comprador llegó! Venta de $" + _format_money(int(ingreso)))
	show_event_banner("💰 ¡Venta exitosa! Ingresos: $" + _format_money(int(ingreso)), "comprador")

func on_precio_actualizado(nuevo_precio: int) -> void:
	_add_narrative_event("Precio del huevo fluctuó: $" + str(nuevo_precio), "info")
	show_event_banner("📈 Precio huevo: $" + str(nuevo_precio), "info")

func on_costo_maiz_actualizado(nuevo_costo: int) -> void:
	_add_narrative_event("Costo de alimento: $" + str(nuevo_costo) + "/gallina", "info")
	show_event_banner("🌽 Costo alimento: $" + str(nuevo_costo), "info")

func on_banquero_visito(deuda_restante: float, día: int) -> void:
	var mensaje = "Banquero Rodrigo Urquijo visitó. Deuda restante: $" + _format_money(int(deuda_restante))
	_show_warning_event(mensaje)
	show_event_banner("🏦 " + mensaje, "negativo")

func on_inspeccion_ocurrio(multa: float) -> void:
	_show_critical_event("¡Inspección sanitaria sorpresa! Multa: $" + _format_money(int(multa)))

func on_vecino_interaccion(tipo: String, efecto: String) -> void:
	if tipo == "positivo":
		_show_positive_event("Carlos (vecino): " + efecto)
	else:
		_show_warning_event("Carlos (vecino): " + efecto)

# =============== FUNCIONES AUXILIARES DE PANTALLA ===============
func _update_day_display(day: int) -> void:
	if day == last_day_shown:
		return
	last_day_shown = day
	
	var progress_bar = ""
	var barra_length = int(float(day) / 30.0 * 20)
	for i in range(20):
		progress_bar += "█" if i < barra_length else "░"
	
	# Determinar semana
	var semana = int(float(day) / 7.0) + 1
	var dia_en_semana = ((day - 1) % 7) + 1
	
	label_day.text = "Día: %d / 30  [%s]  (Semana %d - Día %d)" % [day, progress_bar, semana, dia_en_semana]

func _update_inventory_display(player: Node) -> void:
	if player == null:
		return
	var label_vaccines: Label = $SidePanel/MarginContainer/VBoxContainer/LabelVaccines
	var label_medications: Label = $SidePanel/MarginContainer/VBoxContainer/LabelMedications
	
	if label_vaccines: label_vaccines.text = "💉 Vacunas: %d" % player.vaccine_inventory
	if label_medications: label_medications.text = "💊 Medicamentos: %d" % player.medicine_inventory

func _update_debt_progress(balance: float, deuda_restante: float, huevos: int) -> void:
	if not has_node("DebtProgressPanel"):
		return
	var panel = $DebtProgressPanel
	if panel == null:
		return

func _update_model1_panel() -> void:
	if not has_node("DashboardPanel/Model1Info"):
		return
	var info = $DashboardPanel/Model1Info
	if info:
		info.text = "🐔 PRODUCCIÓN: %d huevos | %d/%d gallinas sanas" % [
			model_status["model1_production"]["huevos_hoy"],
			model_status["model1_production"]["gallinas_sanas"],
			model_status["model1_production"]["gallinas_totales"]
		]

func _update_model2_panel() -> void:
	if not has_node("DashboardPanel/Model2Info"):
		return
	var info = $DashboardPanel/Model2Info
	if info:
		var color_estado = Color.RED if model_status["model2_abm"]["nivel_amenaza"] == "🚨 CRÍTICO" else Color.YELLOW
		info.text = "🐭 PLAGAS: %d roedores | %d huevos robados | Estado: %s" % [
			model_status["model2_abm"]["roedores"],
			model_status["model2_abm"]["huevos_robados"],
			model_status["model2_abm"]["nivel_amenaza"]
		]

func _update_model3_panel() -> void:
	if not has_node("DashboardPanel/Model3Info"):
		return
	var info = $DashboardPanel/Model3Info
	if info:
		info.text = "🦠 SALUD: %d enfermas | %d sanas | Contagio: %.1f%%" % [
			model_status["model3_disease"]["enfermas"],
			model_status["model3_disease"]["sanas"],
			model_status["model3_disease"]["tasa_contagio"] * 100
		]

func _update_model4_panel() -> void:
	if not has_node("DashboardPanel/Model4Info"):
		return
	var info = $DashboardPanel/Model4Info
	if info:
		info.text = "📊 EDAD: %.1f años | Vida restante: %.1f | Muertes próximas: %d" % [
			model_status["model4_queues"]["edad_promedio"],
			model_status["model4_queues"]["vida_restante"],
			model_status["model4_queues"]["muertes_proximas"]
		]

func _update_model5_panel() -> void:
	if not has_node("DashboardPanel/Model5Info"):
		return
	var info = $DashboardPanel/Model5Info
	if info:
		var próxima = model_status["model5_economy"]["próxima_venta"]
		var próxima_text = str(próxima) + " días" if próxima > 0 else "¡HOY!"
		info.text = "💰 ECONOMÍA: Saldo: $%s | Próxima venta: %s" % [
			_format_money(model_status["model5_economy"]["balance"]),
			próxima_text
		]

func _update_narrative_panel() -> void:
	if not has_node("NarrativePanel/EventList"):
		return
	var list = $NarrativePanel/EventList
	if list:
		var texto = ""
		for event in active_narrative_events:
			var icon = "📌"
			if event["tipo"] == "critical":
				icon = "🚨"
			elif event["tipo"] == "warning":
				icon = "⚠️"
			elif event["tipo"] == "positive":
				icon = "✅"
			texto += icon + " " + event["texto"] + "\n"
		list.text = texto

func _format_money(amount: int) -> String:
	var texto = str(amount)
	var resultado = ""
	var contador = 0
	for i in range(texto.length() - 1, -1, -1):
		if contador > 0 and contador % 3 == 0:
			resultado = "." + resultado
		resultado = texto[i] + resultado
		contador += 1
	return resultado

# =============== ACTUALIZACIONES DE PERSONAJES NARRATIVOS ===============
func show_banker_dialogue(deuda_restante: float, día: int) -> void:
	var porcentaje = ((1500000.0 - deuda_restante) / 1500000.0) * 100
	var mensaje = "🏦 Rodrigo Urquijo (Banquero): "
	
	if deuda_restante <= 0:
		mensaje += "¡Deuda pagada! Tu granja está libre."
	elif porcentaje < 20:
		mensaje += "¿Qué pasa? ¡Apenas has pagado el " + str(int(porcentaje)) + "%! Día " + str(día) + " de 30."
	elif porcentaje < 50:
		mensaje += "Buen progreso... pero aún te queda mucho. " + str(int(porcentaje)) + "% pagado."
	else:
		mensaje += "Veo que al fin te estás tomando esto en serio..."
	
	_show_warning_event(mensaje)

func show_grandfather_advice(consejo: String) -> void:
	var mensajes = [
		"📜 Abuelo Ernesto: 'Las vacunas son inversión, no gasto, mi querido nieto'",
		"📜 Abuelo Ernesto: 'Observa el balance cada día. La ignorancia cuesta dinero'",
		"📜 Abuelo Ernesto: 'Un roedor hoy, cien roedores mañana. Actúa temprano'",
		"📜 Abuelo Ernesto: 'Las gallinas envejecen. Debes renovar el plantel'",
		"📜 Abuelo Ernesto: 'La paciencia y la ciencia salvan granjas, muchacho'"
	]
	_add_narrative_event(mensajes[randi_range(0, mensajes.size() - 1)], "positive")

func show_neighbor_interaction(tipo_interaccion: String) -> void:
	var mensajes_positivos = [
		"😊 Carlos (Vecino): 'Mira, tienes buen potencial. Te dejo huevos a mejor precio hoy'",
		"😊 Carlos (Vecino): 'Veo que sabes cuidar gallinas. Quizás no eres tan malo después de todo'",
	]
	var mensajes_negativos = [
		"😠 Carlos (Vecino): 'Jajaja, tus roedores se están comiendo todo. ¡Vuelven a mi granja!'",
		"😠 Carlos (Vecino): 'Vi a varias de tus gallinas muertas. Mal negocio, amigo'",
		"😠 Carlos (Vecino): 'Oye, ¿ese es el mismo banco que me embargó? Buena suerte, necesitarás'",
	]
	
	if tipo_interaccion == "positivo":
		_show_positive_event(mensajes_positivos[randi_range(0, mensajes_positivos.size() - 1)])
	else:
		_show_warning_event(mensajes_negativos[randi_range(0, mensajes_negativos.size() - 1)])

# =============== INFORMACIÓN DE GALLINAS ESPECIALES ===============
func show_special_hens_status(cometida: bool, berenjena: bool, la_muda: bool) -> void:
	var special_hens = []
	if cometida: special_hens.append("Cometida")
	if berenjena: special_hens.append("Berenjena")
	if la_muda: special_hens.append("La Muda")
	
	if special_hens.size() == 3:
		_show_positive_event("✨ Las 3 gallinas del abuelo siguen vivas y productivas")
	elif special_hens.size() > 0:
		_show_warning_event("⚠️ Gallinas especiales vivas: " + ", ".join(special_hens))
	else:
		_show_critical_event("💀 Las gallinas favoritas del abuelo han muerto...")

# =============== RESUMEN DE DÍA ===============
func show_daily_summary(day: int, production: int, infections: int, deaths: int, balance_change: float) -> void:
	var summary = "\n📊 ════ RESUMEN DEL DÍA %d ════\n" % day
	summary += "🐔 Producción: +%d huevos\n" % production
	
	if infections > 0:
		summary += "🦠 Nuevas infecciones: %d\n" % infections
	if deaths > 0:
		summary += "💀 Muertes: %d gallinas\n" % deaths
	
	if balance_change > 0:
		summary += "💰 Cambio de balance: +$%d\n" % int(balance_change)
	elif balance_change < 0:
		summary += "💸 Cambio de balance: -$%d\n" % int(abs(balance_change))
	
	summary += "════════════════════════════\n"
	_add_narrative_event(summary, "info")

# =============== ALERTAS CRÍTICAS ===============
func show_critical_alert(alerta: String) -> void:
	_show_critical_event("🚨 ALERTA CRÍTICA: " + alerta)

func show_success_milestone(hito: String) -> void:
	var iconos = ["🎉", "⭐", "✨", "🏆", "🎊"]
	var icono = iconos[randi_range(0, iconos.size() - 1)]
	_show_positive_event(icono + " ¡LOGRO! " + hito)
