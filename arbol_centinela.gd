extends Node3D

var hp := 150
var hp_maximo := 150
var activa := false
var muriendo := false
var timer_crecimiento := 5.0
var dano := 25
var radio_ataque := 12.0
var timer_ataque := 0.0
var tiempo_entre_ataques := 1.5

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
		_atacar_cercano()

func _activar():
	activa = true
	mesh.scale = Vector3(1.5, 1.5, 1.5)
	material.albedo_color = COLOR_ACTIVA
	barra = preload("res://barra_vida.gd").new()
	barra.position = Vector3(0, 3.0, 0)
	add_child(barra)
	barra.crear(1.5, 0.15)
	barra.actualizar(hp, hp_maximo, "Centinela")
	print("Arbol Centinela ACTIVO — atacando cada ", tiempo_entre_ataques, "s en radio ", radio_ataque, "m")

func _atacar_cercano():
	var mejor: Node3D = null
	var mejor_dist := 99999.0
	for z in get_tree().get_nodes_in_group("zombies"):
		if is_instance_valid(z) and z is Node3D and not z.get("muriendo"):
			var d = global_position.distance_to(z.global_position)
			if d <= radio_ataque and d < mejor_dist:
				mejor_dist = d
				mejor = z
	if mejor != null and mejor.has_method("recibir_dano"):
		mejor.recibir_dano(dano)

func recibir_dano(cantidad: int):
	if muriendo:
		return
	hp -= cantidad
	if barra != null:
		barra.actualizar(hp, hp_maximo, "Centinela")
	if hp <= 0:
		muriendo = true
		queue_free()
