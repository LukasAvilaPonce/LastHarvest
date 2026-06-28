extends StaticBody3D

# ─── STATS ────────────────────────────────────────────────────────
@export var hp_maximo := 10000
var hp := 10000
var muriendo := false
var timer_mejora_drop := 15.0

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
	barra.position = Vector3(-2, 10, 0)
	add_child(barra)
	barra.crear(3.0, 0.25)
	barra.actualizar(hp, hp_maximo, "Planta Madre")
	call_deferred("_fix_posicion")

func _fix_posicion():
	# Centrar hijos que tienen offsets incorrectos
	var base_node = get_node_or_null("base")
	if base_node != null:
		base_node.position = Vector3(0, 0, 0)
	var mesh_node = get_node_or_null("MeshInstance3D")
	if mesh_node != null:
		mesh_node.position = Vector3(0, 0, 0)
	var col_node = get_node_or_null("CollisionShape3D")
	if col_node != null:
		col_node.transform = Transform3D.IDENTITY
		col_node.position = Vector3(0, 2, 0)
		col_node.scale = Vector3(1, 1, 1)
		var shape = BoxShape3D.new()
		shape.size = Vector3(5, 5, 5)
		col_node.shape = shape
	# Mover Planta Madre dentro del mapa si está fuera
	if abs(global_position.x) > 45 or abs(global_position.z) > 22:
		global_position = Vector3(0, 0.5, 0)
	print("Planta Madre en: ", global_position)

func _process(delta):
	if muriendo:
		return
	var mundo = get_tree().current_scene
	if mundo == null:
		return
	var estado = mundo.get("estado_actual")
	if estado == null:
		return
	# Solo dropear mejoras durante oleadas (OLEADA=2, CAOS=3, BOSS_FIGHT=5)
	if not (estado == 2 or estado == 3 or estado == 5):
		return
	# Limitar mejoras en el mapa (max 3)
	var mejoras_en_mapa = 0
	for child in get_tree().current_scene.get_children():
		if child.has_method("recoger_mejora") or (child.get("recogida") != null and child.name.begins_with("@")):
			mejoras_en_mapa += 1
	if mejoras_en_mapa >= 3:
		return
	timer_mejora_drop -= delta
	if timer_mejora_drop <= 0:
		timer_mejora_drop = 15.0
		_dropear_mejora()

func _dropear_mejora():
	var plantas = get_tree().get_nodes_in_group("plantas")
	if plantas.size() == 0:
		return
	var mejora = preload("res://pickup_mejora.gd").new()
	get_tree().current_scene.add_child(mejora)
	var pos_mej = Vector3(global_position.x + randf_range(-5, 5), global_position.y + 1.5, global_position.z + randf_range(-5, 5))
	mejora.global_position = pos_mej
	print("Mejora dropeada en: ", snapped(pos_mej, Vector3(0.1,0.1,0.1)))

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

	# Drop fijo: 4 caminantes, 3 girasol
	var drops = [
		{"key": "semillas_caminante", "cant": 4},
		{"key": "semillas_girasol", "cant": 3},
	]
	var desbloqueadas = [0, 1]
	if jugador_nodo.get("plantas_desbloqueadas") != null:
		desbloqueadas = jugador_nodo.plantas_desbloqueadas
	var extras = {2: "semillas_hongo", 3: "semillas_enredadera", 4: "semillas_chile", 5: "semillas_arbol"}
	for idx in desbloqueadas:
		if extras.has(idx):
			drops.append({"key": extras[idx], "cant": 2})

	print("=== DROP LOOT desde Planta Madre en: ", global_position, " ===")
	var pos_base = global_position
	var item_idx = 0
	var total_items = 0
	for d in drops:
		total_items += d["cant"]
	for d in drops:
		for _i in range(d["cant"]):
			var pickup = preload("res://pickup_semilla.gd").new()
			pickup.tipo_semilla = d["key"]
			pickup.cantidad = 1
			get_tree().current_scene.add_child(pickup)
			var angulo = (float(item_idx) / max(total_items, 1)) * TAU
			var drop_pos = Vector3(pos_base.x + cos(angulo) * 5, pos_base.y + 1.5, pos_base.z + sin(angulo) * 5)
			pickup.global_position = drop_pos
			print("  Drop ", d["key"], " en: ", snapped(drop_pos, Vector3(0.1,0.1,0.1)))
			item_idx += 1

	var agua_p = preload("res://pickup_recurso.gd").new()
	agua_p.tipo = "agua"
	agua_p.cantidad = 10
	get_tree().current_scene.add_child(agua_p)
	var pos_agua = Vector3(pos_base.x - 4, pos_base.y + 1.5, pos_base.z + 4)
	agua_p.global_position = pos_agua
	print("  Drop agua x10 en: ", snapped(pos_agua, Vector3(0.1,0.1,0.1)))

	var abono_p = preload("res://pickup_recurso.gd").new()
	abono_p.tipo = "abono"
	abono_p.cantidad = 10
	get_tree().current_scene.add_child(abono_p)
	var pos_abono = Vector3(pos_base.x + 4, pos_base.y + 1.5, pos_base.z - 4)
	abono_p.global_position = pos_abono
	print("  Drop abono x10 en: ", snapped(pos_abono, Vector3(0.1,0.1,0.1)))

	_efecto_loot_drop()
	print("=== FIN DROP ===")

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
	get_tree().current_scene.add_child(arma)
	var pos_arma = Vector3(global_position.x + 6, global_position.y + 1.5, global_position.z)
	arma.global_position = pos_arma
	print("Arma dropeada en: ", snapped(pos_arma, Vector3(0.1,0.1,0.1)))
	_efecto_drop_arma()

func _efecto_drop_arma():
	var pos_arma = Vector3(global_position.x + 6, global_position.y + 1, global_position.z)

	material.albedo_color = Color(0.0, 1.0, 0.3)
	var tw_mat = create_tween()
	tw_mat.tween_property(material, "albedo_color", COLOR_NORMAL, 1.0)

	var onda = MeshInstance3D.new()
	var mesh_onda = TorusMesh.new()
	mesh_onda.inner_radius = 0.3
	mesh_onda.outer_radius = 0.6
	onda.mesh = mesh_onda
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.0, 1.0, 0.3, 0.7)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	onda.material_override = mat
	onda.global_position = pos_arma
	get_tree().current_scene.add_child(onda)
	var tw = onda.create_tween()
	tw.tween_property(onda, "scale", Vector3(5, 1, 5), 1.0).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(mat, "albedo_color:a", 0.0, 1.0)
	tw.tween_callback(onda.queue_free)

	for i in range(6):
		var part = MeshInstance3D.new()
		var mesh_p = SphereMesh.new()
		mesh_p.radius = 0.15
		mesh_p.height = 0.3
		part.mesh = mesh_p
		var mat_p = StandardMaterial3D.new()
		mat_p.albedo_color = Color(0.0, 1.0, 0.3, 0.8)
		mat_p.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat_p.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		part.material_override = mat_p
		part.global_position = pos_arma + Vector3(randf_range(-1, 1), -0.5, randf_range(-1, 1))
		get_tree().current_scene.add_child(part)
		var tw_p = part.create_tween()
		tw_p.tween_property(part, "global_position:y", pos_arma.y + 2, 1.2)
		tw_p.parallel().tween_property(mat_p, "albedo_color:a", 0.0, 1.2)
		tw_p.tween_callback(part.queue_free)

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
