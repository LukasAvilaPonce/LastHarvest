extends "res://zombie.gd"

var fase_endurecido := false
var timer_proyectil := 0.0
var intervalo_proyectil := 3.0
var dano_proyectil := 30
var velocidad_proyectil := 15.0
var hp_maximo_crystal := 600

func _ready():
	super._ready()
	velocidad = 5
	hp = 600
	dano = 20
	tiempo_entre_ataques = 2.0
	distancia_atacar = 12.0
	distancia_perseguir = 800.0
	scale = Vector3(1.3, 1.3, 1.3)
	for child in get_children():
		if child.has_method("actualizar"):
			child.position = Vector3(0, 3.5, 0)
			child.actualizar(hp, hp_maximo_crystal, "Crystal")
			break
	_colorear(Color(0.5, 0.2, 1.0))
	print(">>> CRYSTAL MUTATE CARGADO <<<")

func _physics_process(delta):
	super._physics_process(delta)
	if muriendo:
		return
	if objetivo_actual != null and is_instance_valid(objetivo_actual):
		timer_proyectil -= delta
		if timer_proyectil <= 0:
			timer_proyectil = intervalo_proyectil
			_lanzar_hielo()
	if hp <= 300 and not fase_endurecido:
		fase_endurecido = true
		velocidad = 8
		intervalo_proyectil = 1.5
		print("CRYSTAL ENDURECIDO — fase 2")

func recibir_dano(cantidad: int):
	if muriendo:
		return
	var dano_real = int(cantidad * 0.5) if fase_endurecido else cantidad
	super.recibir_dano(dano_real)
	for child in get_children():
		if child.has_method("actualizar"):
			child.actualizar(hp, hp_maximo_crystal, "Crystal")
			break

func _lanzar_hielo():
	if objetivo_actual == null or not is_instance_valid(objetivo_actual):
		return
	var esfera = MeshInstance3D.new()
	var mesh_esfera = SphereMesh.new()
	mesh_esfera.radius = 0.35
	mesh_esfera.height = 0.7
	esfera.mesh = mesh_esfera
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.8, 1.0)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	esfera.material_override = mat

	var origen = global_position + Vector3(0, 1.5, 0)
	var destino = objetivo_actual.global_position + Vector3(0, 1, 0)
	var dir = (destino - origen).normalized()

	var proyectil = preload("res://proyectil_hielo.gd").new()
	proyectil.add_child(esfera)
	get_tree().current_scene.add_child(proyectil)
	proyectil.global_position = origen
	proyectil.direccion = dir
	proyectil.velocidad = velocidad_proyectil
	proyectil.dano = dano_proyectil
	print("Crystal lanzó hielo hacia: ", objetivo_actual.name)
