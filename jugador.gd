extends CharacterBody3D

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
var modo_dev := false
var agachado := false
var offset_agachado_actual := 0.0
var tiempo_ultimo_espacio_modo_dios := -10.0
var plantas_desbloqueadas := [0, 1]
var _backup_inventario := {}
var _backup_desbloqueadas := []

# ─── ARMA ─────────────────────────────────────────────────────────
var tiene_arma := false
var balas := 0
var dano_bala := 5
var puede_disparar := true
var cadencia := 0.15
var label_balas: Label = null
var mejoras_disponibles := 0
var label_mejoras: Label = null
var audio_plantar: AudioStreamPlayer = null
var audio_salto: AudioStreamPlayer = null

# ─── SISTEMA DE OLEADAS ───────────────────────────────────────────
var semillas_por_oleada := 5
var semillas_recogidas_oleada := 0
var oleada_activa := true

# ─── SISTEMA DE PLANTAS ───────────────────────────────────────────
var planta_seleccionada := 0
const NOMBRES_PLANTAS = ["Caminante", "Girasol", "Hongo", "Enredadera", "Chile", "Centinela"]
const SEMILLAS_KEYS = ["semillas_caminante", "semillas_girasol", "semillas_hongo", "semillas_enredadera", "semillas_chile", "semillas_arbol"]
const COLORES_PLANTAS = [
	Color(0.2, 0.7, 0.2),
	Color(1.0, 0.85, 0.0),
	Color(0.4, 0.2, 0.0),
	Color(0.0, 0.3, 0.0),
	Color(0.9, 0.1, 0.0),
	Color(0.0, 0.4, 0.3),
]
var plantas_escenas := [
	"res://planta.tscn",
	"res://planta.tscn",
	"res://hongo_explosivo.tscn",
	"res://enredadera.tscn",
	"res://chile_llamante.tscn",
	"res://arbol_centinela.tscn",
]

# ─── INVENTARIO ───────────────────────────────────────────────────
var inventario := {
	"semillas_caminante": 0,
	"semillas_girasol": 0,
	"semillas_hongo": 0,
	"semillas_enredadera": 0,
	"semillas_chile": 0,
	"semillas_arbol": 0,
	"agua": 0,
	"abono": 0,
}

# ─── HOTBAR ───────────────────────────────────────────────────────
var hotbar_labels := {}
var hotbar_panels := {}

# ─── CROSSHAIR ────────────────────────────────────────────────────
var crosshair: Control
var crosshair_dot: ColorRect

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
@onready var cam_holder: Node3D = get_node_or_null("CamHolder") as Node3D
@onready var camara: Camera3D = _buscar_camara()
@onready var raycast: RayCast3D = _buscar_raycast()
@onready var escena_actual = get_tree().current_scene
@onready var hud_vida: Label = escena_actual.get_node_or_null("CanvasLayer/Label2")
@onready var inventario_ui = escena_actual.get_node_or_null("CanvasLayer/InventarioUI")
@onready var efectos_vida = escena_actual.get_node_or_null("CanvasLayer/EfectosVida")

