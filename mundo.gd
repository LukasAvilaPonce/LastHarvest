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
enum Estado { ESPERA_INICIO, LOOT, OLEADA, CAOS, LIMPIEZA }
var estado_actual = Estado.ESPERA_INICIO
var timer_fase = 0.0
var timer_limpieza = 0.0
var duracion_loot = 30.0
var duracion_oleada = 120.0
var duracion_caos = 60.0
var numero_oleada = 0

# ─── ZOMBIES ──────────────────────────────────────────────────────
var zombies_base = 1
var zombies_extra_por_oleada = 3
var zombies_por_oleada = 5
var zombies_spawneados = 0
var boss_spawneado := false
var timer_spawn_zombie = 1.0
var intervalo_spawn_zombie = 30.0
var modo_caos = false

# Spawn en el lado opuesto a la Planta Madre (X negativo, frente amplio)
var zona_spawn_min := Vector3(-100.0, 2.0, -40.0)
var zona_spawn_max := Vector3(-80.0, 2.0,  40.0)
var separacion_spawn_zombie = 3.5
var intentos_spawn_zombie = 20

# ─── HUD ──────────────────────────────────────────────────────────
@onready var jugador = get_node_or_null("jugador")
@onready var label_timer: Label = get_node_or_null("CanvasLayer/LabelTimer")
@onready var label_fase: Label  = get_node_or_null("CanvasLayer/LabelFase")

# ─── INIT ─────────────────────────────────────────────────────────
func _ready():
	mostrar_espera_inicio()

# ─── LOOP PRINCIPAL ───────────────────────────────────────────────
func _input(evento):
	if evento is InputEventKey and evento.pressed and evento.keycode == KEY_X:
		if not sistema_oleadas_activo:
			sistema_oleadas_activo = true
			iniciar_fase_loot()
			print(">>> SKIP: oleadas iniciadas")
		elif estado_actual == Estado.LOOT:
			timer_fase = 0
			print(">>> SKIP: loot saltado")
		else:
			for z in get_tree().get_nodes_in_group("zombies"):
				if is_instance_valid(z):
					z.queue_free()
			if estado_actual == Estado.LIMPIEZA:
				iniciar_fase_loot()
			else:
				timer_fase = 0
			print(">>> SKIP: oleada ", numero_oleada, " saltada")

func _process(delta):
	if not sistema_oleadas_activo:
		procesar_inicio_manual(delta)
		return

	match estado_actual:
		Estado.LOOT:
			timer_fase -= delta
			timer_semilla -= delta
			actualizar_hud_timer()
			if timer_semilla <= 0 and semillas_en_mapa < max_semillas_en_mapa:
				spawnear_semilla()
				timer_semilla = intervalo_semilla
			if timer_fase <= 0:
				iniciar_fase_oleada()

		Estado.OLEADA:
			timer_fase -= delta
			actualizar_hud_timer()
			timer_spawn_zombie -= delta
			if timer_spawn_zombie <= 0:
				spawnear_zombie()
				timer_spawn_zombie = intervalo_spawn_zombie
			if timer_fase <= duracion_caos and not modo_caos:
				activar_modo_caos()
			if timer_fase <= 0:
				_iniciar_limpieza()

		Estado.CAOS:
			timer_fase -= delta
			actualizar_hud_timer()
			timer_spawn_zombie -= delta
			if timer_spawn_zombie <= 0:
				for i in range(3):
					spawnear_zombie()
				timer_spawn_zombie = 5.0
			if timer_fase <= 0:
				_iniciar_limpieza()

		Estado.LIMPIEZA:
			timer_limpieza += delta
			_actualizar_timer_limpieza()
			var zombies_vivos = _contar_zombies_vivos()
			if zombies_vivos == 0:
				print("--- Todos los zombies eliminados ---")
				iniciar_fase_loot()
			else:
				actualizar_label_fase("Elimina los zombies restantes: " + str(zombies_vivos))

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
	if jugador != null and jugador.has_method("desbloquear_planta_por_oleada"):
		jugador.desbloquear_planta_por_oleada(numero_oleada)
	# Dropear loot de la Planta Madre al terminar oleada
	var plantas_madre = get_tree().get_nodes_in_group("planta_madre")
	if plantas_madre.size() > 0:
		plantas_madre[0].dropear_loot(numero_oleada)
	var xp_node = get_node_or_null("/root/SistemaXP")
	if xp_node and numero_oleada > 0:
		xp_node.agregar_xp(100 * numero_oleada)
		xp_node.completar_oleada()
		print("XP de oleada: +", 100 * numero_oleada)
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
	actualizar_label_fase("MODO CAOS")
	print("--- MODO CAOS ACTIVADO ---")

func _iniciar_limpieza():
	estado_actual = Estado.LIMPIEZA
	timer_limpieza = 0.0
	actualizar_label_fase("Elimina los zombies restantes...")
	print("--- LIMPIEZA: esperando que mueran todos los zombies ---")

