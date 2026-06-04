extends StaticBody3D

# ─── STATS ────────────────────────────────────────────────────────
@export var hp_maximo := 500
var hp := 500
var muriendo := false

# ─── NODOS Y VISUAL ───────────────────────────────────────────────
@onready var mesh := $MeshInstance3D
var material: StandardMaterial3D

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
	print("Planta Madre lista — HP: ", hp)

# ─── DAÑO ─────────────────────────────────────────────────────────
func recibir_dano(cantidad: int):
	if muriendo:
		return
	hp -= cantidad
	hp = clampi(hp, 0, hp_maximo)
	print("Planta Madre recibió daño: -", cantidad, " HP (total: ", hp, "/", hp_maximo, ")")

	# Actualizar HUD si existe
	_actualizar_hud()

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

# ─── LOOT AL GANAR OLEADA ─────────────────────────────────────────
func dropear_loot(numero_oleada: int):
	var jugador = get_tree().current_scene.get_node_or_null("jugador")
	if jugador == null:
		return

	# Loot escala con el número de oleada
	var semillas = 5 + (numero_oleada * 2)
	var abono    = 3 + (numero_oleada * 1)

	jugador.agregar_item("semillas", semillas)
	jugador.agregar_item("abono", abono)

	print("Planta Madre dropeo loot — Semillas: +", semillas, " Abono: +", abono)

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