func _buscar_camara() -> Camera3D:
	var rutas = [
		"CamHolder/Camera3D",
		"Camholder/Camera3D",
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
		"Camholder/Camera3D/RayCast3D",
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
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	call_deferred("_posicionar_jugador")
	if camara != null:
		posicion_original_camara = camara.position
	else:
		posicion_original_camara = Vector3.ZERO
		push_warning("No se encontró Camera3D.")

	if cam == null:
		cam = camara

	if cam_holder != null:
		pitch_camara = cam_holder.rotation.x
	elif camara != null:
		pitch_camara = camara.rotation.x

	if weapon_holder != null:
		def_weapon_holder_pos = weapon_holder.position

	vida = clampi(vida, 0, vida_maxima)
	actualizar_hud_vida()
	actualizar_efecto_vida()
	if inventario_ui != null:
		inventario_ui.actualizar(inventario)
	_crear_hotbar()
	_crear_label_xp()
	_crear_crosshair()
	_crear_viewmodel()
	_crear_audio_plantar()
	_crear_audio_salto()

# ─── INPUT ────────────────────────────────────────────────────────
func _input(evento):
	if evento.is_action_pressed(accion_godmode):
		modo_dios = not modo_dios
		volando = false
		tiempo_ultimo_espacio_modo_dios = -10.0
		if modo_dios:
			_backup_inventario = inventario.duplicate()
			_backup_desbloqueadas = plantas_desbloqueadas.duplicate()
			plantas_desbloqueadas = [0, 1, 2, 3, 4, 5]
			for key in SEMILLAS_KEYS:
				inventario[key] = 999
			inventario["agua"] = 999
			inventario["abono"] = 999
			print("MODO DIOS ACTIVADO")
		else:
			inventario = _backup_inventario.duplicate()
			plantas_desbloqueadas = _backup_desbloqueadas.duplicate()
			print("MODO DIOS DESACTIVADO — inventario restaurado")
		_actualizar_hotbar()

	if muerto:
		return

	if modo_dios and evento.is_action_pressed("saltar"):
		_procesar_doble_espacio_modo_dios()

	if evento is InputEventMouseMotion and not inventario_abierto:
		mover_camara(evento)
		mouse_input = evento.relative

	if evento.is_action_pressed("ui_cancel"):
		if inventario_abierto:
			alternar_inventario()
		else:
			_alternar_modo_dev()

	if evento.is_action_pressed("inventario"):
		alternar_inventario()

	if inventario_abierto:
		return

	if evento is InputEventKey and evento.pressed and evento.keycode == KEY_M:
		_usar_mejora_cercana()



	if evento.is_action_pressed("plantar"):
		_intentar_plantar()

	if evento is InputEventMouseButton and evento.pressed:
		if evento.button_index == MOUSE_BUTTON_LEFT:
			if tiene_arma and puede_disparar and balas > 0:
				_disparar()
		elif evento.button_index == MOUSE_BUTTON_WHEEL_UP:
			_cambiar_tipo_planta(-1)
		elif evento.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_cambiar_tipo_planta(1)

	if evento is InputEventKey and evento.pressed:
		var teclas = [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6]
		for i in range(teclas.size()):
			if evento.keycode == teclas[i]:
				if not plantas_desbloqueadas.has(i):
					print("Bloqueada — completa oleada para desbloquear")
					break
				planta_seleccionada = i
				_actualizar_hotbar()
				break

# ─── LOOP PRINCIPAL ───────────────────────────────────────────────
func _physics_process(delta):
	if muerto:
		actualizar_shake(delta)
		return

	if modo_dios:
		actualizar_agachado(delta)
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
	rotate_y(-evento.relative.x * sensibilidad)
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
		if audio_salto != null:
			audio_salto.play()

func actualizar_agachado(delta):
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
	var delta_t = ahora - tiempo_ultimo_espacio_modo_dios
	if delta_t <= ventana_doble_espacio_modo_dios:
		volando = not volando
		tiempo_ultimo_espacio_modo_dios = -10.0
		print("VUELO MODO DIOS: ", "ACTIVADO" if volando else "DESACTIVADO")
	else:
		tiempo_ultimo_espacio_modo_dios = ahora
		print("Modo dios: primer espacio registrado — presiona de nuevo rápido para volar")

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

func _posicionar_jugador():
	await get_tree().process_frame
	await get_tree().process_frame
	var madre = get_tree().get_first_node_in_group("planta_madre")
	if madre != null:
		global_position = Vector3(madre.global_position.x + 8, 1.0, madre.global_position.z)
	else:
		global_position = Vector3(8, 1.0, 0)
	global_transform.basis = Basis()
	var cam_h = get_node_or_null("Camholder")
	if cam_h != null:
		cam_h.rotation = Vector3.ZERO
	print("JUGADOR en: ", snapped(global_position, Vector3(0.1,0.1,0.1)))

func recibir_curacion(cantidad: int):
	if muerto:
		return
	vida = clampi(vida + cantidad, 0, vida_maxima)
	actualizar_hud_vida()
	actualizar_efecto_vida()
	print("Jugador curado: +", cantidad, " HP (total: ", vida, ")")

# ─── DAÑO Y MUERTE ────────────────────────────────────────────────
func recibir_dano(cantidad: int):
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
		hud_vida.text = "HP: " + str(vida) + "/" + str(vida_maxima)

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
	_actualizar_hotbar()
	if inventario_ui != null:
		inventario_ui.actualizar(inventario)

# ─── SISTEMA DE OLEADAS ───────────────────────────────────────────
func nueva_oleada():
	semillas_recogidas_oleada = 0
	oleada_activa = true

func recoger_semilla():
	if not oleada_activa:
		return
	if semillas_recogidas_oleada >= semillas_por_oleada:
		print("Límite de semillas alcanzado esta oleada")
		return
	semillas_recogidas_oleada += 1
	if randi() % 2 == 0:
		agregar_item("semillas_caminante", 1)
	else:
		agregar_item("semillas_girasol", 1)
	print("Semillas esta oleada: ", semillas_recogidas_oleada, "/", semillas_por_oleada)

func _on_semilla_semilla_recogida():
	recoger_semilla()

# ─── HOTBAR UI ────────────────────────────────────────────────────
func _crear_hotbar():
	var canvas = escena_actual.get_node_or_null("CanvasLayer")
	if canvas == null:
		return

	# Fondo principal oscuro
	var fondo = PanelContainer.new()
	fondo.name = "Hotbar"
	fondo.anchor_left = 0.5
	fondo.anchor_right = 0.5
	fondo.anchor_top = 1.0
	fondo.anchor_bottom = 1.0
	fondo.offset_left = -550
	fondo.offset_right = 550
	fondo.offset_top = -95
	fondo.offset_bottom = -5
	var style_fondo = StyleBoxFlat.new()
	style_fondo.bg_color = Color(0.05, 0.05, 0.08, 0.85)
	style_fondo.border_color = Color(0.6, 0.15, 0.1)
	style_fondo.set_border_width_all(2)
	style_fondo.set_corner_radius_all(6)
	fondo.add_theme_stylebox_override("panel", style_fondo)
	canvas.add_child(fondo)

	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 6)
	fondo.add_child(hbox)

	for i in range(NOMBRES_PLANTAS.size()):
		var panel = PanelContainer.new()
		panel.custom_minimum_size = Vector2(110, 65)
		hbox.add_child(panel)

		var vbox = VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_theme_constant_override("separation", 2)
		panel.add_child(vbox)

		var icono = ColorRect.new()
		icono.custom_minimum_size = Vector2(22, 22)
		icono.color = COLORES_PLANTAS[i]
		vbox.add_child(icono)

		var lbl = Label.new()
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(lbl)

		hotbar_labels[i] = lbl
		hotbar_panels[i] = panel

	# Separador con estilo
	var sep_rect = ColorRect.new()
	sep_rect.custom_minimum_size = Vector2(2, 50)
	sep_rect.color = Color(0.6, 0.15, 0.1, 0.6)
	hbox.add_child(sep_rect)

	for key in ["agua", "abono"]:
		var panel = PanelContainer.new()
		panel.custom_minimum_size = Vector2(90, 65)
		hbox.add_child(panel)

		var vbox = VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_theme_constant_override("separation", 2)
		panel.add_child(vbox)

		var icono = ColorRect.new()
		icono.custom_minimum_size = Vector2(22, 22)
		icono.color = Color(0.2, 0.4, 0.9) if key == "agua" else Color(0.55, 0.35, 0.15)
		vbox.add_child(icono)

		var lbl = Label.new()
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(lbl)

		hotbar_labels[key] = lbl

	_actualizar_hotbar()

