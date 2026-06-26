extends Control

func _ready():
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func actualizar(datos: Dictionary):
	for item_name in datos:
		var label = find_child(item_name, true, false)
		if label is Label:
			label.text = str(datos[item_name])

func abrir():
	visible = true

func cerrar():
	visible = false
