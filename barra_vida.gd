extends Node3D

var _fondo: MeshInstance3D
var _relleno: MeshInstance3D
var _label: Label3D
var _ancho := 1.5
var _alto := 0.15
var _mat_fondo: StandardMaterial3D
var _mat_relleno: StandardMaterial3D

func crear(ancho: float = 1.5, alto: float = 0.15):
	_ancho = ancho
	_alto = alto

	# Borde negro (ligeramente más grande)
	var borde = MeshInstance3D.new()
	var mesh_borde = QuadMesh.new()
	mesh_borde.size = Vector2(ancho + 0.06, alto + 0.06)
	borde.mesh = mesh_borde
	var mat_borde = StandardMaterial3D.new()
	mat_borde.albedo_color = Color(0.0, 0.0, 0.0, 0.9)
	mat_borde.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat_borde.no_depth_test = true
	mat_borde.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_borde.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	borde.material_override = mat_borde
	borde.position.z = 0.01
	add_child(borde)

	# Fondo rojo oscuro
	_fondo = MeshInstance3D.new()
	var mesh_fondo = QuadMesh.new()
	mesh_fondo.size = Vector2(ancho, alto)
	_fondo.mesh = mesh_fondo
	_mat_fondo = StandardMaterial3D.new()
	_mat_fondo.albedo_color = Color(0.4, 0.0, 0.0)
	_mat_fondo.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	_mat_fondo.no_depth_test = true
	_mat_fondo.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_fondo.material_override = _mat_fondo
	add_child(_fondo)

	# Relleno de vida
	_relleno = MeshInstance3D.new()
	var mesh_relleno = QuadMesh.new()
	mesh_relleno.size = Vector2(ancho, alto)
	_relleno.mesh = mesh_relleno
	_mat_relleno = StandardMaterial3D.new()
	_mat_relleno.albedo_color = Color(0.0, 1.0, 0.0)
	_mat_relleno.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	_mat_relleno.no_depth_test = true
	_mat_relleno.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_relleno.material_override = _mat_relleno
	_relleno.position.z = -0.01
	add_child(_relleno)

	# Label
	_label = Label3D.new()
	_label.font_size = 36
	_label.outline_size = 10
	_label.position.y = alto + 0.12
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.no_depth_test = true
	_label.modulate = Color.WHITE
	add_child(_label)

func actualizar(hp: int, hp_max: int, nombre: String = ""):
	if hp_max <= 0:
		return
	var porcentaje = float(hp) / float(hp_max)
	porcentaje = clampf(porcentaje, 0.0, 1.0)

	_relleno.scale.x = porcentaje
	_relleno.position.x = (_ancho * (1.0 - porcentaje)) / 2.0

	if porcentaje > 0.5:
		_mat_relleno.albedo_color = Color(0.0, 1.0, 0.0)
	elif porcentaje > 0.25:
		_mat_relleno.albedo_color = Color(1.0, 0.7, 0.0)
	else:
		_mat_relleno.albedo_color = Color(1.0, 0.0, 0.0)

	if nombre != "":
		_label.text = nombre + " " + str(hp) + "/" + str(hp_max)
	else:
		_label.text = str(hp) + "/" + str(hp_max)