func _actualizar_hotbar():
	for i in range(NOMBRES_PLANTAS.size()):
		if hotbar_panels.has(i):
			hotbar_panels[i].visible = plantas_desbloqueadas.has(i)
		if hotbar_labels.has(i):
			if plantas_desbloqueadas.has(i):
				var cant = inventario.get(SEMILLAS_KEYS[i], 0)
				hotbar_labels[i].text = NOMBRES_PLANTAS[i] + "\nx" + str(cant)

	for key in ["agua", "abono"]:
		if hotbar_labels.has(key):
			hotbar_labels[key].text = key.capitalize() + "\nx" + str(inventario.get(key, 0))

	if label_balas != null and tiene_arma:
		if modo_dios:
			label_balas.text = "Balas: INF"
		else:
			label_balas.text = "Balas: " + str(balas)

	for i in hotbar_panels:
		if not i is int:
			continue
		var panel = hotbar_panels[i]
		var style = StyleBoxFlat.new()
		if i == planta_seleccionada:
			style.bg_color = Color(0.15, 0.25, 0.1, 0.9)
			style.border_color = Color(0.8, 0.2, 0.1)
			style.set_border_width_all(3)
		else:
			style.bg_color = Color(0.08, 0.08, 0.1, 0.7)
			style.border_color = Color(0.3, 0.1, 0.08)
			style.set_border_width_all(1)
		style.set_corner_radius_all(4)
		panel.add_theme_stylebox_override("panel", style)

	var label_planta = get_tree().current_scene.get_node_or_null("CanvasLayer/LabelPlanta")
	if label_planta:
		label_planta.text = "Planta: " + NOMBRES_PLANTAS[planta_seleccionada]

