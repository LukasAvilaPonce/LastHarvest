extends CharacterBody3D
var vida = 100
var puede_recibir_dano = true

<<<<<<< Updated upstream
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
=======
# ─── STATS EXPORTABLES ────────────────────────────────────────────
@export var vida_maxima := 100
@export var vida := 100
@export var velocidad := 5.0
@export var velocidad_correr := 10.0
@export var gravedad := 9.8
@export var sensibilidad := 0.003
@export var limite_mirada_arriba_grados := 80.0
@export var limite_mirada_abajo_grados := 80.0
@export var shake_duracion := 0.25
@export var shake_fuerza := 0.08

# ─── CONFIG EXTRA DESDE player_controller.gd ──────────────────────
# Estas variables agregan salto, inclinación de cámara y movimiento visual
# del holder de arma/manos sin reemplazar la lógica original del jugador.
@export var permitir_salto := true
@export var fuerza_salto := 4.5
@export var cam: Node3D
@export var cam_rotation_amount: float = 0.05
@export var weapon_holder: Node3D
@export var weapon_sway_amount: float = 5.0
@export var weapon_rotation_amount: float = 1.0
@export var invert_weapon_sway: bool = false
@export var weapon_bob_amount: float = 0.01
@export var weapon_bob_freq: float = 0.01
@export var distancia_plantado := 5.0

# ─── CONFIG AGACHARSE / MODO DIOS ────────────────────────────────
# En Project Settings > Input Map crea una acción llamada "agacharse"
# y asígnale Ctrl. Si la nombraste distinto, cambia este texto en el Inspector.
# La acción para activar/desactivar Godmode debe llamarse "Godmode".
@export var accion_agacharse := "agachar"
@export var accion_godmode := "Godmode"
@export var velocidad_agachado := 2.5
@export var altura_camara_agachado := -0.45
@export var velocidad_transicion_agachado := 10.0
@export var ventana_doble_espacio_modo_dios := 0.35

# ─── ESTADO DEL JUGADOR ───────────────────────────────────────────
var modo_dios := false
var volando := false
var muerto := false
var puede_recibir_dano := true
var inventario_abierto := false
var agachado := false
var offset_agachado_actual := 0.0
var tiempo_ultimo_espacio_modo_dios := -10.0

# ─── SISTEMA DE OLEADAS ───────────────────────────────────────────
var semillas_por_oleada := 5
var semillas_recogidas_oleada := 0
var oleada_activa := true

# ─── SISTEMA DE PLANTAS ───────────────────────────────────────────
var tipo_planta_seleccionado := 0
const NOMBRES_PLANTAS = ["Caminante", "Girasol"]

# ─── INVENTARIO ───────────────────────────────────────────────────
var inventario := {
	"semillas": 5,
	"agua": 5,
	"abono": 5
}

# ─── CAMERA SHAKE ─────────────────────────────────────────────────
var shake_tiempo := 0.0
var shake_fuerza_actual := 0.0
var posicion_original_camara: Vector3

# ─── VIEWMODEL / HOLDER DESDE player_controller.gd ────────────────
var def_weapon_holder_pos: Vector3 = Vector3.ZERO
var mouse_input: Vector2 = Vector2.ZERO
var input_movimiento_actual: Vector2 = Vector2.ZERO
var pitch_camara: float = 0.0

# ─── NODOS ────────────────────────────────────────────────────────
# Compatible con estructura nueva:
# jugador/CamHolder/Camera3D
# y también con estructura antigua:
# jugador/Camera3D
@onready var cam_holder: Node3D = get_node_or_null("CamHolder") as Node3D
@onready var camara: Camera3D = _buscar_camara()
@onready var raycast: RayCast3D = _buscar_raycast()
@onready var escena_actual = get_tree().current_scene
@onready var hud_vida: Label = escena_actual.get_node_or_null("CanvasLayer/Label2")
@onready var inventario_ui = escena_actual.get_node_or_null("CanvasLayer/InventarioUI")
@onready var efectos_vida = escena_actual.get_node_or_null("CanvasLayer/EfectosVida")
>>>>>>> Stashed changes

