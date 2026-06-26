extends Node3D

var hp := 80
var hp_maximo := 80
var activa := false
var muriendo := false
var timer_crecimiento := 5.0
var radio_efecto := 6.0
var timer_check := 0.0
var intervalo_check := 0.5
var zombies_afectados := []

const COLOR_SEMILLA = Color(0.5, 0.5, 0.5)
const COLOR_ACTIVA = Color(0.0, 0.3, 0.0)

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
	timer_check -= delta
	if timer_check <= 0:
		timer_check = intervalo_check
		_aplicar_efecto()

func _activar():
	activa = true
	mesh.scale = Vector3(1.0, 1.0, 1.0)
	material.albedo_color = COLOR_ACTIVA
	barra = preload("res://barra_vida.gd").new()
	barra.position = Vector3(0, 2.0, 0)
	add_child(barra)
	barra.crear(1.2, 0.12)
	barra.actualizar(hp, hp_maximo, "Enredadera")
	print("Enredadera ACTIVA — ralentiza en radio ", radio_efecto, "m")

func _aplicar_efecto():
	var en_rango := []
	for z in get_tree().get_nodes_in_group("zombies"):
		if is_instance_valid(z) and z is Node3D and not z.get("muriendo"):
			if global_position.distance_to(z.global_position) <= radio_efecto:
				en_rango.append(z)
				z.velocidad = 1.5
	for z in zombies_afectados:
		if is_instance_valid(z) and not z in en_rango:
			z.velocidad = 8.0
	zombies_afectados = en_rango

func recibir_dano(cantidad: int):
	if muriendo:
		return
	hp -= cantidad
	if barra != null:
		barra.actualizar(hp, hp_maximo, "Enredadera")
	if hp <= 0:
		_morir()

func _morir():
	muriendo = true
	for z in zombies_afectados:
		if is_instance_valid(z):
			z.velocidad = 8.0
	queue_free()
