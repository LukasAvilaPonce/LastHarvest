extends CharacterBody3D

var velocidad = 2.0
var gravedad = 9.8
var jugador = null
var puede_atacar = true

@onready var nav = $NavigationAgent3D

func _ready():
	jugador = get_tree().get_root().get_node("mundo/jugador")

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravedad * delta

	if jugador:
		var distancia = global_position.distance_to(jugador.global_position)
		
		if distancia < 15.0:
			nav.target_position = jugador.global_position
			var direccion = nav.get_next_path_position() - global_position
			direccion = direccion.normalized()
			velocity.x = direccion.x * velocidad
			velocity.z = direccion.z * velocidad
		else:
			velocity.x = move_toward(velocity.x, 0, velocidad)
			velocity.z = move_toward(velocity.z, 0, velocidad)

		# Ataca si está muy cerca
		if distancia < 1.5 and puede_atacar:
			atacar()

	move_and_slide()

func atacar():
	puede_atacar = false
	jugador.recibir_dano(10)
	await get_tree().create_timer(1.0).timeout
	puede_atacar = true
