extends Node3D

var hp := 30
var hp_maximo := 30
var activa := false
var muriendo := false
var timer_crecimiento := 5.0
var radio_deteccion := 7.0
var radio_explosion := 8.0
var dano_explosion := 80

const COLOR_SEMILLA = Color(0.5, 0.5, 0.5)
const COLOR_ACTIVA = Color(0.4, 0.2, 0.0)

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
	for z in get_tree().get_nodes_in_group("zombies"):
		if is_instance_valid(z) and z is Node3D and not z.get("muriendo"):
			if global_position.distance_to(z.global_position) <= radio_deteccion:
				_explotar()
				return

func _activar():
	activa = true
	mesh.scale = Vector3(1.0, 1.0, 1.0)
	material.albedo_color = COLOR_ACTIVA
	barra = preload("res://barra_vida.gd").new()
	barra.position = Vector3(0, 2.0, 0)
	add_child(barra)
	barra.crear(1.2, 0.12)
	barra.actualizar(hp, hp_maximo, "Hongo")
	print("Hongo Explosivo ACTIVO — esperando zombie a ", radio_deteccion, "m")

func _explotar():
	muriendo = true
	for z in get_tree().get_nodes_in_group("zombies"):
		if is_instance_valid(z) and z is Node3D and not z.get("muriendo"):
			if global_position.distance_to(z.global_position) <= radio_explosion:
				if z.has_method("recibir_dano"):
					z.recibir_dano(dano_explosion)
	print("HONGO EXPLOTO — daño ", dano_explosion, " en radio ", radio_explosion)
	_efecto_explosion()

func _efecto_explosion():
	var esfera = MeshInstance3D.new()
	var mesh_esfera = SphereMesh.new()
	mesh_esfera.radius = 0.5
	mesh_esfera.height = 1.0
	esfera.mesh = mesh_esfera
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.4, 0.0, 0.8)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.no_depth_test = true
	esfera.material_override = mat
	esfera.global_position = global_position + Vector3(0, 1, 0)
	get_tree().current_scene.add_child(esfera)
	var tween = esfera.create_tween()
	tween.tween_property(esfera, "scale", Vector3(radio_explosion * 2, radio_explosion * 2, radio_explosion * 2), 0.4)
	tween.parallel().tween_property(mat, "albedo_color", Color(1.0, 0.1, 0.0, 0.0), 0.4)
	tween.tween_callback(esfera.queue_free)
	await get_tree().create_timer(0.1).timeout
	queue_free()

func recibir_dano(cantidad: int):
	if muriendo:
		return
	hp -= cantidad
	if barra != null:
		barra.actualizar(hp, hp_maximo, "Hongo")
	if hp <= 0:
		_explotar()
