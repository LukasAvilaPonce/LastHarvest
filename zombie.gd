extends CharacterBody3D

# ─── STATS ────────────────────────────────────────────────────────
@export var velocidad := 3
@export var gravedad := 9.8
@export var distancia_perseguir := 500.0
@export var distancia_atacar := 2.5
@export var dano := 1
@export var tiempo_entre_ataques := 1

# ─── ESTADO ───────────────────────────────────────────────────────
var timer_nav := 0.0
var intervalo_nav := 0.10
var jugador: Node3D = null
var objetivo_actual: Node3D = null
var puede_atacar := true
var hp := 50

# ─── NODOS ────────────────────────────────────────────────────────
@onready var nav: NavigationAgent3D = $NavigationAgent3D
@onready var anim: AnimationPlayer = $copzombie_l_actisdato/AnimationPlayer
@onready var modelo: Node3D = $copzombie_l_actisdato

# ─── INIT ─────────────────────────────────────────────────────────
func _ready():
	add_to_group("zombies")
	buscar_jugador()
	anim.play("zombie idle/mixamo_com")
	anim.animation_started.connect(_on_animation_started)
	anim.animation_finished.connect(_on_animation_finished)

func _on_animation_started(_anim_name: String):
	modelo.position.x = 0
	modelo.position.z = 0

func _on_animation_finished(_anim_name: String):
	modelo.position.x = 0
	modelo.position.z = 0

# ─── LOOP PRINCIPAL ───────────────────────────────────────────────
func _physics_process(delta):
	# Gravedad
	if not is_on_floor():
		velocity.y -= gravedad * delta

	# Buscar jugador si se perdió
	if jugador == null or not is_instance_valid(jugador):
		buscar_jugador()
	if jugador == null or not is_instance_valid(jugador):
		detener_movimiento()
		move_and_slide()
		return

	# ── Elegir objetivo ──────────────────────────────────────────
	# 1. Destino final: Planta Madre (o jugador si no hay)
	var madre: Node3D = null
	var plantas_madre = get_tree().get_nodes_in_group("planta_madre")
	if plantas_madre.size() > 0 and is_instance_valid(plantas_madre[0]):
		madre = plantas_madre[0]

	objetivo_actual = madre if madre != null else jugador

	# 2. Si el jugador está MUY cerca (5m), atacarlo primero
	if jugador != null and is_instance_valid(jugador):
		var d_jugador = global_position.distance_to(jugador.global_position)
		if d_jugador < 5.0:
			objetivo_actual = jugador

	# 3. Si hay una planta defensiva muy cerca (5m), atacarla de paso
	for planta in get_tree().get_nodes_in_group("plantas"):
		if is_instance_valid(planta) and planta.get("activa"):
			var d = global_position.distance_to(planta.global_position)
			if d < 5.0:
				objetivo_actual = planta
				break

	# ── Distancia horizontal al objetivo (ignora Y) ───────────────
	var pos_zombie = global_position
	var pos_obj = objetivo_actual.global_position
	pos_zombie.y = 0
	pos_obj.y = 0
	var distancia_al_objetivo = pos_zombie.distance_to(pos_obj)
	var rango_ataque_real = max(distancia_atacar, 2.5)

	if distancia_al_objetivo < distancia_perseguir:
		if distancia_al_objetivo <= rango_ataque_real:
			_estado_atacar()
		else:
			_estado_mover()
			_aplicar_separacion()
	else:
		_estado_idle()

	move_and_slide()

# ─── ESTADOS ──────────────────────────────────────────────────────
func _estado_mover():
	nav.avoidance_enabled = false
	var direccion = (objetivo_actual.global_position - global_position).normalized()
	direccion.y = 0
	velocity.x = direccion.x * velocidad
	velocity.z = direccion.z * velocidad
	if direccion.length() > 0.1:
		rotation.y = lerp_angle(rotation.y, atan2(direccion.x, direccion.z), 0.15)
	if anim.current_animation != "zombie run/mixamo_com":
		anim.play("zombie run/mixamo_com")

func _estado_atacar():
	nav.avoidance_enabled = false
	detener_movimiento()
	var dir_obj = (objetivo_actual.global_position - global_position)
	dir_obj.y = 0
	if dir_obj.length() > 0.1:
		rotation.y = lerp_angle(rotation.y, atan2(dir_obj.x, dir_obj.z), 0.2)
	if anim.current_animation != "zombie attack/mixamo_com":
		anim.play("zombie attack/mixamo_com")
	if puede_atacar:
		atacar()

func _estado_idle():
	nav.avoidance_enabled = true
	detener_movimiento()
	if anim.current_animation != "zombie idle/mixamo_com":
		anim.play("zombie idle/mixamo_com")

# ─── ATAQUE ───────────────────────────────────────────────────────
func atacar():
	if not puede_atacar or not is_inside_tree():
		return
	if objetivo_actual == null or not is_instance_valid(objetivo_actual):
		return
	puede_atacar = false
	if objetivo_actual.has_method("recibir_dano"):
		objetivo_actual.recibir_dano(dano)
		print("Zombie atacó a: ", objetivo_actual.name)
	get_tree().create_timer(tiempo_entre_ataques).timeout.connect(
		func():
			if is_inside_tree():
				puede_atacar = true
	)

# ─── DAÑO Y MUERTE ────────────────────────────────────────────────
func recibir_dano(cantidad):
	hp -= cantidad
	print("Zombie recibió daño, HP: ", hp)
	if hp <= 0:
		anim.play("zombie death/mixamo_com")
		await get_tree().create_timer(1.5).timeout
		queue_free()

# ─── SEPARACIÓN MANUAL ENTRE ZOMBIES ─────────────────────────────
func _aplicar_separacion():
	var fuerza_separacion := Vector3.ZERO
	var radio_separacion := 1.2
	for z in get_tree().get_nodes_in_group("zombies"):
		if z == self or not is_instance_valid(z):
			continue
		var diff = global_position - z.global_position
		diff.y = 0
		var dist = diff.length()
		if dist < radio_separacion and dist > 0.01:
			fuerza_separacion += diff.normalized() * (radio_separacion - dist) * 3.0
	velocity.x += fuerza_separacion.x
	velocity.z += fuerza_separacion.z

# ─── UTILIDADES ───────────────────────────────────────────────────
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
