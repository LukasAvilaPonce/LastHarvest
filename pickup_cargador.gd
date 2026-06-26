extends Node3D

var recogido := false

func _ready():
	var mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.3, 0.15, 0.5)
	mesh.mesh = box
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.8, 0.6, 0.0)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material_override = mat
	mesh.position.y = 0.5
	add_child(mesh)

	var label = Label3D.new()
	label.text = "+30"
	label.font_size = 20
	label.position = Vector3(0, 1.2, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color(1.0, 0.8, 0.0)
	add_child(label)

func _process(_delta):
	if recogido:
		return
	var jugador = get_tree().current_scene.get_node_or_null("jugador")
	if jugador == null:
		return
	if global_position.distance_to(jugador.global_position) < 3.0:
		if Input.is_action_just_pressed("recoger"):
			recogido = true
			if jugador.has_method("recoger_cargador"):
				jugador.recoger_cargador(30)
			queue_free()
