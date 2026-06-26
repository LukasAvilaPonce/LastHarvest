extends Control

var panel_fondo: PanelContainer
var grid: GridContainer
var items_rows := {}
var items_labels := {}

const ITEMS_CONFIG = {
	"semillas_caminante": {"nombre": "Sem. Caminante", "color": Color(0.2, 0.7, 0.2), "idx": 0},
	"semillas_girasol": {"nombre": "Sem. Girasol", "color": Color(1.0, 0.85, 0.0), "idx": 1},
	"semillas_hongo": {"nombre": "Sem. Hongo", "color": Color(0.4, 0.2, 0.0), "idx": 2},
	"semillas_enredadera": {"nombre": "Sem. Enredadera", "color": Color(0.0, 0.3, 0.0), "idx": 3},
	"semillas_chile": {"nombre": "Sem. Chile", "color": Color(0.9, 0.1, 0.0), "idx": 4},
	"semillas_arbol": {"nombre": "Sem. Centinela", "color": Color(0.0, 0.4, 0.3), "idx": 5},
	"agua": {"nombre": "Agua", "color": Color(0.3, 0.5, 1.0), "idx": -1},
	"abono": {"nombre": "Abono", "color": Color(0.5, 0.3, 0.1), "idx": -1},
}

func _ready():
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_construir_ui()

func _construir_ui():
	var fondo_oscuro = ColorRect.new()
	fondo_oscuro.anchor_right = 1.0
	fondo_oscuro.anchor_bottom = 1.0
	fondo_oscuro.color = Color(0, 0, 0, 0.6)
	fondo_oscuro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fondo_oscuro)

	panel_fondo = PanelContainer.new()
	panel_fondo.anchor_left = 0.5
	panel_fondo.anchor_right = 0.5
	panel_fondo.anchor_top = 0.5
	panel_fondo.anchor_bottom = 0.5
	panel_fondo.offset_left = -300
	panel_fondo.offset_right = 300
	panel_fondo.offset_top = -250
	panel_fondo.offset_bottom = 250
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.12, 0.95)
	style.border_color = Color(0.4, 0.6, 0.4)
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	panel_fondo.add_theme_stylebox_override("panel", style)
	add_child(panel_fondo)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel_fondo.add_child(vbox)

	var titulo = Label.new()
	titulo.text = "INVENTARIO"
	titulo.add_theme_font_size_override("font_size", 28)
	titulo.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(titulo)

	var sep = HSeparator.new()
	vbox.add_child(sep)

	grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 15)
	grid.add_theme_constant_override("v_separation", 8)
	vbox.add_child(grid)

	for key in ITEMS_CONFIG:
		var config = ITEMS_CONFIG[key]
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		hbox.visible = false
		grid.add_child(hbox)

		var icono = ColorRect.new()
		icono.custom_minimum_size = Vector2(24, 24)
		icono.color = config["color"]
		hbox.add_child(icono)

		var lbl_nombre = Label.new()
		lbl_nombre.text = config["nombre"]
		lbl_nombre.add_theme_font_size_override("font_size", 18)
		lbl_nombre.custom_minimum_size = Vector2(160, 0)
		hbox.add_child(lbl_nombre)

		var lbl_cant = Label.new()
		lbl_cant.text = "x0"
		lbl_cant.add_theme_font_size_override("font_size", 20)
		lbl_cant.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
		lbl_cant.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		lbl_cant.custom_minimum_size = Vector2(80, 0)
		hbox.add_child(lbl_cant)

		items_labels[key] = lbl_cant
		items_rows[key] = hbox

	var sep2 = HSeparator.new()
	vbox.add_child(sep2)

	var instruccion = Label.new()
	instruccion.text = "Presiona [I] para cerrar"
	instruccion.add_theme_font_size_override("font_size", 14)
	instruccion.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	instruccion.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(instruccion)

func actualizar(datos: Dictionary):
	var jugador = get_tree().current_scene.get_node_or_null("jugador")
	var desbloqueadas = [0, 1]
	if jugador != null and jugador.get("plantas_desbloqueadas") != null:
		desbloqueadas = jugador.plantas_desbloqueadas

	for key in items_rows:
		var config = ITEMS_CONFIG[key]
		var idx = config["idx"]
		if idx == -1:
			# Agua y abono: visible si tiene al menos 1
			items_rows[key].visible = datos.get(key, 0) > 0
		else:
			# Semillas: visible solo si esa planta está desbloqueada
			items_rows[key].visible = idx in desbloqueadas

		if items_labels.has(key):
			items_labels[key].text = "x" + str(datos.get(key, 0))

func abrir():
	visible = true
	get_tree().paused = true

func cerrar():
	visible = false
	get_tree().paused = false
