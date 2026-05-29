# -*- coding: utf-8 -*-
import re

with open('scenes/world/main.tscn', 'r', encoding='utf-8') as f:
    text = f.read()

new_ui = '''[node name="UIManager" type="CanvasLayer" parent="."]
script = ExtResource("5_tt8nk")

[node name="BackgroundMain" type="ColorRect" parent="UIManager"]
z_index = -10
offset_right = 852.0
offset_bottom = 648.0
mouse_filter = 2
color = Color(0.7686, 0.6431, 0.4196, 1)

[node name="Sidebar" type="ColorRect" parent="UIManager"]
offset_left = 852.0
offset_right = 1152.0
offset_bottom = 648.0
color = Color(0.5451, 0.2706, 0.0745, 1)

[node name="Margin" type="MarginContainer" parent="UIManager/Sidebar"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
theme_override_constants/margin_left = 20
theme_override_constants/margin_top = 20
theme_override_constants/margin_right = 20
theme_override_constants/margin_bottom = 20

[node name="VBox" type="VBoxContainer" parent="UIManager/Sidebar/Margin"]
layout_mode = 2
theme_override_constants/separation = 15

[node name="Title" type="Label" parent="UIManager/Sidebar/Margin/VBox"]
layout_mode = 2
theme_override_font_sizes/font_size = 22
text = "HUEVO O NADA"
horizontal_alignment = 1

[node name="HSeparator1" type="HSeparator" parent="UIManager/Sidebar/Margin/VBox"]
layout_mode = 2

[node name="LabelDay" type="Label" parent="UIManager/Sidebar/Margin/VBox"]
layout_mode = 2
theme_override_font_sizes/font_size = 18
text = "Día: 0 / 30"
horizontal_alignment = 1

[node name="HSeparator2" type="HSeparator" parent="UIManager/Sidebar/Margin/VBox"]
layout_mode = 2

[node name="TitleEco" type="Label" parent="UIManager/Sidebar/Margin/VBox"]
layout_mode = 2
theme_override_colors/font_color = Color(0.9608, 0.7725, 0.2588, 1)
theme_override_font_sizes/font_size = 16
text = "--- ECONOMÍA ---"
horizontal_alignment = 1

[node name="BalanceLabel" type="Label" parent="UIManager/Sidebar/Margin/VBox"]
layout_mode = 2
theme_override_colors/font_color = Color(0.3804, 0.8118, 0.3216, 1)
text = "Saldo: \"

[node name="DeudaLabel" type="Label" parent="UIManager/Sidebar/Margin/VBox"]
layout_mode = 2
theme_override_colors/font_color = Color(0.902, 0.298, 0.298, 1)
text = "Deuda: \"

[node name="InventarioLabel" type="Label" parent="UIManager/Sidebar/Margin/VBox"]
layout_mode = 2
text = "Huevos: 0 🥚"

[node name="HSeparator3" type="HSeparator" parent="UIManager/Sidebar/Margin/VBox"]
layout_mode = 2

[node name="TitleSalud" type="Label" parent="UIManager/Sidebar/Margin/VBox"]
layout_mode = 2
theme_override_colors/font_color = Color(0.4784, 0.549, 0.4157, 1)
theme_override_font_sizes/font_size = 16
text = "--- SALUD ---"
horizontal_alignment = 1

[node name="LabelVaccines" type="Label" parent="UIManager/Sidebar/Margin/VBox"]
layout_mode = 2
text = "Vacunas: 0"

[node name="LabelMedications" type="Label" parent="UIManager/Sidebar/Margin/VBox"]
layout_mode = 2
text = "Medicinas: 0"

[node name="HSeparator4" type="HSeparator" parent="UIManager/Sidebar/Margin/VBox"]
layout_mode = 2

[node name="LabelInstruction" type="Label" parent="UIManager/Sidebar/Margin/VBox"]
layout_mode = 2
theme_override_font_sizes/font_size = 14
text = "[Espacio] Iniciar\n[1] Vacuna (\)\n[2] Medicina (\)\n[3] Siguiente Día\n[4] Comprar Gallina"
autowrap_mode = 2

[node name="LabelGameOver" type="Label" parent="UIManager"]
visible = false
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -350.0
offset_top = -60.0
offset_right = -50.0
offset_bottom = 60.0
theme_override_colors/font_color = Color(1, 1, 1, 1)
theme_override_colors/font_outline_color = Color(0, 0, 0, 1)
theme_override_constants/outline_size = 10
theme_override_font_sizes/font_size = 40
text = "GAME OVER"
horizontal_alignment = 1
vertical_alignment = 1

[node name="RestartButton" type="Button" parent="UIManager"]
visible = false
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -250.0
offset_top = 40.0
offset_right = -150.0
offset_bottom = 80.0
theme_override_font_sizes/font_size = 20
text = "Reiniciar"

[node name="EventBanner" type="PanelContainer" parent="UIManager"]
visible = false
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -350.0
offset_top = -200.0
offset_right = -50.0
offset_bottom = -140.0

[node name="Label" type="Label" parent="UIManager/EventBanner"]
layout_mode = 2
theme_override_font_sizes/font_size = 18
horizontal_alignment = 1

'''

start_idx = text.find('[node name="UIManager"')
end_idx = text.find('[node name="HenManager"')

if start_idx != -1 and end_idx != -1:
    new_text = text[:start_idx] + new_ui + text[end_idx:]
    with open('scenes/world/main.tscn', 'w', encoding='utf-8') as f:
        f.write(new_text)
    print("Reemplazo exitoso en main.tscn")
else:
    print("No se encontraron los nodos UIManager o HenManager")
