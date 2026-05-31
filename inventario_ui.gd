extends Control

var panel: Panel
var titulo: Label
var grid: GridContainer

# Tamaños base. Se reajustan automáticamente según la resolución.
var panel_porcentaje := Vector2(0.80, 0.70)
var slot_size := Vector2(150, 170)
var icon_size := Vector2(110, 110)
var fuente_titulo := 32
var fuente_item := 18

var inventario_actual := {}

var iconos := {
	"semillas": preload("res://assets/iconosHUD/semilla.svg"),
	"agua": preload("res://assets/iconosHUD/agua.svg"),
	"abono": preload("res://assets/iconosHUD/abono.svg")
}

func _ready():
	set_anchors_preset(Control.PRESET_FULL_RECT)
	crear_ui()
	ajustar_layout()
	visible = false

func _notification(what):
	if what == NOTIFICATION_RESIZED:
		ajustar_layout()

		# Si el inventario ya tenía items, se vuelven a dibujar
		# para que los slots se adapten al nuevo tamaño.
		if grid != null and inventario_actual.size() > 0:
			actualizar(inventario_actual)

func crear_ui():
	panel = Panel.new()
	add_child(panel)

	titulo = Label.new()
	titulo.text = "INVENTARIO"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(titulo)

	grid = GridContainer.new()
	panel.add_child(grid)

func ajustar_layout():
	if panel == null:
		return

	var pantalla = get_viewport_rect().size

	# Panel adaptable al tamaño de pantalla.
	panel.size = Vector2(
		pantalla.x * panel_porcentaje.x,
		pantalla.y * panel_porcentaje.y
	)

	# Centrar panel.
	panel.position = (pantalla - panel.size) / 2

	# Escala adaptable tomando 1080p como referencia.
	var escala = clamp(pantalla.y / 1080.0, 0.70, 1.20)

	var margen = 40.0 * escala
	var alto_titulo = 55.0 * escala
	var espacio_superior_grid = 80.0 * escala

	fuente_titulo = int(32 * escala)
	fuente_item = int(18 * escala)

	slot_size = Vector2(
		clamp(150.0 * escala, 110.0, 180.0),
		clamp(170.0 * escala, 130.0, 210.0)
	)

	icon_size = Vector2(
		clamp(110.0 * escala, 80.0, 140.0),
		clamp(110.0 * escala, 80.0, 140.0)
	)

	titulo.position = Vector2(0, 15 * escala)
	titulo.size = Vector2(panel.size.x, alto_titulo)
	titulo.add_theme_font_size_override("font_size", fuente_titulo)

	grid.position = Vector2(margen, espacio_superior_grid)
	grid.size = Vector2(
		panel.size.x - margen * 2,
		panel.size.y - espacio_superior_grid - margen
	)

	# Cantidad de columnas automática según el ancho disponible.
	grid.columns = max(1, int(grid.size.x / slot_size.x))

func abrir():
	visible = true
	ajustar_layout()

func cerrar():
	visible = false

func actualizar(inventario: Dictionary):
	inventario_actual = inventario.duplicate()

	if grid == null:
		return

	for hijo in grid.get_children():
		hijo.queue_free()

	for item in inventario.keys():
		var cantidad = inventario[item]

		if cantidad <= 0:
			continue

		var slot = crear_slot(item, cantidad)
		grid.add_child(slot)

func crear_slot(nombre_item: String, cantidad: int) -> Control:
	var slot = PanelContainer.new()
	slot.custom_minimum_size = slot_size

	var caja = VBoxContainer.new()
	caja.alignment = BoxContainer.ALIGNMENT_CENTER
	slot.add_child(caja)

	var imagen = TextureRect.new()
	imagen.custom_minimum_size = icon_size
	imagen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	imagen.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	if iconos.has(nombre_item):
		imagen.texture = iconos[nombre_item]

	caja.add_child(imagen)

	var texto = Label.new()
	texto.text = nombre_item.capitalize() + " x" + str(cantidad)
	texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto.add_theme_font_size_override("font_size", fuente_item)
	caja.add_child(texto)

	return slot
