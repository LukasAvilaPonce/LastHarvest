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
var _pos_y_modelo := 0.0
var _ataque_idx := 0
var _pos_anterior := Vector3.ZERO
var _timer_atascado := 0.0
var _anim_run := ""
var _anim_idle := ""
var _anim_ataques := []

# ─── NODOS ────────────────────────────────────────────────────────
@onready var nav: NavigationAgent3D = get_node_or_null("NavigationAgent3D")
@onready var anim: AnimationPlayer = null
@onready var modelo: Node3D = null

# ─── INIT ─────────────────────────────────────────────────────────
func _ready():
	add_to_group("zombies")
	buscar_jugador()
	if nav != null:
		nav.avoidance_enabled = false
	_cargar_modelo_zombie()
	if anim != null:
		anim.root_motion_track = NodePath("")
	color_base = Color(0.9, 0.9, 0.9)
	var barra = preload("res://barra_vida.gd").new()
	barra.position = Vector3(0, 2.5, 0)
	add_child(barra)
	barra.crear(1.0, 0.1)
	barra.actualizar(hp, 80, "Zombie")

func _cargar_modelo_zombie():
	# Ocultar mesh placeholder
	var mesh_viejo = get_node_or_null("MeshInstance3D")
	if mesh_viejo != null:
		mesh_viejo.visible = false

	# Cargar modelo con skeleton
	var modelo_path = "res://assets/animaciones/Model/characterMedium.fbx"
	if not ResourceLoader.exists(modelo_path):
		return
	var escena_z = load(modelo_path)
	if escena_z == null:
		return
	modelo = escena_z.instantiate()
	modelo.name = "ZombieSkin"
	modelo.scale = Vector3(1.5, 1.5, 1.5)
	modelo.position = Vector3(0, -1, 0)
	add_child(modelo)

	# Aplicar skin zombie aleatoria
	var skins = ["res://assets/animaciones/Skins/zombieA.png", "res://assets/animaciones/Skins/zombieC.png"]
	var tex_path = skins[randi() % skins.size()]
	if ResourceLoader.exists(tex_path):
		var textura = load(tex_path)
		_aplicar_textura(modelo, textura)

	# Buscar AnimationPlayer del modelo
	anim = modelo.find_child("AnimationPlayer", true, false)
	if anim == null:
		return
	anim.root_motion_track = NodePath("")

	# Cargar animaciones del pack
	var libs = {"idle": "res://assets/animaciones/Animations/idle.fbx", "run": "res://assets/animaciones/Animations/run.fbx", "jump": "res://assets/animaciones/Animations/jump.fbx"}
	for nombre in libs:
		if ResourceLoader.exists(libs[nombre]):
			var lib = load(libs[nombre])
			if lib is AnimationLibrary:
				if anim.has_animation_library(nombre):
					anim.remove_animation_library(nombre)
				anim.add_animation_library(nombre, lib)

	# Detectar nombres de animación
	_anim_idle = ""
	_anim_run = ""
	_anim_ataques = []
	for lib_name in anim.get_animation_library_list():
		for anim_name in anim.get_animation_library(lib_name).get_animation_list():
			var full = lib_name + "/" + anim_name if lib_name != "" else anim_name
			if lib_name == "idle":
				_anim_idle = full
			elif lib_name == "run":
				_anim_run = full
			elif lib_name == "jump":
				_anim_ataques.append(full)
	if _anim_idle == "":
		_detectar_animaciones()
	if _anim_run == "":
		_anim_run = _anim_idle
	if _anim_ataques.is_empty():
		_anim_ataques.append(_anim_run)
	if _anim_idle != "":
		anim.play(_anim_idle)
	_pos_y_modelo = modelo.position.y

func _aplicar_textura(nodo: Node, textura: Texture2D):
	if nodo is MeshInstance3D:
		var mat = StandardMaterial3D.new()
		mat.albedo_texture = textura
		nodo.material_override = mat
	for hijo in nodo.get_children():
		_aplicar_textura(hijo, textura)

