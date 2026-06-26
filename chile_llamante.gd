extends Node3D

var hp := 70
var hp_maximo := 70
var activa := false
var muriendo := false
var timer_crecimiento := 5.0
var dano := 20
var distancia_ataque := 15.0
var timer_ataque := 0.0
var tiempo_entre_ataques := 3.0

const COLOR_SEMILLA = Color(0.5, 0.5, 0.5)
const COLOR_ACTIVA = Color(0.9, 0.1, 0.0)

@onready var mesh := $MeshInstance3D
var material: StandardMaterial3D
var barra: Node3D

func _ready():
	add_to_group("plantas")
	mesh.scale = Vector3(0.3, 0.3, 0.3)
	material = StandardMaterial3D.new()
	material.albedo_color = COLOR_SEMILLA
	mesh.material_override = material

func _process(delta):
	if muriendo:
		return
	if not activa:
		timer_crecimiento -= delta
		if timer_crecimiento <= 0:
			_activar()
		return
	rotation_degrees.y += 60 * delta
	timer_ataque -= delta
	if timer_ataque <= 0:
		timer_ataque = tiempo_entre_ataques
		_atacar_linea()

func _activar():
	activa = true
	mesh.scale = Vector3(1.0, 1.0, 1.0)
	material.albedo_color = COLOR_ACTIVA
	barra = preload("res://barra_vida.gd").new()
	barra.position = Vector3(0, 2.0, 0)
	add_child(barra)
	barra.crear(1.2, 0.12)
	barra.actualizar(hp, hp_maximo, "Chile")
	print("Chile Llamante ACTIVO — rotando y disparando cada ", tiempo_entre_ataques, "s")

func _atacar_linea():
	var objetivo = _buscar_zombie_cercano()
	if objetivo == null:
		return
	var origen = global_position + Vector3(0, 1, 0)
	var dir = (objetivo.global_position - global_position)
	dir.y = 0
	if dir.length() < 0.1:
		return
	dir = dir.normalized()
	var destino = origen + dir * distancia_ataque
	look_at(global_position + dir, Vector3.UP)
	var space_state = get_world_3d().direct_space_state
	var excluir := []
	var golpeo := false
	for _i in range(10):
		var query = PhysicsRayQueryParameters3D.create(origen, destino)
		query.exclude = excluir
		var resultado = space_state.intersect_ray(query)
		if resultado.is_empty():
			break
		var hit = resultado["collider"]
		excluir.append(hit.get_rid())
		if hit.is_in_group("zombies") and hit.has_method("recibir_dano"):
			hit.recibir_dano(dano)
			golpeo = true
	_efecto_rayo(origen, destino, golpeo)

func _buscar_zombie_cercano() -> Node3D:
	var mejor: Node3D = null
	var mejor_dist := 99999.0
	for z in get_tree().get_nodes_in_group("zombies"):
		if is_instance_valid(z) and z is Node3D and not z.get("muriendo"):
			var d = global_position.distance_to(z.global_position)
			if d <= distancia_ataque and d < mejor_dist:
				mejor_dist = d
				mejor = z
	return mejor

func _efecto_rayo(desde: Vector3, hasta: Vector3, golpeo: bool):
	var rayo = MeshInstance3D.new()
	var mesh_rayo = BoxMesh.new()
	var largo = desde.distance_to(hasta)
	mesh_rayo.size = Vector3(0.08, 0.08, largo)
	rayo.mesh = mesh_rayo
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.3, 0.0, 0.9) if golpeo else Color(1.0, 0.6, 0.2, 0.5)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.no_depth_test = true
	rayo.material_override = mat
	var punto_medio = (desde + hasta) / 2.0
	rayo.global_position = punto_medio
	rayo.look_at(hasta)
	get_tree().current_scene.add_child(rayo)
	var tween = rayo.create_tween()
	tween.tween_property(mat, "albedo_color:a", 0.0, 0.3)
	tween.tween_callback(rayo.queue_free)

func recibir_dano(cantidad: int):
	if muriendo:
		return
	hp -= cantidad
	if barra != null:
		barra.actualizar(hp, hp_maximo, "Chile")
	if hp <= 0:
		muriendo = true
		queue_free()
