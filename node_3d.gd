extends StaticBody3D

# ─── STATS ────────────────────────────────────────────────────────
@export var hp_maximo := 500
var hp := 500
var muriendo := false

# ─── NODOS Y VISUAL ───────────────────────────────────────────────
@onready var mesh := $MeshInstance3D
var material: StandardMaterial3D
var barra: Node3D

# ─── COLORES ──────────────────────────────────────────────────────
const COLOR_NORMAL  = Color(0.0, 0.8, 0.2)
const COLOR_DANO    = Color(1.0, 0.1, 0.1)
const COLOR_CRITICO = Color(1.0, 0.5, 0.0)  # menos del 25% HP

# ─── INIT ─────────────────────────────────────────────────────────
func _ready():
	add_to_group("planta_madre")
	material = StandardMaterial3D.new()
	material.albedo_color = COLOR_NORMAL
	mesh.material_override = material
	barra = preload("res://barra_vida.gd").new()
	barra.position = Vector3(0, 7, 0)
	add_child(barra)
	barra.crear(3.0, 0.25)
	barra.actualizar(hp, hp_maximo, "Planta Madre")
	print("Planta Madre lista — HP: ", hp)

# ─── DAÑO ─────────────────────────────────────────────────────────
func recibir_dano(cantidad: int):
	if muriendo:
		return
	hp -= cantidad
	hp = clampi(hp, 0, hp_maximo)
	print("Planta Madre recibió daño: -", cantidad, " HP (total: ", hp, "/", hp_maximo, ")")

	_actualizar_hud()
	if barra != null:
		barra.actualizar(hp, hp_maximo, "Planta Madre")

	if hp <= 0:
		_morir()
		return

	# Parpadeo rojo
	material.albedo_color = COLOR_DANO
	await get_tree().create_timer(0.2).timeout
	if is_inside_tree() and not muriendo:
		# Color crítico si queda menos del 25%
		if hp <= hp_maximo * 0.25:
			material.albedo_color = COLOR_CRITICO
		else:
			material.albedo_color = COLOR_NORMAL

# ─── CURACIÓN ─────────────────────────────────────────────────────
func recibir_curacion(cantidad: int):
	if muriendo:
		return
	hp = clampi(hp + cantidad, 0, hp_maximo)
	print("Planta Madre curada: +", cantidad, " HP (total: ", hp, "/", hp_maximo, ")")
	_actualizar_hud()
	if barra != null:
		barra.actualizar(hp, hp_maximo, "Planta Madre")

# ─── LOOT AL GANAR OLEADA ─────────────────────────────────────────
func dropear_loot(numero_oleada: int):
	var jugador_nodo = get_tree().current_scene.get_node_or_null("jugador")
	if jugador_nodo == null:
		return

	if numero_oleada == 0:
		_dropear_arma()

	var agua  = 10 + (numero_oleada * 10)
	var abono = 10 + (numero_oleada * 10)
	var cant_semillas = 5 + (numero_oleada * 2)

	jugador_nodo.agregar_item("agua", agua)
	jugador_nodo.agregar_item("abono", abono)

	var keys_semillas = [
		"semillas_caminante", "semillas_girasol", "semillas_hongo",
		"semillas_enredadera", "semillas_chile", "semillas_arbol"
	]
	for _i in range(cant_semillas):
		var key = keys_semillas[randi() % keys_semillas.size()]
		jugador_nodo.agregar_item(key, 1)

	_efecto_loot_drop()
	print("Loot oleada ", numero_oleada, " — Agua: +", agua, " Abono: +", abono, " Semillas: +", cant_semillas)

func _efecto_loot_drop():
	var colores = [
		Color(0.3, 0.5, 1.0),
		Color(0.5, 0.3, 0.1),
		Color(0.2, 1.0, 0.3),
		Color(1.0, 0.85, 0.0),
		Color(0.9, 0.1, 0.0),
	]
	for i in range(8):
		var particula = MeshInstance3D.new()
		var mesh_p = SphereMesh.new()
		mesh_p.radius = 0.3
		mesh_p.height = 0.6
		particula.mesh = mesh_p
		var mat = StandardMaterial3D.new()
		mat.albedo_color = colores[i % colores.size()]
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		particula.material_override = mat
		particula.global_position = global_position + Vector3(0, 3, 0)
		get_tree().current_scene.add_child(particula)
		var angulo = (i / 8.0) * TAU
		var destino = particula.global_position + Vector3(cos(angulo) * 5, 4, sin(angulo) * 5)
		var tween = particula.create_tween()
		tween.tween_property(particula, "global_position", destino, 0.6).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(particula, "scale", Vector3(0.1, 0.1, 0.1), 0.8)
		tween.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.8)
		tween.tween_callback(particula.queue_free)

	# Texto flotante
	var canvas = get_tree().current_scene.get_node_or_null("CanvasLayer")
	if canvas:
		var label = Label.new()
		label.text = "LOOT RECIBIDO"
		label.add_theme_font_size_override("font_size", 32)
		label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.anchor_left = 0.5
		label.anchor_right = 0.5
		label.anchor_top = 0.4
		label.offset_left = -150
		label.offset_right = 150
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		canvas.add_child(label)
		var tween = label.create_tween()
		tween.tween_property(label, "offset_top", -60.0, 1.5)
		tween.parallel().tween_property(label, "modulate:a", 0.0, 1.5)
		tween.tween_callback(label.queue_free)

func _dropear_arma():
	var arma = preload("res://pickup_arma.gd").new()
	arma.global_position = global_position + Vector3(-5, 1, 0)
	get_tree().current_scene.add_child(arma)
	print("Planta Madre dropeó un arma!")

# ─── MUERTE → GAME OVER ───────────────────────────────────────────
func _morir():
	muriendo = true
	print("¡PLANTA MADRE DESTRUIDA — GAME OVER!")
	material.albedo_color = COLOR_DANO

	# Pequeña pausa antes del game over para que se vea el efecto
	await get_tree().create_timer(1.5).timeout
	if is_inside_tree():
		get_tree().reload_current_scene()

# ─── HUD ──────────────────────────────────────────────────────────
func _actualizar_hud():
	var label = get_tree().current_scene.get_node_or_null("CanvasLayer/LabelPlantaMadre")
	if label:
		label.text = "Planta Madre: " + str(hp) + "/" + str(hp_maximo)
