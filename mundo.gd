extends Node3D

@export var semilla_escena = preload("res://semilla.tscn")
@export var zombie_escena = preload("res://zombie.tscn")

# ─── INICIO MANUAL ────────────────────────────────────────────────
@export var accion_iniciar_oleadas := "accionar"
@export var tiempo_mantener_accion := 5.0
var sistema_oleadas_activo := false
var timer_mantener_accion := 0.0

# ─── SEMILLAS ─────────────────────────────────────────────────────
var semillas_en_mapa = 0
var max_semillas_en_mapa = 5
var timer_semilla = 0.0
var intervalo_semilla = 24.0

# Zonas donde aparecen las semillas (cerca de la base)
var zonas_spawn_semillas = [
	Vector3(70, 1.5, 5),
	Vector3(70, 1.5, -5),
	Vector3(75, 1.5, 10),
	Vector3(75, 1.5, -10),
	Vector3(80, 1.5, 0),
	Vector3(65, 1.5, 8),
	Vector3(65, 1.5, -8),
	Vector3(72, 1.5, 15),
	Vector3(72, 1.5, -15),
	Vector3(68, 1.5, 0),
]

# ─── OLEADAS ──────────────────────────────────────────────────────
enum Estado { ESPERA_INICIO, LOOT, OLEADA, CAOS }
var estado_actual = Estado.ESPERA_INICIO
var timer_fase = 0.0
var duracion_loot = 30.0
var duracion_oleada = 120.0
var duracion_caos = 60.0
var numero_oleada = 0

# ─── ZOMBIES ──────────────────────────────────────────────────────
var zombies_base = 1
var zombies_extra_por_oleada = 3
var zombies_por_oleada = 5
var zombies_spawneados = 0
var timer_spawn_zombie = 1.0
var intervalo_spawn_zombie = 30.0
var modo_caos = false

# Spawn en el lado opuesto a la Planta Madre (X negativo, frente amplio)
var zona_spawn_min := Vector3(-100.0, 2.0, -90.0)
var zona_spawn_max := Vector3(-80.0, 2.0,  90.0)
var separacion_spawn_zombie = 3.5
var intentos_spawn_zombie = 20

# ─── HUD ──────────────────────────────────────────────────────────
@onready var jugador = get_node_or_null("jugador")
@onready var label_timer: Label = get_node_or_null("CanvasLayer/LabelTimer")
@onready var label_fase: Label  = get_node_or_null("CanvasLayer/LabelFase")

# ─── INIT ─────────────────────────────────────────────────────────
func _ready():
	randomize()
	mostrar_espera_inicio()

# ─── LOOP PRINCIPAL ───────────────────────────────────────────────
func _process(delta):
	if not sistema_oleadas_activo:
		procesar_inicio_manual(delta)
		return

	timer_fase -= delta
	timer_semilla -= delta
	actualizar_hud_timer()

	match estado_actual:
		Estado.LOOT:
			if timer_semilla <= 0 and semillas_en_mapa < max_semillas_en_mapa:
				spawnear_semilla()
				timer_semilla = intervalo_semilla

		Estado.OLEADA:
			timer_spawn_zombie -= delta
			if timer_spawn_zombie <= 0:
				spawnear_zombie()
				timer_spawn_zombie = intervalo_spawn_zombie
			if timer_fase <= duracion_caos and not modo_caos:
				activar_modo_caos()

		Estado.CAOS:
			timer_spawn_zombie -= delta
			if timer_spawn_zombie <= 0:
				for i in range(3):
					spawnear_zombie()
				timer_spawn_zombie = 5.0

	if timer_fase <= 0:
		if estado_actual == Estado.LOOT:
			iniciar_fase_oleada()
		else:
			iniciar_fase_loot()

# ─── INICIO MANUAL ────────────────────────────────────────────────
func procesar_inicio_manual(delta):
	if not InputMap.has_action(accion_iniciar_oleadas):
		actualizar_label_fase("Falta crear la accion: " + accion_iniciar_oleadas)
		if label_timer != null:
			label_timer.text = "--:--"
		return

	if Input.is_action_pressed(accion_iniciar_oleadas):
		timer_mantener_accion += delta
		var restante = max(tiempo_mantener_accion - timer_mantener_accion, 0.0)
		actualizar_label_fase("Manteniendo accion... no sueltes")
		if label_timer != null:
			label_timer.text = "Inicia en %.1fs" % restante
		if timer_mantener_accion >= tiempo_mantener_accion:
			sistema_oleadas_activo = true
			timer_mantener_accion = 0.0
			iniciar_fase_loot()
	else:
		if timer_mantener_accion > 0.0:
			timer_mantener_accion = 0.0
		mostrar_espera_inicio()

