extends Node3D

var tipo_semilla := ""
var cantidad := 1
var recogida := false
var tiempo := 0.0
var vel_y := 0.0
var en_suelo := false
var altura_suelo := 1.0

const COLORES = {
	"semillas_caminante": Color(0.2, 0.7, 0.2),
	"semillas_girasol": Color(1.0, 0.85, 0.0),
	"semillas_hongo": Color(0.4, 0.2, 0.0),
	"semillas_enredadera": Color(0.0, 0.3, 0.0),
	"semillas_chile": Color(0.9, 0.1, 0.0),
	"semillas_arbol": Color(0.0, 0.4, 0.3),
}

const NOMBRES = {
	"semillas_caminante": "Caminante",
	"semillas_girasol": "Girasol",
	"semillas_hongo": "Hongo",
	"semillas_enredadera": "Enredadera",
	"semillas_chile": "Chile",
	"semillas_arbol": "Centinela",
}

func _ready():
	var mesh = MeshInstance3D.new()
	var esfera = SphereMesh.new()
	esfera.radius = 0.4
	esfera.height = 0.8
	mesh.mesh = esfera
	var mat = StandardMaterial3D.new()
	mat.albedo_color = COLORES.get(tipo_semilla, Color.WHITE)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material_override = mat
	add_child(mesh)

	var label = Label3D.new()
	label.text = "[E] " + NOMBRES.get(tipo_semilla, tipo_semilla) + " x" + str(cantidad)
	label.font_size = 22
	label.outline_size = 8
	label.position = Vector3(0, 1.2, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = COLORES.get(tipo_semilla, Color.WHITE)
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
		global_position.y = altura_suelo + sin(tiempo * 2.0) * 0.15
	rotation_degrees.y += 60 * delta

	var jugador = get_tree().current_scene.get_node_or_null("jugador")
	if jugador == null:
		return
	if global_position.distance_to(jugador.global_position) < 3.5:
		if Input.is_action_just_pressed("recoger"):
			recogida = true
			if jugador.has_method("agregar_item"):
				jugador.agregar_item(tipo_semilla, cantidad)
			queue_free()