var label_xp: Label

func _crear_label_xp():
	var canvas = escena_actual.get_node_or_null("CanvasLayer")
	if canvas == null:
		return
	label_xp = Label.new()
	label_xp.name = "LabelXP"
	label_xp.anchor_left = 1.0
	label_xp.anchor_right = 1.0
	label_xp.offset_left = -300
	label_xp.offset_top = 10
	label_xp.offset_right = -10
	label_xp.offset_bottom = 40
	label_xp.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label_xp.add_theme_font_size_override("font_size", 20)
	canvas.add_child(label_xp)
	_actualizar_label_xp()
	var xp_node = get_node_or_null("/root/SistemaXP")
	if xp_node:
		xp_node.nivel_subio.connect(_on_nivel_subio)
		xp_node.xp_cambio.connect(_on_xp_cambio)
		xp_node.planta_desbloqueada.connect(_on_planta_desbloqueada)

func _on_nivel_subio(_nivel_nuevo):
	_actualizar_label_xp()
	_actualizar_hotbar()

func _on_xp_cambio(_xp, _xp_sig):
	_actualizar_label_xp()

func _on_planta_desbloqueada(_oleada):
	_actualizar_hotbar()

func _actualizar_label_xp():
	if label_xp == null:
		return
	var xp_node = get_node_or_null("/root/SistemaXP")
	if xp_node:
		label_xp.text = "Nivel " + str(xp_node.nivel) + " | XP: " + str(xp_node.xp) + "/" + str(xp_node.xp_para_siguiente)
	else:
		label_xp.text = "XP: --"

# ─── CROSSHAIR ────────────────────────────────────────────────────
func _crear_crosshair():
	var canvas = escena_actual.get_node_or_null("CanvasLayer")
	if canvas == null:
		return

	crosshair = Control.new()
	crosshair.name = "Crosshair"
	crosshair.anchor_left = 0.5
	crosshair.anchor_right = 0.5
	crosshair.anchor_top = 0.5
	crosshair.anchor_bottom = 0.5
	crosshair.offset_left = -12
	crosshair.offset_right = 12
	crosshair.offset_top = -12
	crosshair.offset_bottom = 12
	crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(crosshair)

	crosshair_dot = ColorRect.new()
	crosshair_dot.size = Vector2(6, 6)
	crosshair_dot.position = Vector2(9, 9)
	crosshair_dot.color = Color(1, 1, 1, 0.8)
	crosshair.add_child(crosshair_dot)

	var linea_h = ColorRect.new()
	linea_h.size = Vector2(24, 2)
	linea_h.position = Vector2(0, 11)
	linea_h.color = Color(1, 1, 1, 0.4)
	crosshair.add_child(linea_h)

	var linea_v = ColorRect.new()
	linea_v.size = Vector2(2, 24)
	linea_v.position = Vector2(11, 0)
	linea_v.color = Color(1, 1, 1, 0.4)
	crosshair.add_child(linea_v)

func _animar_crosshair_plantar():
	if crosshair_dot == null:
		return
	crosshair_dot.color = Color(0.2, 1.0, 0.3, 1.0)
	var tween = create_tween()
	tween.tween_property(crosshair_dot, "scale", Vector2(3, 3), 0.15)
	tween.tween_property(crosshair_dot, "scale", Vector2(1, 1), 0.2)
	tween.parallel().tween_property(crosshair_dot, "color", Color(1, 1, 1, 0.8), 0.2)

