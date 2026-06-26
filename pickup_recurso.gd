extends Node3D

var tipo := ""
var cantidad := 1
var recogido := false
var tiempo := 0.0
var vel_y := 0.0
var en_suelo := false
var altura_suelo := 1.0

func _ready():
	var mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.4, 0.4, 0.4)
	mesh.mesh = box
	var mat = StandardMaterial3D.new()
	if tipo == "agua":
		mat.albedo_color = Color(0.3, 0.5, 1.0)
	else:
		mat.albedo_color = Color(0.5, 0.3, 0.1)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material_override = mat
	add_child(mesh)

	var label = Label3D.new()
	label.text = "[E] " + tipo.capitalize() + " x" + str(cantidad)
	label.font_size = 20
	label.outline_size = 6
	label.position = Vector3(0, 1.0, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = mat.albedo_color
	add_child(label)

func _process(delta):
	if recogido:
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
		global_position.y = altura_suelo + sin(tiempo * 2.0) * 0.1
	var jugador = get_tree().current_scene.get_node_or_null("jugador")
	if jugador == null:
		return
	if global_position.distance_to(jugador.global_position) < 3.5:
		if Input.is_action_just_pressed("recoger"):
			recogido = true
			if jugador.has_method("agregar_item"):
				jugador.agregar_item(tipo, cantidad)
			queue_free()
