extends "res://zombie.gd"

var radio_explosion := 10.0
var dano_explosion := 30
var cayendo := true
var timer_caida := 0.0

func _ready():
	super._ready()
	velocidad = 18
	hp = 30
	dano = 0
	tiempo_entre_ataques = 999
	distancia_atacar = 3.0
	scale = Vector3(1.3, 1.3, 1.3)
	color_base = Color(1.0, 0.5, 0.0)
	_colorear(color_base)
	# Barra naranja
	for child in get_children():
		if child.has_method("actualizar"):
			child.actualizar(hp, 30, "Kamikaze")
			break
	# Empezar en el aire
	cayendo = true
	call_deferred("_iniciar_caida")

func _iniciar_caida():
	global_position.y = 40.0
	print("KAMIKAZE spawneado en: ", snapped(global_position, Vector3(0.1,0.1,0.1)))

func _physics_process(delta):
	if modelo != null:
		modelo.position = Vector3(0, _pos_y_modelo, 0)
	if muriendo:
		velocity = Vector3.ZERO
		move_and_slide()
		return

	if cayendo:
		global_position.y -= 8.0 * delta
		_crear_estela()
		if global_position.y <= 1.5:
			global_position.y = 1.5
			cayendo = false
			_efecto_aterrizaje()
			print("KAMIKAZE aterrizó en: ", snapped(global_position, Vector3(0.1,0.1,0.1)))
		return

	super._physics_process(delta)

var _timer_estela := 0.0

func _crear_estela():
	_timer_estela += get_physics_process_delta_time()
	if _timer_estela < 0.05:
		return
	_timer_estela = 0.0
	var punto = MeshInstance3D.new()
	var mesh_p = SphereMesh.new()
	mesh_p.radius = 0.3
	mesh_p.height = 0.6
	punto.mesh = mesh_p
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.5, 0.0, 0.8)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	punto.material_override = mat
	punto.global_position = global_position
	get_tree().current_scene.add_child(punto)
	var tween = punto.create_tween()
	tween.tween_property(punto, "scale", Vector3(0.1, 0.1, 0.1), 0.5)
	tween.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.5)
	tween.tween_callback(punto.queue_free)

func _efecto_aterrizaje():
	var impacto = MeshInstance3D.new()
	var mesh_imp = SphereMesh.new()
	mesh_imp.radius = 0.5
	mesh_imp.height = 1.0
	impacto.mesh = mesh_imp
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.5, 0.0, 0.6)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	impacto.material_override = mat
	impacto.global_position = global_position
	get_tree().current_scene.add_child(impacto)
	var tween = impacto.create_tween()
	tween.tween_property(impacto, "scale", Vector3(4, 1, 4), 0.3)
	tween.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.3)
	tween.tween_callback(impacto.queue_free)

# Override atacar — explota en vez de golpear
func atacar():
	if not puede_atacar or not is_inside_tree():
		return
	_explotar()

func _explotar():
	muriendo = true
	velocity = Vector3.ZERO
	# Daño a todo en radio
	var jugador_nodo = get_tree().current_scene.get_node_or_null("jugador")
	if jugador_nodo != null and is_instance_valid(jugador_nodo):
		if global_position.distance_to(jugador_nodo.global_position) <= radio_explosion:
			if jugador_nodo.has_method("recibir_dano"):
				jugador_nodo.recibir_dano(dano_explosion)
	for planta in get_tree().get_nodes_in_group("plantas"):
		if is_instance_valid(planta) and planta is Node3D:
			if global_position.distance_to(planta.global_position) <= radio_explosion:
				if planta.has_method("recibir_dano"):
					planta.recibir_dano(dano_explosion)
	for madre in get_tree().get_nodes_in_group("planta_madre"):
		if is_instance_valid(madre) and madre is Node3D:
			if global_position.distance_to(madre.global_position) <= radio_explosion:
				if madre.has_method("recibir_dano"):
					madre.recibir_dano(dano_explosion)
	_efecto_explosion()

func _efecto_explosion():
	# Esfera naranja expandiéndose
	var esfera = MeshInstance3D.new()
	var mesh_esfera = SphereMesh.new()
	mesh_esfera.radius = 1.0
	mesh_esfera.height = 2.0
	esfera.mesh = mesh_esfera
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.4, 0.0, 0.8)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	esfera.material_override = mat
	esfera.global_position = global_position + Vector3(0, 1, 0)
	get_tree().current_scene.add_child(esfera)
	var tween = esfera.create_tween()
	tween.tween_property(esfera, "scale", Vector3(radio_explosion, radio_explosion, radio_explosion), 0.4)
	tween.parallel().tween_property(mat, "albedo_color", Color(1.0, 0.1, 0.0, 0.0), 0.4)
	tween.tween_callback(esfera.queue_free)
	# Partículas de fuego
	for i in range(8):
		var part = MeshInstance3D.new()
		var mesh_p = SphereMesh.new()
		mesh_p.radius = 0.3
		mesh_p.height = 0.6
		part.mesh = mesh_p
		var mat_p = StandardMaterial3D.new()
		mat_p.albedo_color = Color(1.0, randf_range(0.2, 0.6), 0.0, 0.9)
		mat_p.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat_p.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		part.material_override = mat_p
		part.global_position = global_position + Vector3(0, 1, 0)
		get_tree().current_scene.add_child(part)
		var angulo = (float(i) / 8.0) * TAU
		var destino = part.global_position + Vector3(cos(angulo) * 5, randf_range(2, 5), sin(angulo) * 5)
		var tw = part.create_tween()
		tw.tween_property(part, "global_position", destino, 0.5)
		tw.parallel().tween_property(mat_p, "albedo_color:a", 0.0, 0.5)
		tw.tween_callback(part.queue_free)
	queue_free()

func recibir_dano(cantidad: int):
	if muriendo:
		return
	hp -= cantidad
	for child in get_children():
		if child.has_method("actualizar"):
			child.actualizar(hp, 30, "Kamikaze")
			break
	if hp <= 0:
		_explotar()