func _animar_mano_plantar():
	var canvas = escena_actual.get_node_or_null("CanvasLayer")
	if canvas == null:
		return
	var mano = Label.new()
	mano.text = "+"
	mano.add_theme_font_size_override("font_size", 48)
	mano.add_theme_color_override("font_color", Color(0.2, 1.0, 0.3))
	mano.anchor_left = 0.5
	mano.anchor_top = 0.5
	mano.offset_left = 20
	mano.offset_top = -40
	mano.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(mano)
	var tween = mano.create_tween()
	tween.tween_property(mano, "offset_top", -80.0, 0.4)
	tween.parallel().tween_property(mano, "modulate:a", 0.0, 0.4)
	tween.tween_callback(mano.queue_free)

# ─── SISTEMA DE PLANTAS ───────────────────────────────────────────
func _cambiar_tipo_planta(delta_slot: int):
	var siguiente = (planta_seleccionada + delta_slot) % NOMBRES_PLANTAS.size()
	if siguiente < 0:
		siguiente = NOMBRES_PLANTAS.size() - 1
	if plantas_desbloqueadas.has(siguiente):
		planta_seleccionada = siguiente
		_actualizar_hotbar()

func _obtener_punto_plantado():
	if raycast != null:
		raycast.force_raycast_update()
		if raycast.is_colliding():
			return raycast.get_collision_point()
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

	var semilla_key = SEMILLAS_KEYS[planta_seleccionada]

	if inventario.get(semilla_key, 0) <= 0:
		print("No tienes semillas de ", NOMBRES_PLANTAS[planta_seleccionada])
		return
	if inventario.get("agua", 0) <= 0:
		print("No tienes agua")
		return
	if inventario.get("abono", 0) <= 0:
		print("No tienes abono")
		return

	var planta_escena = load(plantas_escenas[planta_seleccionada])
	var nueva_planta = planta_escena.instantiate()
	nueva_planta.position = punto
	if nueva_planta.get("tipo") != null:
		nueva_planta.tipo = planta_seleccionada
	get_tree().current_scene.add_child(nueva_planta)

	inventario[semilla_key] -= 1
	inventario["agua"] -= 1
	inventario["abono"] -= 1
	_actualizar_hotbar()
	_animar_crosshair_plantar()
	_animar_mano_plantar()
	if inventario_ui != null:
		inventario_ui.actualizar(inventario)
	if audio_plantar != null:
		audio_plantar.play()
	print("Planta colocada [", NOMBRES_PLANTAS[planta_seleccionada], "] en: ", punto)

# ─── DESBLOQUEO POR OLEADA ────────────────────────────────────────
func desbloquear_planta_por_oleada(numero_oleada_actual: int):
	var desbloqueos = {
		1: 2,
		2: 3,
		3: 4,
		4: 5,
	}
	if desbloqueos.has(numero_oleada_actual):
		var nueva = desbloqueos[numero_oleada_actual]
		if not plantas_desbloqueadas.has(nueva):
			plantas_desbloqueadas.append(nueva)
			inventario[SEMILLAS_KEYS[nueva]] = 5
			print("NUEVA PLANTA DESBLOQUEADA: ", NOMBRES_PLANTAS[nueva])
			_mostrar_notificacion_desbloqueo(nueva)
	_actualizar_hotbar()

func _mostrar_notificacion_desbloqueo(indice: int):
	var canvas = escena_actual.get_node_or_null("CanvasLayer")
	if canvas == null:
		return

	var fondo = ColorRect.new()
	fondo.anchor_left = 0.25
	fondo.anchor_right = 0.75
	fondo.anchor_top = 0.3
	fondo.anchor_bottom = 0.45
	fondo.color = Color(0, 0, 0, 0.7)
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(fondo)

	var label = Label.new()
	label.text = "NUEVA PLANTA DESBLOQUEADA!\n" + NOMBRES_PLANTAS[indice]
	label.add_theme_font_size_override("font_size", 32)
	label.add_theme_color_override("font_color", COLORES_PLANTAS[indice])
	label.anchor_left = 0.5
	label.anchor_right = 0.5
	label.anchor_top = 0.5
	label.anchor_bottom = 0.5
	label.offset_left = -200
	label.offset_right = 200
	label.offset_top = -80
	label.offset_bottom = -40
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.anchor_left = 0.0
	label.anchor_right = 1.0
	label.anchor_top = 0.0
	label.anchor_bottom = 1.0
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fondo.add_child(label)
	var tween = fondo.create_tween()
	tween.tween_interval(2.5)
	tween.tween_property(fondo, "modulate:a", 0.0, 0.5)
	tween.tween_callback(fondo.queue_free)