func _buscar_camara() -> Camera3D:
	var rutas = [
		"CamHolder/Camera3D",
		"Camera3D"
	]
	for ruta in rutas:
		var nodo = get_node_or_null(ruta)
		if nodo is Camera3D:
			return nodo

	var encontrada = find_child("Camera3D", true, false)
	if encontrada is Camera3D:
		return encontrada
	return null

func _buscar_raycast() -> RayCast3D:
	var rutas = [
		"CamHolder/Camera3D/RayCast3D",
		"Camera3D/RayCast3D",
		"CamHolder/RayCast3D",
		"RayCast3D"
	]
	for ruta in rutas:
		var nodo = get_node_or_null(ruta)
		if nodo is RayCast3D:
			return nodo

	var encontrado = find_child("RayCast3D", true, false)
	if encontrado is RayCast3D:
		return encontrado
	return null

# ─── INIT ─────────────────────────────────────────────────────────
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
<<<<<<< Updated upstream
=======
	if camara != null:
		posicion_original_camara = camara.position
	else:
		posicion_original_camara = Vector3.ZERO
		push_warning("No se encontró Camera3D. Usa jugador/CamHolder/Camera3D o asigna una cámara válida.")

	# Si no se asigna una cámara extra en el Inspector, usa la Camera3D detectada.
	if cam == null:
		cam = camara

	# Guarda el ángulo vertical inicial para poder limitarlo y evitar que la cámara se voltee.
	if cam_holder != null:
		pitch_camara = cam_holder.rotation.x
	elif camara != null:
		pitch_camara = camara.rotation.x

	# Si asignas aquí el nodo de arma/manos, se activan sway, tilt y bob.
	if weapon_holder != null:
		def_weapon_holder_pos = weapon_holder.position

	vida = clampi(vida, 0, vida_maxima)
	actualizar_hud_vida()
	actualizar_efecto_vida()
	if inventario_ui != null:
		inventario_ui.actualizar(inventario)
>>>>>>> Stashed changes

# ─── INPUT ────────────────────────────────────────────────────────
func _input(evento):
<<<<<<< Updated upstream
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
=======
	# Toggle modo dios
	if evento.is_action_pressed(accion_godmode):
		modo_dios = not modo_dios
		# El vuelo vertical ya no queda activo automáticamente.
		# Se activa/desactiva con doble espacio mientras modo dios está encendido.
		volando = false
		tiempo_ultimo_espacio_modo_dios = -10.0
		print("MODO DIOS: ", "ACTIVADO" if modo_dios else "DESACTIVADO")

	if muerto:
		return

	# En modo dios, doble espacio activa/desactiva la subida vertical.
	if modo_dios and evento.is_action_pressed("saltar"):
		_procesar_doble_espacio_modo_dios()

	# Mover cámara con el mouse
	if evento is InputEventMouseMotion and not inventario_abierto:
		mover_camara(evento)
		mouse_input = evento.relative

	if evento.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	if evento.is_action_pressed("inventario"):
		alternar_inventario()

	if evento.is_action_pressed("plantar"):
		_intentar_plantar()

	# Scroll del mouse: cambiar tipo de planta
	if evento is InputEventMouseButton and evento.pressed:
		if evento.button_index == MOUSE_BUTTON_WHEEL_UP:
			_cambiar_tipo_planta(1)
		elif evento.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_cambiar_tipo_planta(-1)

# ─── LOOP PRINCIPAL ───────────────────────────────────────────────
func _physics_process(delta):
	if muerto:
		actualizar_shake(delta)
		return

	if modo_dios:
		actualizar_agachado(delta)

		# Si el vuelo del Godmode está activo, se usa movimiento libre:
		# espacio sube y Ctrl/agacharse baja.
		# Si el vuelo NO está activo, el jugador conserva gravedad y salto normal.
		if volando:
			_mover_modo_dios()
		else:
			aplicar_gravedad(delta)
			procesar_salto()
			mover_jugador()
			move_and_slide()

		actualizar_shake(delta)
		actualizar_efectos_viewmodel(delta)
		return

	aplicar_gravedad(delta)
	procesar_salto()
	actualizar_agachado(delta)
	mover_jugador()
	actualizar_shake(delta)
	move_and_slide()
	actualizar_efectos_viewmodel(delta)

