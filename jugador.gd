extends CharacterBody3D
var vida = 100
var puede_recibir_dano = true

var velocidad = 5.0
var gravedad = 9.8
var sensibilidad = 0.003

var inventario = {
	"semillas": 0,
	"agua": 0,
	"abono": 0
}

@onready var hud_vida = get_tree().get_root().get_node("mundo/CanvasLayer/Label2")

@onready var camara = $Camera3D

@onready var hud_semillas = get_tree().get_root().get_node("mundo/CanvasLayer/Label")

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(evento):
	if evento is InputEventMouseMotion:
		rotate_y(-evento.relative.x * sensibilidad)
		camara.rotate_x(-evento.relative.y * sensibilidad)
		camara.rotation.x = clamp(camara.rotation.x, -1.2, 1.2)
	if evento.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravedad * delta

	var direccion = Vector3.ZERO
	if Input.is_action_pressed("mover_adelante"):  direccion -= transform.basis.z
	if Input.is_action_pressed("mover_atras"):     direccion += transform.basis.z
	if Input.is_action_pressed("mover_izquierda"): direccion -= transform.basis.x
	if Input.is_action_pressed("mover_derecha"):   direccion += transform.basis.x

	if direccion:
		velocity.x = direccion.normalized().x * velocidad
		velocity.z = direccion.normalized().z * velocidad
	else:
		velocity.x = move_toward(velocity.x, 0, velocidad)
		velocity.z = move_toward(velocity.z, 0, velocidad)

	move_and_slide()

func recoger_semilla():
	inventario["semillas"] += 1
	hud_semillas.text = "Semillas: " + str(inventario["semillas"])


func _on_semilla_semilla_recogida():
	recoger_semilla()
	
func recibir_dano(cantidad):
	if puede_recibir_dano:
		vida -= cantidad
		puede_recibir_dano = false
		hud_vida.text = "Vida: " + str(vida)
		
		await get_tree().create_timer(1.0).timeout
		puede_recibir_dano = true
		
		if vida <= 0:
			get_tree().reload_current_scene()