func _restaurar_desbloqueo_real():
	var mundo = get_tree().current_scene
	var oleada_actual = 0
	if mundo and mundo.get("numero_oleada") != null:
		oleada_actual = mundo.numero_oleada

	plantas_desbloqueadas = [0, 1]
	var desbloqueos = {1: 2, 2: 3, 3: 4, 4: 5}
	for oleada in range(1, oleada_actual + 1):
		if desbloqueos.has(oleada) and not plantas_desbloqueadas.has(desbloqueos[oleada]):
			plantas_desbloqueadas.append(desbloqueos[oleada])

	inventario["agua"] = 1000
	inventario["abono"] = 1000
	_actualizar_hotbar()

# ─── SISTEMA DE ARMA ─────────────────────────────────────────────
func recoger_arma():
	tiene_arma = true
	balas = 30
	_crear_label_balas()
	_actualizar_label_balas()
	var cam = _buscar_camara()
	if cam != null:
		var vm = cam.get_node_or_null("Viewmodel")
		if vm != null:
			vm.visible = true
	print("ARMA RECOGIDA — 30 balas")
	var canvas = escena_actual.get_node_or_null("CanvasLayer")
	if canvas:
		var notif = Label.new()
		notif.text = "Arma recogida!"
		notif.add_theme_font_size_override("font_size", 28)
		notif.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
		notif.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		notif.anchor_left = 0.5
		notif.anchor_right = 0.5
		notif.anchor_top = 0.35
		notif.offset_left = -150
		notif.offset_right = 150
		notif.mouse_filter = Control.MOUSE_FILTER_IGNORE
		canvas.add_child(notif)
		var tw = notif.create_tween()
		tw.tween_property(notif, "offset_top", -50.0, 1.5)
		tw.parallel().tween_property(notif, "modulate:a", 0.0, 1.5)
		tw.tween_callback(notif.queue_free)

func recoger_cargador(cantidad: int):
	balas += cantidad
	_actualizar_label_balas()
	print("CARGADOR RECOGIDO — +", cantidad, " balas (total: ", balas, ")")

func _crear_label_balas():
	var canvas = escena_actual.get_node_or_null("CanvasLayer")
	if canvas == null or label_balas != null:
		return
	label_balas = Label.new()
	label_balas.name = "LabelBalas"
	label_balas.anchor_left = 1.0
	label_balas.anchor_right = 1.0
	label_balas.anchor_top = 1.0
	label_balas.anchor_bottom = 1.0
	label_balas.offset_left = -200
	label_balas.offset_right = -10
	label_balas.offset_top = -50
	label_balas.offset_bottom = -10
	label_balas.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label_balas.add_theme_font_size_override("font_size", 24)
	label_balas.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
	label_balas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(label_balas)

func _actualizar_label_balas():
	if label_balas != null:
		if tiene_arma:
			label_balas.text = "Balas: " + str(balas)
		else:
			label_balas.text = ""

func _disparar():
	if not tiene_arma or not puede_disparar:
		return
	if not modo_dios and balas <= 0:
		return
	puede_disparar = false
	if not modo_dios:
		balas -= 1
	_actualizar_label_balas()

	if camara == null:
		puede_disparar = true
		return

	var origen = camara.global_transform.origin
	var direccion = -camara.global_transform.basis.z
	var destino = origen + direccion * 500.0
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(origen, destino)
	query.exclude = [self]
	var resultado = space_state.intersect_ray(query)

	var punto_impacto = destino
	if not resultado.is_empty():
		punto_impacto = resultado["position"]
		var hit = resultado["collider"]
		if hit.is_in_group("zombies") and hit.has_method("recibir_dano"):
			hit.recibir_dano(dano_bala)

	_efecto_disparo(origen, punto_impacto)
	_animar_crosshair_plantar()
	_retroceso_arma()

	await get_tree().create_timer(cadencia).timeout
	if is_inside_tree():
		puede_disparar = true

