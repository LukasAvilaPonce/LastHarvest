extends Node3D

var direccion := Vector3.ZERO
var velocidad := 15.0
var dano := 30
var tiempo_vida := 0.0
var max_tiempo := 4.0
var trail_timer := 0.0

func _physics_process(delta):
	tiempo_vida += delta
	if tiempo_vida >= max_tiempo:
		queue_free()
		return
	global_position += direccion * velocidad * delta
	look_at(global_position + direccion, Vector3.UP)

	trail_timer += delta
	if trail_timer >= 0.05:
		trail_timer = 0.0
		_crear_trail()

	# Revisar impacto con jugador
	var jugador = get_tree().current_scene.get_node_or_null("jugador")
	if jugador != null and is_instance_valid(jugador):
		if global_position.distance_to(jugador.global_position) < 1.5:
			if jugador.has_method("recibir_dano"):
				jugador.recibir_dano(dano)
			_efecto_impacto()
			queue_free()
			return
	# Revisar impacto con plantas
	for planta in get_tree().get_nodes_in_group("plantas"):
		if is_instance_valid(planta) and planta is Node3D:
			if global_position.distance_to(planta.global_position) < 1.5:
				if planta.has_method("recibir_dano"):
					planta.recibir_dano(dano)
				_efecto_impacto()
				queue_free()
				return
	# Revisar impacto con Planta Madre
	for madre in get_tree().get_nodes_in_group("planta_madre"):
		if is_instance_valid(madre) and madre is Node3D:
			if global_position.distance_to(madre.global_position) < 4.0:
				if madre.has_method("recibir_dano"):
					madre.recibir_dano(dano)
				_efecto_impacto()
				queue_free()
				return

func _crear_trail():
	var punto = MeshInstance3D.new()
	var mesh_p = SphereMesh.new()
	mesh_p.radius = 0.1
	mesh_p.height = 0.2
	punto.mesh = mesh_p
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.8, 1.0, 0.6)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	punto.material_override = mat
	punto.global_position = global_position
	get_tree().current_scene.add_child(punto)
	var tween = punto.create_tween()
	tween.tween_property(mat, "albedo_color:a", 0.0, 0.3)
	tween.tween_callback(punto.queue_free)

func _efecto_impacto():
	var impacto = MeshInstance3D.new()
	var mesh_imp = SphereMesh.new()
	mesh_imp.radius = 0.3
	mesh_imp.height = 0.6
	impacto.mesh = mesh_imp
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.8, 1.0, 0.8)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	impacto.material_override = mat
	impacto.global_position = global_position
	get_tree().current_scene.add_child(impacto)
	var tween = impacto.create_tween()
	tween.tween_property(impacto, "scale", Vector3(3, 3, 3), 0.3)
	tween.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.3)
	tween.tween_callback(impacto.queue_free)