# ─── MOVIMIENTO ───────────────────────────────────────────────────
func mover_camara(evento):
	if camara == null:
		return

	# Movimiento horizontal: rota todo el jugador.
	rotate_y(-evento.relative.x * sensibilidad)

	# Movimiento vertical: rota solo el CamHolder/Camera3D y se limita para
	# evitar que la cámara pase de 90 grados, se voltee o genere mareo.
	var nodo_pitch: Node3D = cam_holder
	if nodo_pitch == null:
		nodo_pitch = camara

	var limite_arriba := deg_to_rad(limite_mirada_arriba_grados)
	var limite_abajo := deg_to_rad(limite_mirada_abajo_grados)
	pitch_camara = clamp(
		pitch_camara - evento.relative.y * sensibilidad,
		-limite_arriba,
		limite_abajo
	)
	nodo_pitch.rotation.x = pitch_camara

func aplicar_gravedad(delta):
	if not is_on_floor():
		velocity.y -= gravedad * delta

func procesar_salto():
	if permitir_salto and Input.is_action_just_pressed("saltar") and is_on_floor():
		velocity.y = fuerza_salto

func actualizar_agachado(delta):
	# Agacharse funciona solo en el suelo.
	# En Godmode también funciona mientras NO estés volando.
	# Si estás volando, Ctrl se reserva para bajar y no para agacharse.
	agachado = _accion_presionada(accion_agacharse) and is_on_floor() and not volando
	var objetivo := altura_camara_agachado if agachado else 0.0
	offset_agachado_actual = lerp(offset_agachado_actual, objetivo, velocidad_transicion_agachado * delta)

func mover_jugador():
	var vel_actual = velocidad
	if agachado:
		vel_actual = velocidad_agachado
	elif Input.is_action_pressed("correr"):
		vel_actual = velocidad_correr
	var input = Input.get_vector("mover_izquierda", "mover_derecha", "mover_adelante", "mover_atras")
	input_movimiento_actual = input
	var direccion = (transform.basis.x * input.x + transform.basis.z * input.y).normalized()
	if direccion:
		velocity.x = direccion.x * vel_actual
		velocity.z = direccion.z * vel_actual
	else:
		velocity.x = move_toward(velocity.x, 0, vel_actual)
		velocity.z = move_toward(velocity.z, 0, vel_actual)

func _mover_modo_dios():
	# Modo dios:
	# - Ctrl / acción agacharse: bajar.
	# - Doble espacio: activa/desactiva volando.
	# - Espacio mantenido, solo si volando está activo: subir.
	var input = Input.get_vector("mover_izquierda", "mover_derecha", "mover_adelante", "mover_atras")
	input_movimiento_actual = input
	var direccion = transform.basis.x * input.x + transform.basis.z * input.y
	var mult = 3.0 if Input.is_action_pressed("correr") else 1.0
	velocity = direccion * velocidad_correr * mult
	if volando and Input.is_action_pressed("saltar"):
		velocity.y = velocidad_correr * mult
	elif _accion_presionada(accion_agacharse):
		velocity.y = -velocidad_correr * mult
	else:
		velocity.y = 0
	move_and_slide()

func _procesar_doble_espacio_modo_dios():
	var ahora := Time.get_ticks_msec() / 1000.0
	if ahora - tiempo_ultimo_espacio_modo_dios <= ventana_doble_espacio_modo_dios:
		volando = not volando
		tiempo_ultimo_espacio_modo_dios = -10.0
		print("VUELO MODO DIOS: ", "ACTIVADO" if volando else "DESACTIVADO")
	else:
		tiempo_ultimo_espacio_modo_dios = ahora

func _accion_presionada(nombre_accion: String) -> bool:
	if not InputMap.has_action(nombre_accion):
		return false
	return Input.is_action_pressed(nombre_accion)