func _efecto_disparo(desde: Vector3, hasta: Vector3):
	var rayo = MeshInstance3D.new()
	var mesh_rayo = BoxMesh.new()
	var largo = desde.distance_to(hasta)
	mesh_rayo.size = Vector3(0.02, 0.02, largo)
	rayo.mesh = mesh_rayo
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 1.0, 0.3, 0.9)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rayo.material_override = mat
	get_tree().current_scene.add_child(rayo)
	var medio = (desde + hasta) / 2.0
	rayo.global_position = medio
	if desde.distance_to(hasta) > 0.1:
		rayo.look_at(hasta)
	var tween = rayo.create_tween()
	tween.tween_property(mat, "albedo_color:a", 0.0, 0.1)
	tween.tween_callback(rayo.queue_free)

func _retroceso_arma():
	var cam = _buscar_camara()
	if cam == null:
		return
	var vm = cam.get_node_or_null("Viewmodel")
	if vm == null or not vm.visible:
		return
	var pos_base = vm.position
	var tween = vm.create_tween()
	tween.tween_property(vm, "position", pos_base + Vector3(0, 0.03, 0.08), 0.05)
	tween.tween_property(vm, "position", pos_base, 0.12)

# ─── VIEWMODEL (ARMA VISUAL) ─────────────────────────────────────
func _crear_viewmodel():
	var cam = _buscar_camara()
	if cam == null:
		push_warning("Viewmodel: Camera3D no encontrada")
		return
	if cam.get_node_or_null("Viewmodel") != null:
		return
	var rutas = [
		"res://assets/plantas/pistola v2.glb",
		"res://assets/arma/arma.glb",
	]
	var escena_arma = null
	for ruta in rutas:
		if ResourceLoader.exists(ruta):
			escena_arma = load(ruta)
			print("Arma GLB cargada desde: ", ruta)
			break
	if escena_arma == null:
		push_warning("Viewmodel: no se encontró arma.glb")
		return
	var viewmodel_root = Node3D.new()
	viewmodel_root.name = "Viewmodel"
	var script_vm = load("res://viewmodel.gd")
	if script_vm != null:
		viewmodel_root.set_script(script_vm)
	var instancia_arma = escena_arma.instantiate()
	instancia_arma.name = "ArmaModel"
	viewmodel_root.add_child(instancia_arma)
	cam.add_child(viewmodel_root)
	print("Viewmodel GLB agregado a: ", cam.name)

func _crear_audio_plantar():
	audio_plantar = AudioStreamPlayer.new()
	audio_plantar.name = "AudioPlantar"
	audio_plantar.volume_db = -5.0
	var ruta = "res://assets/sonidos/sonidos al plantar/fah.wav"
	if ResourceLoader.exists(ruta):
		audio_plantar.stream = load(ruta)
		print("Sonido plantar cargado: ", ruta)
	add_child(audio_plantar)

func _crear_audio_salto():
	audio_salto = AudioStreamPlayer.new()
	audio_salto.name = "AudioSalto"
	audio_salto.volume_db = -8.0
	var ruta = "res://assets/sonidos/sonidos personaje/salto.wav"
	if ResourceLoader.exists(ruta):
		audio_salto.stream = load(ruta)
	add_child(audio_salto)

# ─── MODO DESARROLLADOR ──────────────────────────────────────────
var _dev_label: Label = null

func _alternar_modo_dev():
	modo_dev = not modo_dev
	if modo_dev:
		get_tree().paused = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		if not modo_dios:
			modo_dios = true
			volando = true
			_backup_inventario = inventario.duplicate()
			_backup_desbloqueadas = plantas_desbloqueadas.duplicate()
			plantas_desbloqueadas = [0, 1, 2, 3, 4, 5]
			for key in SEMILLAS_KEYS:
				inventario[key] = 999
			inventario["agua"] = 999
			inventario["abono"] = 999
			_actualizar_hotbar()
		_mostrar_dev_hud(true)
	else:
		get_tree().paused = false
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		_mostrar_dev_hud(false)

