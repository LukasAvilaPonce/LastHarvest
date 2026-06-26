extends CharacterBody3D

# ─── STATS ────────────────────────────────────────────────────────
@export var velocidad := 8
@export var gravedad := 9.8
@export var distancia_perseguir := 500.0
@export var distancia_atacar := 2.5
@export var dano := 15
@export var tiempo_entre_ataques := 1

# ─── ESTADO ───────────────────────────────────────────────────────
var jugador: Node3D = null
var objetivo_actual: Node3D = null
var puede_atacar := true
var hp := 80
var muriendo := false
var timer_buscar := 0.0
var color_base := Color(0.9, 0.9, 0.9)

# ─── NODOS ────────────────────────────────────────────────────────
@onready var nav: NavigationAgent3D = get_node_or_null("NavigationAgent3D")
@onready var anim: AnimationPlayer = _buscar_anim()
@onready var modelo: Node3D = get_node_or_null("copzombie_l_actisdato")

func _buscar_anim() -> AnimationPlayer:
	var rutas = [
		"copzombie_l_actisdato/AnimationPlayer",
		"AnimationPlayer"
	]
	for ruta in rutas:
		var nodo = get_node_or_null(ruta)
		if nodo is AnimationPlayer:
			return nodo
	return null

# ─── INIT ─────────────────────────────────────────────────────────
func _ready():
	add_to_group("zombies")
	buscar_jugador()
	if nav != null:
		nav.avoidance_enabled = false
	if anim != null:
		anim.root_motion_track = NodePath("")
		anim.play("zombie idle/mixamo_com")
	color_base = Color(0.9, 0.9, 0.9)
	_colorear(color_base)
	var barra = preload("res://barra_vida.gd").new()
	barra.position = Vector3(0, 2.5, 0)
	add_child(barra)
	barra.crear(1.0, 0.1)
	barra.actualizar(hp, 80, "Zombie")

func _colorear(color: Color):
	for child in get_children():
		if child is MeshInstance3D:
			var mat = StandardMaterial3D.new()
			mat.albedo_color = color
			child.material_override = mat
			return
	var modelo_node = get_node_or_null("copzombie_l_actisdato")
	if modelo_node == null:
		return
	for child in modelo_node.get_children():
		if child.has_method("get_children"):
			for sub in child.get_children():
				if sub is MeshInstance3D:
					var mat = StandardMaterial3D.new()
					mat.albedo_color = color
					sub.material_override = mat


# ─── LOOP PRINCIPAL ───────────────────────────────────────────────
func _physics_process(delta):
	if muriendo:
		velocity = Vector3.ZERO
		move_and_slide()
		return

	if not is_on_floor():
		velocity.y -= gravedad * delta

	if jugador == null or not is_instance_valid(jugador):
		buscar_jugador()
	if jugador == null or not is_instance_valid(jugador):
		velocity.x = 0
		velocity.z = 0
		move_and_slide()
		return

	# ── Elegir objetivo: el MÁS CERCANO (cada 0.3s) ────────────
	timer_buscar -= delta
	if timer_buscar <= 0 or objetivo_actual == null or not is_instance_valid(objetivo_actual):
		timer_buscar = 0.3
		var mejor: Node3D = null
		var mejor_dist := 99999.0

		var madre: Node3D = null
		var plantas_madre = get_tree().get_nodes_in_group("planta_madre")
		if plantas_madre.size() > 0 and is_instance_valid(plantas_madre[0]):
			madre = plantas_madre[0]

		var candidatos: Array[Node3D] = []
		if madre != null:
			candidatos.append(madre)
		if jugador != null and is_instance_valid(jugador):
			candidatos.append(jugador)
		for planta in get_tree().get_nodes_in_group("plantas"):
			if is_instance_valid(planta) and planta.get("activa"):
				candidatos.append(planta)

		for c in candidatos:
			var d = global_position.distance_to(c.global_position)
			if d < mejor_dist:
				mejor_dist = d
				mejor = c

		if mejor != null:
			objetivo_actual = mejor
		else:
			objetivo_actual = jugador

	# ── Distancia horizontal ─────────────────────────────────────
	var dir_al_objetivo = objetivo_actual.global_position - global_position
	dir_al_objetivo.y = 0
	var distancia = dir_al_objetivo.length()

	var rango_ataque := 2.0
	if objetivo_actual != null and objetivo_actual.is_in_group("planta_madre"):
		rango_ataque = 6.0

	# ── Mover / Atacar / Idle ────────────────────────────────────
	if distancia > distancia_perseguir:
		velocity.x = 0
		velocity.z = 0
		if anim != null and anim.current_animation != "zombie idle/mixamo_com":
			anim.play("zombie idle/mixamo_com")
	elif distancia <= rango_ataque:
		velocity.x = 0
		velocity.z = 0
		if dir_al_objetivo.length() > 0.1:
			rotation.y = lerp_angle(rotation.y, atan2(dir_al_objetivo.x, dir_al_objetivo.z), 0.2)
		if anim != null and anim.current_animation != "zombie attack/mixamo_com":
			anim.play("zombie attack/mixamo_com")
		if puede_atacar:
			atacar()
	else:
		var dir = dir_al_objetivo.normalized()
		velocity.x = dir.x * velocidad
		velocity.z = dir.z * velocidad
		if dir.length() > 0.1:
			rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), 0.15)
		if anim != null and anim.current_animation != "zombie run/mixamo_com":
			anim.play("zombie run/mixamo_com")
		_aplicar_separacion()

	move_and_slide()