func _contar_zombies_vivos() -> int:
	var count = 0
	for z in get_tree().get_nodes_in_group("zombies"):
		if is_instance_valid(z) and not z.get("muriendo"):
			count += 1
	return count

func _actualizar_timer_limpieza():
	if label_timer == null:
		return
	var segundos = int(timer_limpieza)
	var minutos = int(segundos / 60.0)
	segundos = segundos % 60
	label_timer.text = "+" + "%02d:%02d" % [minutos, segundos]

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
	var tipo_escena: String = "res://zombie.tscn"

	match numero_oleada:
		1, 2:
			if zombies_spawneados == 0 or zombies_spawneados == 1:
				tipo_escena = "res://zombie_runner.tscn"
			elif zombies_spawneados == 2:
				tipo_escena = "res://zombie_brute.tscn"
			else:
				tipo_escena = "res://zombie.tscn"
		3, 4:
			var idx = zombies_spawneados % 8
			match idx:
				0, 1, 2, 3:
					tipo_escena = "res://zombie_runner.tscn"
				4, 5:
					tipo_escena = "res://zombie_brute.tscn"
				6, 7:
					tipo_escena = "res://zombie_crystal.tscn"
				_:
					tipo_escena = "res://zombie.tscn"
		5:
			var rand = randf()
			if rand < 0.3:
				tipo_escena = "res://zombie_runner.tscn"
			elif rand < 0.5:
				tipo_escena = "res://zombie_brute.tscn"
			elif rand < 0.7:
				tipo_escena = "res://zombie_crystal.tscn"
			else:
				tipo_escena = "res://zombie.tscn"
		6:
			if not boss_spawneado:
				boss_spawneado = true
				_spawnear_boss()
				return
			tipo_escena = "res://zombie_runner.tscn" if randf() < 0.5 else "res://zombie.tscn"
		_:
			var rand = randf()
			if rand < 0.1:
				tipo_escena = "res://zombie_crystal.tscn"
			elif rand < 0.3:
				tipo_escena = "res://zombie_brute.tscn"
			elif rand < 0.6:
				tipo_escena = "res://zombie_runner.tscn"
			else:
				tipo_escena = "res://zombie.tscn"

	var escena = load(tipo_escena) if ResourceLoader.exists(tipo_escena) else zombie_escena
	if escena == null:
		escena = zombie_escena
	var nuevo_zombie = escena.instantiate()
	add_child(nuevo_zombie)
	nuevo_zombie.global_position = pos
	if nuevo_zombie is CharacterBody3D:
		nuevo_zombie.velocity = Vector3.ZERO
	zombies_spawneados += 1
	print("Zombie spawneado [", tipo_escena.get_file(), "]: ", zombies_spawneados)

func _spawnear_boss():
	actualizar_label_fase("ALGO SE ACERCA...")
	if label_timer != null:
		label_timer.text = "!!!"
	print("--- BOSS INCOMING... esperando 5 segundos ---")
	_secuencia_boss()

func _secuencia_boss():
	await get_tree().create_timer(2.0).timeout
	if not is_inside_tree():
		return
	actualizar_label_fase("LA TIERRA TIEMBLA...")

	await get_tree().create_timer(3.0).timeout
	if not is_inside_tree():
		return

	var pos_boss = Vector3(
		(zona_spawn_min.x + zona_spawn_max.x) / 2.0,
		zona_spawn_min.y,
		0
	)

	# Spawnear escolta de zombies alrededor del boss
	var tipos_escolta = [
		"res://zombie_runner.tscn",
		"res://zombie_brute.tscn",
		"res://zombie_runner.tscn",
		"res://zombie.tscn",
		"res://zombie_runner.tscn",
		"res://zombie_crystal.tscn",
		"res://zombie_runner.tscn",
		"res://zombie.tscn",
	]
	for i in range(tipos_escolta.size()):
		var angulo = (float(i) / tipos_escolta.size()) * TAU
		var offset = Vector3(cos(angulo) * 8, 0, sin(angulo) * 8)
		var escena_path = tipos_escolta[i]
		var escena = load(escena_path) if ResourceLoader.exists(escena_path) else zombie_escena
		if escena == null:
			escena = zombie_escena
		var z = escena.instantiate()
		add_child(z)
		z.global_position = pos_boss + offset
		if z is CharacterBody3D:
			z.velocity = Vector3.ZERO

	# Spawnear boss
	var boss_path = "res://zombie_boss.tscn"
	var boss_escena_res = load(boss_path) if ResourceLoader.exists(boss_path) else zombie_escena
	var boss = boss_escena_res.instantiate()
	add_child(boss)
	boss.global_position = pos_boss
	if boss is CharacterBody3D:
		boss.velocity = Vector3.ZERO

	actualizar_label_fase("ZOMBIE GIGANTE HA APARECIDO")
	print("!!!! FINAL BOSS SPAWNEADO CON ESCOLTA !!!!")

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
