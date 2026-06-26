extends Node3D

var recogida := false
var tiempo := 0.0
var vel_y := 0.0
var en_suelo := false
var altura_suelo := 1.5

func _ready():
	var escena_arma = load("res://assets/arma/arma.glb")
	if escena_arma != null:
		var modelo = escena_arma.instantiate()
		modelo.name = "ArmaModelo"
		modelo.scale = Vector3(0.8, 0.8, 0.8)
		modelo.position.y = 1.0
		modelo.rotation_degrees.y = 90
		add_child(modelo)
	else:
		var mesh = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(0.6, 0.3, 1.2)
		mesh.mesh = box
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.3, 0.3, 0.3)
		mesh.material_override = mat
		add_child(mesh)

	var label = Label3D.new()
	label.text = "[E] Recoger Arma"
	label.font_size = 28
	label.position = Vector3(0, 2.5, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color(1.0, 0.8, 0.0)
	label.outline_size = 8
	add_child(label)

func _process(delta):
	if recogida:
		return
	tiempo += delta
	if not en_suelo:
		vel_y -= 9.8 * delta
		global_position.y += vel_y * delta
		if global_position.y <= altura_suelo:
			global_position.y = altura_suelo
			en_suelo = true
			vel_y = 0.0
	else:
		global_position.y = altura_suelo + sin(tiempo * 1.5) * 0.15
	rotation_degrees.y = sin(tiempo * 2.0) * 15.0

	var jugador = get_tree().current_scene.get_node_or_null("jugador")
	if jugador == null:
		return
	if global_position.distance_to(jugador.global_position) < 3.5:
		if Input.is_action_just_pressed("recoger"):
			recogida = true
			if jugador.has_method("recoger_arma"):
				jugador.recoger_arma()
			queue_free()
