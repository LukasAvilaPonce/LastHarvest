extends Node3D

var recogida := false
var tiempo := 0.0
var vel_y := 0.0
var en_suelo := false
var altura_suelo := 1.5

func _ready():
	var mesh = MeshInstance3D.new()
	var star = SphereMesh.new()
	star.radius = 0.35
	star.height = 0.7
	mesh.mesh = star
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.5, 1.0)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true
	mat.emission = Color(0.3, 0.5, 1.0)
	mat.emission_energy_multiplier = 2.0
	mesh.material_override = mat
	add_child(mesh)

	var luz = OmniLight3D.new()
	luz.light_color = Color(0.3, 0.5, 1.0)
	luz.light_energy = 2.0
	luz.omni_range = 4.0
	add_child(luz)

	var label = Label3D.new()
	label.text = "[E] Mejora"
	label.font_size = 24
	label.outline_size = 8
	label.position = Vector3(0, 1.2, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color(0.3, 0.7, 1.0)
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
	else:
		global_position.y = altura_suelo + sin(tiempo * 2.0) * 0.2
	rotation_degrees.y += 90 * delta

	var jugador = get_tree().current_scene.get_node_or_null("jugador")
	if jugador == null:
		return
	if global_position.distance_to(jugador.global_position) < 3.5:
		if Input.is_action_just_pressed("recoger"):
			recogida = true
			if jugador.has_method("recoger_mejora"):
				jugador.recoger_mejora()
			queue_free()