func _posicion_base_camara_actual() -> Vector3:
	return posicion_original_camara + Vector3(0.0, offset_agachado_actual, 0.0)

# ─── EFECTOS DE CÁMARA / ARMA DESDE player_controller.gd ──────────
func actualizar_efectos_viewmodel(delta):
	cam_tilt(input_movimiento_actual.x, delta)
	weapon_tilt(input_movimiento_actual.x, delta)
	weapon_sway(delta)
	weapon_bob(velocity.length(), delta)

func cam_tilt(input_x, delta):
	var cam_obj: Node3D = cam
	if cam_obj == null:
		cam_obj = camara
	if cam_obj != null:
		cam_obj.rotation.z = lerp(cam_obj.rotation.z, -input_x * cam_rotation_amount, 10 * delta)

func weapon_tilt(input_x, delta):
	if weapon_holder != null:
		weapon_holder.rotation.z = lerp(weapon_holder.rotation.z, -input_x * weapon_rotation_amount * 10.0, 10 * delta)

func weapon_sway(delta):
	if weapon_holder == null:
		return
	mouse_input = mouse_input.lerp(Vector2.ZERO, 10 * delta)
	var invert := -1.0 if invert_weapon_sway else 1.0
	var sway_x := mouse_input.y * sensibilidad * weapon_rotation_amount * weapon_sway_amount * invert
	var sway_y := mouse_input.x * sensibilidad * weapon_rotation_amount * weapon_sway_amount * invert
	weapon_holder.rotation.x = lerp(weapon_holder.rotation.x, sway_x, 10 * delta)
	weapon_holder.rotation.y = lerp(weapon_holder.rotation.y, sway_y, 10 * delta)

func weapon_bob(vel: float, delta):
	if weapon_holder == null:
		return
	if vel > 0 and is_on_floor():
		weapon_holder.position.y = lerp(
			weapon_holder.position.y,
			def_weapon_holder_pos.y + sin(Time.get_ticks_msec() * weapon_bob_freq) * weapon_bob_amount,
			10 * delta
		)
		weapon_holder.position.x = lerp(
			weapon_holder.position.x,
			def_weapon_holder_pos.x + sin(Time.get_ticks_msec() * weapon_bob_freq * 0.5) * weapon_bob_amount,
			10 * delta
		)
	else:
		weapon_holder.position.y = lerp(weapon_holder.position.y, def_weapon_holder_pos.y, 10 * delta)
		weapon_holder.position.x = lerp(weapon_holder.position.x, def_weapon_holder_pos.x, 10 * delta)

# ─── DAÑO Y MUERTE ────────────────────────────────────────────────
func recibir_dano(cantidad: int):
	# Bloqueos: modo dios, ya muerto, o en periodo de invencibilidad
	if muerto or modo_dios:
		return
	if not puede_recibir_dano:
		return

	vida -= cantidad
	vida = clampi(vida, 0, vida_maxima)
	puede_recibir_dano = false

	actualizar_hud_vida()
	actualizar_efecto_vida()
	iniciar_shake(0.2, 0.5)
	print("Jugador recibió daño: -", cantidad, " HP (total: ", vida, ")")

	if vida <= 0:
		morir()
		return

	# Periodo de invencibilidad de 1 segundo tras recibir golpe
	await get_tree().create_timer(1.0).timeout
	if is_inside_tree() and not muerto:
		puede_recibir_dano = true

func morir():
	if muerto:
		return
	muerto = true
	puede_recibir_dano = false
	velocity = Vector3.ZERO
	print("¡JUGADOR MUERTO!")
	await get_tree().create_timer(0.35).timeout
	if is_inside_tree():
		get_tree().reload_current_scene()

# ─── HUD Y EFECTOS VISUALES ───────────────────────────────────────
func actualizar_hud_vida():
	if hud_vida != null:
		hud_vida.text = "Vida: " + str(vida)

func actualizar_efecto_vida():
	if efectos_vida != null and efectos_vida.has_method("actualizar_vida"):
		efectos_vida.actualizar_vida(vida, vida_maxima)

