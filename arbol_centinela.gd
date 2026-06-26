extends Node3D

var hp := 150
var hp_maximo := 150
var activa := false
var muriendo := false
var timer_crecimiento := 5.0
var dano := 10
var radio_ataque := 20.0
var timer_ataque := 0.0
var tiempo_entre_ataques := 1.0

const COLOR_SEMILLA = Color(0.5, 0.5, 0.5)
const COLOR_ACTIVA = Color(0.0, 0.4, 0.3)

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
	timer_ataque -= delta
	if timer_ataque <= 0:
		timer_ataque = tiempo_entre_ataques
		_disparar()

func _activar():
	activa = true
	mesh.scale = Vector3(1.5, 1.5, 1.5)
	material.albedo_color = COLOR_ACTIVA
	barra = preload("res://barra_vida.gd").new()
	barra.position = Vector3(0, 3.0, 0)
	add_child(barra)
	barra.crear(1.5, 0.15)
	barra.actualizar(hp, hp_maximo, "Torreta")
	print("Torreta ACTIVA — dispara cada ", tiempo_entre_ataques, "s en radio ", radio_ataque, "m")

func _disparar():
	var objetivo = _buscar_zombie_cercano()
	if objetivo == null:
		return
	if objetivo.has_method("recibir_dano"):
		objetivo.recibir_dano(dano)
	_efecto_disparo(objetivo)

func _buscar_zombie_cercano() -> Node3D:
	var mejor: Node3D = null
	var mejor_dist := 99999.0
	for z in get_tree().get_nodes_in_group("zombies"):
		if is_instance_valid(z) and z is Node3D and not z.get("muriendo"):
			var d = global_position.distance_to(z.global_position)
			if d <= radio_ataque and d < mejor_dist:
				mejor_dist = d
				mejor = z
	return mejor

func _efecto_disparo(objetivo: Node3D):
	var origen = global_position + Vector3(0, 2.0, 0)
	var destino = objetivo.global_position + Vector3(0, 1.0, 0)

	# Línea de disparo
	var rayo = MeshInstance3D.new()
	var mesh_rayo = BoxMesh.new()
	var largo = origen.distance_to(destino)
	mesh_rayo.size = Vector3(0.06, 0.06, largo)
	rayo.mesh = mesh_rayo
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.0, 1.0, 0.5, 0.9)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rayo.material_override = mat
	var medio = (origen + destino) / 2.0
	rayo.global_position = medio
	rayo.look_at(destino)
	get_tree().current_scene.add_child(rayo)
	var tween_rayo = rayo.create_tween()
	tween_rayo.tween_property(mat, "albedo_color:a", 0.0, 0.15)
	tween_rayo.tween_callback(rayo.queue_free)

	# Impacto en el zombie
	var impacto = MeshInstance3D.new()
	var mesh_imp = SphereMesh.new()
	mesh_imp.radius = 0.2
	mesh_imp.height = 0.4
	impacto.mesh = mesh_imp
	var mat_imp = StandardMaterial3D.new()
	mat_imp.albedo_color = Color(0.0, 1.0, 0.5, 0.8)
	mat_imp.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_imp.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	impacto.material_override = mat_imp
	impacto.global_position = destino
	get_tree().current_scene.add_child(impacto)
	var tween_imp = impacto.create_tween()
	tween_imp.tween_property(impacto, "scale", Vector3(2, 2, 2), 0.2)
	tween_imp.parallel().tween_property(mat_imp, "albedo_color:a", 0.0, 0.2)
	tween_imp.tween_callback(impacto.queue_free)

func recibir_dano(cantidad: int):
	if muriendo:
		return
	hp -= cantidad
	if barra != null:
		barra.actualizar(hp, hp_maximo, "Torreta")
	if hp <= 0:
		muriendo = true
		queue_free()