func _detectar_animaciones():
	if anim == null:
		return
	var todas := []
	for lib_name in anim.get_animation_library_list():
		var lib = anim.get_animation_library(lib_name)
		for anim_name in lib.get_animation_list():
			var full = lib_name + "/" + anim_name if lib_name != "" else anim_name
			todas.append(full)
	# Buscar animación de correr
	for a in todas:
		if "run" in a.to_lower() or "fast" in a.to_lower():
			_anim_run = a
			break
	# Buscar idle
	for a in todas:
		if "idle" in a.to_lower():
			_anim_idle = a
			break
	if _anim_idle == "" and todas.size() > 0:
		_anim_idle = todas[0]
	if _anim_run == "":
		_anim_run = _anim_idle
	# Buscar ataques (todo lo que no sea run/idle)
	for a in todas:
		if a != _anim_run and a != _anim_idle:
			_anim_ataques.append(a)
	if _anim_ataques.is_empty() and todas.size() > 0:
		_anim_ataques.append(todas[0])

func _colorear(color: Color):
	var target = get_node_or_null("ZombieSkin")
	if target == null:
		for child in get_children():
			if child is MeshInstance3D:
				var mat = StandardMaterial3D.new()
				mat.albedo_color = color
				child.material_override = mat
		return
	_colorear_recursivo(target, color)

func _colorear_recursivo(nodo: Node, color: Color):
	if nodo is MeshInstance3D:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = color
		nodo.material_override = mat
	for hijo in nodo.get_children():
		_colorear_recursivo(hijo, color)


# ─── LOOP PRINCIPAL ───────────────────────────────────────────────
func _physics_process(delta):
	if modelo != null:
		modelo.position = Vector3(0, _pos_y_modelo, 0)
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
		if anim != null and _anim_idle != "" and anim.current_animation != _anim_idle:
			anim.play(_anim_idle)
	elif distancia <= rango_ataque:
		velocity.x = 0
		velocity.z = 0
		if dir_al_objetivo.length() > 0.1:
			rotation.y = lerp_angle(rotation.y, atan2(dir_al_objetivo.x, dir_al_objetivo.z), 0.2)
		if anim != null and _anim_ataques.size() > 0:
			var ataque_actual = _anim_ataques[_ataque_idx % _anim_ataques.size()]
			if anim.current_animation != ataque_actual:
				anim.play(ataque_actual)
		if puede_atacar:
			atacar()
			_ataque_idx += 1
		_aplicar_separacion()
	else:
		var dir = dir_al_objetivo.normalized()
		# Detectar si está atascado
		var movimiento = global_position.distance_to(_pos_anterior)
		if movimiento < 0.05:
			_timer_atascado += delta
			if _timer_atascado > 0.5:
				dir = dir.rotated(Vector3.UP, randf_range(-1.2, 1.2))
				_timer_atascado = 0.0
		else:
			_timer_atascado = 0.0
		_pos_anterior = global_position
		velocity.x = dir.x * velocidad
		velocity.z = dir.z * velocidad
		if dir.length() > 0.1:
			rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), 0.15)
		if anim != null and _anim_run != "" and anim.current_animation != _anim_run:
			anim.play(_anim_run)
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
	if hp <= 0:
		muriendo = true
		velocity = Vector3.ZERO
		var xp_node = get_node_or_null("/root/SistemaXP")
		if xp_node:
			xp_node.agregar_xp(25)
		if randf() < 0.05:
			_dropear_cargador()
		queue_free()

func _efecto_recibir_dano():
	_colorear(Color(1.0, 0.2, 0.2))
	var modelo_node = get_node_or_null("ZombieSkin")
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
		if dist_sq < 4.0 and dist_sq > 0.0001:
			var dist = sqrt(dist_sq)
			var factor = (2.0 - dist) * 2.0 / dist
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