# ─── ATAQUE ───────────────────────────────────────────────────────
func atacar():
	if not puede_atacar or not is_inside_tree():
		return
	if objetivo_actual == null or not is_instance_valid(objetivo_actual):
		return
	puede_atacar = false
	if objetivo_actual.has_method("recibir_dano"):
		objetivo_actual.recibir_dano(dano)
		print("Zombie atacó a: ", objetivo_actual.name)
	get_tree().create_timer(tiempo_entre_ataques).timeout.connect(
		func():
			if is_inside_tree():
				puede_atacar = true
	)

# ─── DAÑO Y MUERTE ────────────────────────────────────────────────
func recibir_dano(cantidad: int):
	if muriendo:
		return
	hp -= cantidad
	var barra_node = get_node_or_null("Node3D")
	if barra_node == null:
		for child in get_children():
			if child.has_method("actualizar"):
				barra_node = child
				break
	if barra_node != null:
		barra_node.actualizar(hp, 80, "Zombie")
	_efecto_recibir_dano()
	print("Zombie recibió daño, HP: ", hp)
	if hp <= 0:
		muriendo = true
		velocity = Vector3.ZERO
		var xp_node = get_node_or_null("/root/SistemaXP")
		if xp_node:
			xp_node.agregar_xp(25)
		if randf() < 0.05:
			_dropear_cargador()
		if anim != null:
			anim.play("zombie death/mixamo_com")
		await get_tree().create_timer(1.5).timeout
		queue_free()

func _efecto_recibir_dano():
	_colorear(Color(1.0, 0.2, 0.2))
	var modelo_node = get_node_or_null("copzombie_l_actisdato")
	if modelo_node != null:
		var pos_orig = modelo_node.position
		modelo_node.position = pos_orig + Vector3(randf_range(-0.2, 0.2), 0, randf_range(-0.2, 0.2))
		var tween = create_tween()
		tween.tween_property(modelo_node, "position", pos_orig, 0.1)
		tween.tween_callback(func():
			if is_inside_tree() and not muriendo:
				_colorear(color_base)
		)
	else:
		await get_tree().create_timer(0.1).timeout
		if is_inside_tree() and not muriendo:
			_colorear(color_base)

func _dropear_cargador():
	var cargador = preload("res://pickup_cargador.gd").new()
	get_tree().current_scene.add_child(cargador)
	cargador.global_position = global_position + Vector3(0, -0.5, 0)
	print("Zombie dropeó cargador!")

# ─── SEPARACIÓN MANUAL ENTRE ZOMBIES ─────────────────────────────
func _aplicar_separacion():
	var fuerza := Vector3.ZERO
	var mi_pos = global_position
	for z in get_tree().get_nodes_in_group("zombies"):
		if z == self or not is_instance_valid(z):
			continue
		var diff_x = mi_pos.x - z.global_position.x
		var diff_z = mi_pos.z - z.global_position.z
		var dist_sq = diff_x * diff_x + diff_z * diff_z
		if dist_sq < 1.44 and dist_sq > 0.0001:
			var dist = sqrt(dist_sq)
			var factor = (1.2 - dist) * 3.0 / dist
			fuerza.x += diff_x * factor
			fuerza.z += diff_z * factor
	velocity.x += fuerza.x
	velocity.z += fuerza.z

# ─── UTILIDADES ───────────────────────────────────────────────────
func buscar_jugador():
	var tree = get_tree()
	if tree == null:
		return
	var escena_actual = tree.current_scene
	if escena_actual != null:
		jugador = escena_actual.get_node_or_null("jugador")
	if jugador == null:
		jugador = get_node_or_null("/root/mundo/jugador")