func _mostrar_dev_hud(mostrar: bool):
	if mostrar:
		if _dev_label == null:
			var canvas = escena_actual.get_node_or_null("CanvasLayer")
			if canvas == null:
				return
			_dev_label = Label.new()
			_dev_label.name = "DevLabel"
			_dev_label.anchor_left = 0.0
			_dev_label.anchor_top = 0.0
			_dev_label.offset_left = 10
			_dev_label.offset_top = 80
			_dev_label.add_theme_font_size_override("font_size", 16)
			_dev_label.add_theme_color_override("font_color", Color(0.0, 1.0, 0.0))
			_dev_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			canvas.add_child(_dev_label)
		_dev_label.text = "=== MODO DEV ===\nESC: reanudar\nVuelo activo\nWASD: mover\nEspacio: subir\nCtrl: bajar"
		_dev_label.visible = true
	else:
		if _dev_label != null:
			_dev_label.visible = false

func _input_dev(evento):
	if not modo_dev:
		return
	if evento is InputEventMouseMotion:
		mover_camara(evento)

func _unhandled_input(evento):
	if modo_dev:
		if evento is InputEventMouseMotion:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			mover_camara(evento)
			mouse_input = evento.relative

# ─── SISTEMA DE MEJORAS ───────────────────────────────────────────
func recoger_mejora():
	mejoras_disponibles += 1
	_actualizar_label_mejoras()
	var canvas = escena_actual.get_node_or_null("CanvasLayer")
	if canvas:
		var notif = Label.new()
		notif.text = "Mejora recogida! [M] para usar en planta cercana"
		notif.add_theme_font_size_override("font_size", 24)
		notif.add_theme_color_override("font_color", Color(0.3, 0.7, 1.0))
		notif.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		notif.anchor_left = 0.5
		notif.anchor_right = 0.5
		notif.anchor_top = 0.35
		notif.offset_left = -250
		notif.offset_right = 250
		notif.mouse_filter = Control.MOUSE_FILTER_IGNORE
		canvas.add_child(notif)
		var tw = notif.create_tween()
		tw.tween_property(notif, "offset_top", -50.0, 2.0)
		tw.parallel().tween_property(notif, "modulate:a", 0.0, 2.0)
		tw.tween_callback(notif.queue_free)

func _usar_mejora_cercana():
	if mejoras_disponibles <= 0:
		return
	var mejor_planta: Node3D = null
	var mejor_dist := 10.0
	for planta in get_tree().get_nodes_in_group("plantas"):
		if is_instance_valid(planta) and planta.get("activa") and not planta.get("mejorado"):
			var d = global_position.distance_to(planta.global_position)
			if d < mejor_dist:
				mejor_dist = d
				mejor_planta = planta
	if mejor_planta != null and mejor_planta.has_method("aplicar_mejora"):
		mejor_planta.aplicar_mejora()
		mejoras_disponibles -= 1
		_actualizar_label_mejoras()
	else:
		print("No hay planta cercana para mejorar")

func _actualizar_label_mejoras():
	if label_mejoras == null:
		var canvas = escena_actual.get_node_or_null("CanvasLayer")
		if canvas == null:
			return
		label_mejoras = Label.new()
		label_mejoras.name = "LabelMejoras"
		label_mejoras.anchor_left = 1.0
		label_mejoras.anchor_right = 1.0
		label_mejoras.offset_left = -200
		label_mejoras.offset_right = -10
		label_mejoras.offset_top = 40
		label_mejoras.offset_bottom = 70
		label_mejoras.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		label_mejoras.add_theme_font_size_override("font_size", 20)
		label_mejoras.add_theme_color_override("font_color", Color(0.3, 0.7, 1.0))
		label_mejoras.mouse_filter = Control.MOUSE_FILTER_IGNORE
		canvas.add_child(label_mejoras)
	if mejoras_disponibles > 0:
		label_mejoras.text = "Mejoras [M]: " + str(mejoras_disponibles)
	else:
		label_mejoras.text = ""