func iniciar_shake(fuerza: float = shake_fuerza, duracion: float = shake_duracion):
	shake_tiempo = duracion
	shake_fuerza_actual = fuerza

func actualizar_shake(delta):
	if camara == null:
		return

	if shake_tiempo > 0:
		shake_tiempo -= delta
		var offset = Vector3(
			randf_range(-shake_fuerza_actual, shake_fuerza_actual),
			randf_range(-shake_fuerza_actual, shake_fuerza_actual),
			0
		)
		camara.position = _posicion_base_camara_actual() + offset
	else:
		camara.position = _posicion_base_camara_actual()

# ─── INVENTARIO ───────────────────────────────────────────────────
func alternar_inventario():
	inventario_abierto = not inventario_abierto
	if inventario_ui == null:
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
>>>>>>> Stashed changes

# ─── SISTEMA DE OLEADAS ───────────────────────────────────────────
func nueva_oleada():
	semillas_recogidas_oleada = 0
	oleada_activa = true

func recoger_semilla():
<<<<<<< Updated upstream
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
=======
	if not oleada_activa:
		return
	if semillas_recogidas_oleada >= semillas_por_oleada:
		print("Límite de semillas alcanzado esta oleada")
		return
	semillas_recogidas_oleada += 1
	agregar_item("semillas", 1)
	print("Semillas esta oleada: ", semillas_recogidas_oleada, "/", semillas_por_oleada)

func _on_semilla_semilla_recogida():
	recoger_semilla()

# ─── SISTEMA DE PLANTAS ───────────────────────────────────────────
func _cambiar_tipo_planta(delta_slot: int):
	tipo_planta_seleccionado = (tipo_planta_seleccionado + delta_slot) % NOMBRES_PLANTAS.size()
	if tipo_planta_seleccionado < 0:
		tipo_planta_seleccionado = NOMBRES_PLANTAS.size() - 1
	print("Planta seleccionada: ", NOMBRES_PLANTAS[tipo_planta_seleccionado])
	var label = get_tree().current_scene.get_node_or_null("CanvasLayer/LabelPlanta")
	if label:
		label.text = "Planta: " + NOMBRES_PLANTAS[tipo_planta_seleccionado]

func _obtener_punto_plantado():
	# Primero intenta usar un RayCast3D si existe.
	# Puede estar en CamHolder/Camera3D/RayCast3D, Camera3D/RayCast3D u otra ruta.
	if raycast != null:
		raycast.force_raycast_update()
		if raycast.is_colliding():
			return raycast.get_collision_point()

	# Si no tienes RayCast3D en la escena, usamos un raycast por código desde la cámara.
	if camara == null:
		return null

	var origen = camara.global_transform.origin
	var destino = origen + (-camara.global_transform.basis.z * distancia_plantado)
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(origen, destino)
	query.exclude = [self]
	var resultado = space_state.intersect_ray(query)

	if resultado.has("position"):
		return resultado["position"]
	return null

func _intentar_plantar():
	var punto = _obtener_punto_plantado()
	if punto == null:
		print("No hay suelo cerca para plantar")
		return
	if inventario.get("semillas", 0) <= 0:
		print("No tienes semillas")
		return
	if inventario.get("agua", 0) <= 0:
		print("No tienes agua")
		return
	if inventario.get("abono", 0) <= 0:
		print("No tienes abono")
		return

	var planta_escena = preload("res://planta.tscn")
	var nueva_planta = planta_escena.instantiate()
	nueva_planta.position = punto
	nueva_planta.tipo = tipo_planta_seleccionado
	get_tree().current_scene.add_child(nueva_planta)

	inventario["semillas"] -= 1
	inventario["agua"] -= 1
	inventario["abono"] -= 1
	if inventario_ui != null:
		inventario_ui.actualizar(inventario)
	print("Planta colocada [", NOMBRES_PLANTAS[tipo_planta_seleccionado], "] en: ", punto)
>>>>>>> Stashed changes
