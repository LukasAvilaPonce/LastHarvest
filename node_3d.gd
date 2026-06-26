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
	var jugador = get_tree().current_scene.get_node_or_null("jugador")
	if jugador == null:
		return

	var base = 3 + numero_oleada
	var agua   = 10 + numero_oleada * 3
	var abono  = 10 + numero_oleada * 3

	jugador.agregar_item("semillas_caminante", base + 2)
	jugador.agregar_item("semillas_girasol", base)
	jugador.agregar_item("semillas_hongo", base)
	jugador.agregar_item("semillas_enredadera", base)
	jugador.agregar_item("semillas_chile", base)
	jugador.agregar_item("semillas_arbol", base)
	jugador.agregar_item("agua", agua)
	jugador.agregar_item("abono", abono)

	print("Loot oleada ", numero_oleada, " — Agua: +", agua, " Abono: +", abono)

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
