extends "res://zombie.gd"

func _ready():
	super._ready()
	velocidad = 22
	hp = 20
	dano = 8
	tiempo_entre_ataques = 0.3
	distancia_atacar = 1.8
	scale = Vector3(0.75, 0.75, 0.75)
	for child in get_children():
		if child.has_method("actualizar"):
			child.actualizar(hp, 20, "Runner")
			break
	color_base = Color(1.0, 0.4, 0.7)
	_colorear(color_base)
	print(">>> RUNNER CARGADO <<<")

func _aplicar_separacion():
	var fuerza := Vector3.ZERO
	for z in get_tree().get_nodes_in_group("zombies"):
		if z == self or not is_instance_valid(z):
			continue
		var diff = global_position - z.global_position
		diff.y = 0
		var dist = diff.length()
		if dist < 0.6 and dist > 0.01:
			fuerza += diff.normalized() * (0.6 - dist) * 3.0
	velocity.x += fuerza.x
	velocity.z += fuerza.z

func _physics_process(delta):
	super._physics_process(delta)
	if anim != null and not muriendo:
		if velocity.length() > 0.5:
			anim.speed_scale = 1.8
		else:
			anim.speed_scale = 1.0

func recibir_dano(cantidad: int):
	super.recibir_dano(cantidad)
	for child in get_children():
		if child.has_method("actualizar"):
			child.actualizar(hp, 20, "Runner")
			break
