extends CharacterBody3D

# ─── TIPOS ────────────────────────────────────────────────────────
enum Tipo {
	CAMINANTE,
	GIRASOL,
}

@export var tipo: Tipo = Tipo.CAMINANTE

# ─── STATS COMPARTIDOS ────────────────────────────────────────────
var hp := 100
var activa := false
var muriendo := false
var timer_crecimiento := 5.0

# ─── STATS CAMINANTE ──────────────────────────────────────────────
var dano_melee := 40
var radio_deteccion := 200
var radio_ataque := 3.0
var tiempo_entre_ataques := 1.5
var timer_ataque := 0.0
var velocidad_movimiento := 10
var posicion_base := Vector3.ZERO
var objetivo: Node3D = null
var estado_caminante := "esperando"
var timer_busqueda := 0.0
var intervalo_busqueda := 0.5

# ─── STATS GIRASOL ────────────────────────────────────────────────
var curacion_girasol := 10
var radio_curacion := 2.0
var tiempo_entre_curaciones := 30.0
var timer_curacion := 30.0

# ─── NODOS Y VISUAL ───────────────────────────────────────────────
@onready var mesh := $MeshInstance3D
var material: StandardMaterial3D

const COLOR_SEMILLA = Color(0.8, 0.6, 0.0)
const COLORES_ACTIVA = {
	Tipo.CAMINANTE: Color(0.2, 0.7, 0.2),
	Tipo.GIRASOL:   Color(1.0, 0.85, 0.0),
}

# ─── INIT ─────────────────────────────────────────────────────────
func _ready():
	posicion_base = global_position
	mesh.scale = Vector3(0.3, 0.3, 0.3)
	material = StandardMaterial3D.new()
	material.albedo_color = COLOR_SEMILLA
	mesh.material_override = material
	add_to_group("plantas")

# ─── LOOP PRINCIPAL ───────────────────────────────────────────────
func _process(delta):
	if muriendo:
		return
	if not activa:
		timer_crecimiento -= delta
		if timer_crecimiento <= 0:
			activar()
		return
	match tipo:
		Tipo.GIRASOL:
			_proceso_girasol(delta)
		Tipo.CAMINANTE:
			_actualizar_estado_caminante(delta)

func _physics_process(delta):
	if muriendo or not activa or tipo != Tipo.CAMINANTE:
		# Gravedad antes de activar para que caiga al suelo
		if not activa and not muriendo:
			if not is_on_floor():
				velocity.y -= 9.8 * delta
			move_and_slide()
		return
	# Gravedad siempre activa
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	match estado_caminante:
		"yendo":
			_moverse_hacia_objetivo(delta)
		"volviendo":
			_volver_a_base(delta)
		"esperando", "golpeando":
			velocity.x = move_toward(velocity.x, 0, velocidad_movimiento)
			velocity.z = move_toward(velocity.z, 0, velocidad_movimiento)
			move_and_slide()

func activar():
	activa = true
	mesh.scale = Vector3(1.0, 1.0, 1.0)
	material.albedo_color = COLORES_ACTIVA[tipo]
	posicion_base = global_position
	print("Planta activa: ", Tipo.keys()[tipo])

# ─── CAMINANTE ────────────────────────────────────────────────────
func _actualizar_estado_caminante(delta):
	match estado_caminante:
		"esperando":
			_buscar_zombie_cercano(delta)
		"golpeando":
			timer_ataque -= delta
			if timer_ataque <= 0:
				_golpear_objetivo()

func _buscar_zombie_cercano(delta):
	timer_busqueda -= delta
	if timer_busqueda > 0:
		return
	timer_busqueda = intervalo_busqueda
	for z in get_tree().get_nodes_in_group("zombies"):
		if is_instance_valid(z) and z is Node3D:
			var pos_self = global_position
			var pos_z = z.global_position
			pos_self.y = 0
			pos_z.y = 0
			if pos_self.distance_to(pos_z) <= radio_deteccion:
				objetivo = z
				estado_caminante = "yendo"
				return

