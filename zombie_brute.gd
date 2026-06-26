extends "res://zombie.gd"

func _ready():
	super._ready()
	velocidad = 3
	hp = 400
	dano = 40
	tiempo_entre_ataques = 2.5
	distancia_atacar = 4.0
	scale = Vector3(1.8, 1.8, 1.8)
	for child in get_children():
		if child.has_method("actualizar"):
			child.position = Vector3(0, 4.0, 0)
			child.actualizar(hp, 400, "Brute")
			break
	_colorear(Color(0.2, 0.8, 0.2))
	print(">>> BRUTE CARGADO <<<")

func _aplicar_separacion():
	var fuerza := Vector3.ZERO
	for z in get_tree().get_nodes_in_group("zombies"):
		if z == self or not is_instance_valid(z):
			continue
		var diff = global_position - z.global_position
		diff.y = 0
		var dist = diff.length()
		if dist < 2.5 and dist > 0.01:
			fuerza += diff.normalized() * (2.5 - dist) * 3.0
	velocity.x += fuerza.x
	velocity.z += fuerza.z

func recibir_dano(cantidad: int):
	print("BRUTE recibió golpe: -", cantidad, " HP")
	super.recibir_dano(cantidad)
	for child in get_children():
		if child.has_method("actualizar"):
			child.actualizar(hp, 400, "Brute")
			break

func _physics_process(delta):
	super._physics_process(delta)
	if anim != null:
		anim.speed_scale = 0.6