func mostrar_espera_inicio():
	estado_actual = Estado.ESPERA_INICIO
	actualizar_label_fase("Mantén '" + accion_iniciar_oleadas + "' por " + str(tiempo_mantener_accion) + "s para iniciar")
	if label_timer != null:
		label_timer.text = "PAUSA"

# ─── FASES ────────────────────────────────────────────────────────
func iniciar_fase_loot():
	estado_actual = Estado.LOOT
	timer_fase = duracion_loot
	timer_semilla = 0.0
	semillas_en_mapa = 0
	modo_caos = false
	if jugador != null and jugador.has_method("nueva_oleada"):
		jugador.nueva_oleada()
	# Dropear loot de la Planta Madre al terminar oleada
	var plantas_madre = get_tree().get_nodes_in_group("planta_madre")
	if plantas_madre.size() > 0:
		plantas_madre[0].dropear_loot(numero_oleada)
	actualizar_label_fase("FASE LOOT — Busca recursos")
	print("--- FASE LOOT iniciada ---")

func iniciar_fase_oleada():
	estado_actual = Estado.OLEADA
	timer_fase = duracion_oleada
	numero_oleada += 1
	zombies_spawneados = 0
	modo_caos = false
	zombies_por_oleada = zombies_base + (numero_oleada * zombies_extra_por_oleada)
	for i in range(20):
		spawnear_zombie()
	timer_spawn_zombie = intervalo_spawn_zombie
	actualizar_label_fase("OLEADA " + str(numero_oleada) + " — Sobrevive (" + str(zombies_por_oleada) + " zombies)")
	print("--- OLEADA ", numero_oleada, " — ", zombies_por_oleada, " zombies ---")

func activar_modo_caos():
	modo_caos = true
	estado_actual = Estado.CAOS
	timer_spawn_zombie = 0.0
	actualizar_label_fase("⚠ MODO CAOS ⚠")
	print("--- MODO CAOS ACTIVADO ---")

# ─── SPAWN SEMILLAS ───────────────────────────────────────────────
func spawnear_semilla():
	if semillas_en_mapa >= max_semillas_en_mapa:
		return
	var pos = zonas_spawn_semillas[randi() % zonas_spawn_semillas.size()]
	var nueva_semilla = semilla_escena.instantiate()
	nueva_semilla.position = pos
	add_child(nueva_semilla)
	nueva_semilla.semilla_recogida.connect(_on_semilla_recogida)
	semillas_en_mapa += 1

# ─── SPAWN ZOMBIES ────────────────────────────────────────────────
func spawnear_zombie():
	var pos = obtener_posicion_spawn_zombie_segura()
	var nuevo_zombie = zombie_escena.instantiate()
	add_child(nuevo_zombie)
	nuevo_zombie.global_position = pos
	nuevo_zombie.add_to_group("zombies")
	if nuevo_zombie is CharacterBody3D:
		nuevo_zombie.velocity = Vector3.ZERO
	zombies_spawneados += 1
	print("Zombie spawneado: ", zombies_spawneados, "/", zombies_por_oleada)

func obtener_posicion_spawn_zombie_segura() -> Vector3:
	for _intento in range(intentos_spawn_zombie):
		var pos = Vector3(
			randf_range(zona_spawn_min.x, zona_spawn_max.x),
			zona_spawn_min.y,
			randf_range(zona_spawn_min.z, zona_spawn_max.z)
		)
		if not hay_zombie_cerca(pos):
			return pos
	# Fallback
	return Vector3(
		randf_range(zona_spawn_min.x, zona_spawn_max.x),
		zona_spawn_min.y,
		randf_range(zona_spawn_min.z, zona_spawn_max.z)
	)

func hay_zombie_cerca(pos: Vector3) -> bool:
	for zombie in get_tree().get_nodes_in_group("zombies"):
		if zombie is Node3D and zombie.global_position.distance_to(pos) < separacion_spawn_zombie:
			return true
	return false

# ─── SEÑALES ──────────────────────────────────────────────────────
func _on_semilla_recogida():
	semillas_en_mapa -= 1
	if jugador != null and jugador.has_method("recoger_semilla"):
		jugador.recoger_semilla()

# ─── HUD ──────────────────────────────────────────────────────────
func actualizar_hud_timer():
	if label_timer == null:
		return
	var segundos = int(timer_fase)
	var minutos = int(segundos / 60.0)
	segundos = segundos % 60
	label_timer.text = "%02d:%02d" % [minutos, segundos]

func actualizar_label_fase(texto: String):
	if label_fase != null:
		label_fase.text = texto