func _moverse_hacia_objetivo(delta):
	if not is_instance_valid(objetivo):
		objetivo = null
		estado_caminante = "volviendo"
		return
	if global_position.distance_to(posicion_base) > radio_deteccion * 1.5:
		objetivo = null
		estado_caminante = "volviendo"
		return
	var pos_self = global_position
	var pos_obj = objetivo.global_position
	pos_self.y = 0
	pos_obj.y = 0
	var distancia = pos_self.distance_to(pos_obj)
	if distancia <= radio_ataque:
		velocity.x = 0
		velocity.z = 0
		estado_caminante = "golpeando"
		timer_ataque = 0.0
	else:
		var dir = (objetivo.global_position - global_position).normalized()
		dir.y = 0
		velocity.x = dir.x * velocidad_movimiento
		velocity.z = dir.z * velocidad_movimiento
	move_and_slide()

func _golpear_objetivo():
	if not is_instance_valid(objetivo):
		objetivo = null
		estado_caminante = "esperando"
		timer_busqueda = 0.0
		return
	var pos_self = global_position
	var pos_obj = objetivo.global_position
	pos_self.y = 0
	pos_obj.y = 0
	if pos_self.distance_to(pos_obj) > radio_ataque * 1.5:
		estado_caminante = "yendo"
		return
	if objetivo.has_method("recibir_dano"):
		objetivo.recibir_dano(dano_melee)
		print("Caminante golpeó zombie: ", dano_melee, " daño")
	timer_ataque = tiempo_entre_ataques

func _volver_a_base(delta):
	if global_position.distance_to(posicion_base) < 0.2:
		velocity.x = 0
		velocity.z = 0
		global_position.x = posicion_base.x
		global_position.z = posicion_base.z
		estado_caminante = "esperando"
		timer_busqueda = 0.0
	else:
		for z in get_tree().get_nodes_in_group("zombies"):
			if is_instance_valid(z) and z is Node3D:
				var d = global_position.distance_to(z.global_position)
				if d <= radio_deteccion * 0.5:
					objetivo = z
					estado_caminante = "yendo"
					return
		var dir = (posicion_base - global_position).normalized()
		dir.y = 0
		velocity.x = dir.x * velocidad_movimiento
		velocity.z = dir.z * velocidad_movimiento
	move_and_slide()

# ─── GIRASOL ──────────────────────────────────────────────────────
func _proceso_girasol(delta):
	timer_curacion -= delta
	if timer_curacion <= 0:
		timer_curacion = tiempo_entre_curaciones
		_curar_plantas_cercanas()

func _curar_plantas_cercanas():
	var curadas = 0
	for planta in get_tree().get_nodes_in_group("plantas"):
		if planta == self or not planta is Node3D:
			continue
		if global_position.distance_to(planta.global_position) <= radio_curacion:
			if planta.has_method("recibir_curacion"):
				planta.recibir_curacion(curacion_girasol)
				curadas += 1
	print("Girasol curó ", curadas, " plantas (+", curacion_girasol, " HP)")

# ─── DAÑO Y CURACIÓN ──────────────────────────────────────────────
func recibir_dano(cantidad: int):
	if muriendo:
		return
	hp -= cantidad
	print("Planta recibió daño: -", cantidad, " HP (total: ", hp, ")")
	if hp <= 0:
		_morir()
		return
	material.albedo_color = Color(1.0, 0.1, 0.1)
	await get_tree().create_timer(0.15).timeout
	if is_inside_tree() and activa and not muriendo:
		material.albedo_color = COLORES_ACTIVA[tipo]

func recibir_curacion(cantidad: int):
	if muriendo:
		return
	hp += cantidad
	print("Planta curada: +", cantidad, " HP (total: ", hp, ")")
	material.albedo_color = Color(1.0, 1.0, 0.3)
	await get_tree().create_timer(0.2).timeout
	if is_inside_tree() and activa and not muriendo:
		material.albedo_color = COLORES_ACTIVA[tipo]

func _morir():
	muriendo = true
	activa = false
	print("Planta destruida: ", Tipo.keys()[tipo])
	queue_free()
