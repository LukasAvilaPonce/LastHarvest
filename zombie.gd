extends CharacterBody3D

@export var velocidad := 2.0
@export var gravedad := 9.8
@export var distancia_perseguir := 15.0
@export var distancia_atacar := 1.5
@export var dano := 10
@export var tiempo_entre_ataques := 1.0

var jugador: Node3D = null
var puede_atacar := true

@onready var nav: NavigationAgent3D = $NavigationAgent3D

func _ready():
	buscar_jugador()

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravedad * delta

	if jugador == null or not is_instance_valid(jugador):
		buscar_jugador()

	if jugador == null or not is_instance_valid(jugador):
		detener_movimiento()
		move_and_slide()
		return

	var distancia = global_position.distance_to(jugador.global_position)

	if distancia < distancia_perseguir:
		nav.target_position = jugador.global_position

		var siguiente_posicion = nav.get_next_path_position()
		var direccion = siguiente_posicion - global_position
		direccion = direccion.normalized()

		velocity.x = direccion.x * velocidad
		velocity.z = direccion.z * velocidad
	else:
		detener_movimiento()

	if distancia < distancia_atacar and puede_atacar:
		atacar()

	move_and_slide()

func buscar_jugador():
	var tree = get_tree()

	if tree == null:
		return

	var escena_actual = tree.current_scene

	if escena_actual != null:
		jugador = escena_actual.get_node_or_null("jugador")

	if jugador == null:
		jugador = get_node_or_null("/root/mundo/jugador")

func detener_movimiento():
	velocity.x = move_toward(velocity.x, 0, velocidad)
	velocity.z = move_toward(velocity.z, 0, velocidad)

func atacar():
	if not puede_atacar:
		return

	if not is_inside_tree():
		return

	if jugador == null or not is_instance_valid(jugador):
		buscar_jugador()
		return

	puede_atacar = false

	if jugador.has_method("recibir_dano"):
		jugador.recibir_dano(dano)

	var tree = get_tree()

	if tree == null:
		return

	await tree.create_timer(tiempo_entre_ataques).timeout

	if not is_inside_tree():
		return

	puede_atacar = true
