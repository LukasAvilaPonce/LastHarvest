extends CharacterBody3D

@export var vida_maxima := 100
@export var vida := 100
@export var velocidad := 5.0
@export var velocidad_correr := 10.0
@export var gravedad := 9.8
@export var sensibilidad := 0.003
@export var shake_duracion := 0.25
@export var shake_fuerza := 0.08

var puede_recibir_dano := true
var inventario_abierto := false
var muerto := false
var shake_tiempo := 0.0
var shake_fuerza_actual := 0.0
var posicion_original_camara: Vector3

var inventario := {
	"semillas": 0,
	"agua": 0,
	"abono": 0
}

@onready var camara: Camera3D = $Camera3D
@onready var escena_actual = get_tree().current_scene
@onready var hud_vida: Label = escena_actual.get_node_or_null("CanvasLayer/Label2")
@onready var inventario_ui = escena_actual.get_node_or_null("CanvasLayer/InventarioUI")
@onready var efectos_vida = escena_actual.get_node_or_null("CanvasLayer/EfectosVida")

func _ready():
	randomize()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	posicion_original_camara = camara.position

	vida = clampi(vida, 0, vida_maxima)

	actualizar_hud_vida()
	actualizar_efecto_vida()

	if inventario_ui != null:
		inventario_ui.actualizar(inventario)
	else:
		print("ERROR: No se encontró CanvasLayer/InventarioUI")

	if efectos_vida == null:
		print("ERROR: No se encontró CanvasLayer/EfectosVida")

func _input(evento):
	if muerto:
		return

	if evento is InputEventMouseMotion and not inventario_abierto:
		mover_camara(evento)

	if evento.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	if evento.is_action_pressed("inventario"):
		alternar_inventario()

func _physics_process(delta):
	if muerto:
		actualizar_shake(delta)
		return

	aplicar_gravedad(delta)
	mover_jugador()
	actualizar_shake(delta)
	move_and_slide()

func mover_camara(evento):
	rotate_y(-evento.relative.x * sensibilidad)
	camara.rotate_x(-evento.relative.y * sensibilidad)
	camara.rotation.x = clamp(camara.rotation.x, -1.2, 1.2)

func aplicar_gravedad(delta):
	if not is_on_floor():
		velocity.y -= gravedad * delta

func mover_jugador():
	var velocidad_actual = velocidad_correr if Input.is_action_pressed("correr") else velocidad

	var input_movimiento = Input.get_vector(
		"mover_izquierda",
		"mover_derecha",
		"mover_adelante",
		"mover_atras"
	)

	var direccion = (transform.basis.x * input_movimiento.x) + (transform.basis.z * input_movimiento.y)
	direccion = direccion.normalized()

	if direccion:
		velocity.x = direccion.x * velocidad_actual
		velocity.z = direccion.z * velocidad_actual
	else:
		velocity.x = move_toward(velocity.x, 0, velocidad_actual)
		velocity.z = move_toward(velocity.z, 0, velocidad_actual)

func alternar_inventario():
	inventario_abierto = not inventario_abierto

	if inventario_ui == null:
		print("ERROR: InventarioUI no encontrado")
		return

	if inventario_abierto:
		inventario_ui.actualizar(inventario)
		inventario_ui.abrir()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		inventario_ui.cerrar()
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func agregar_item(nombre_item: String, cantidad: int = 1):
	if not inventario.has(nombre_item):
		inventario[nombre_item] = 0

	inventario[nombre_item] += cantidad

	if inventario_ui != null:
		inventario_ui.actualizar(inventario)

func recoger_semilla():
	agregar_item("semillas", 1)

func _on_semilla_semilla_recogida():
	recoger_semilla()

func iniciar_shake(fuerza: float = shake_fuerza, duracion: float = shake_duracion):
	shake_tiempo = duracion
	shake_fuerza_actual = fuerza

func actualizar_shake(delta):
	if shake_tiempo > 0:
		shake_tiempo -= delta

		var offset = Vector3(
			randf_range(-shake_fuerza_actual, shake_fuerza_actual),
			randf_range(-shake_fuerza_actual, shake_fuerza_actual),
			0
		)

		camara.position = posicion_original_camara + offset
	else:
		camara.position = posicion_original_camara

func recibir_dano(cantidad):
	if muerto:
		return

	if not puede_recibir_dano:
		return

	vida -= cantidad
	vida = clampi(vida, 0, vida_maxima)

	puede_recibir_dano = false
	actualizar_hud_vida()
	actualizar_efecto_vida()
	iniciar_shake()

	if vida <= 0:
		morir()
		return

	await get_tree().create_timer(1.0).timeout

	if not muerto:
		puede_recibir_dano = true

func morir():
	if muerto:
		return

	muerto = true
	puede_recibir_dano = false
	velocity = Vector3.ZERO

	await get_tree().create_timer(0.35).timeout

	if is_inside_tree():
		get_tree().reload_current_scene()

func actualizar_hud_vida():
	if hud_vida != null:
		hud_vida.text = "Vida: " + str(vida)

func actualizar_efecto_vida():
	if efectos_vida != null and efectos_vida.has_method("actualizar_vida"):
		efectos_vida.actualizar_vida(vida, vida_maxima)
