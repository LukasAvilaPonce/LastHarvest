extends Node3D

@export var posicion_base := Vector3(0.35, -0.3, -0.6)
@export var rotacion_base := Vector3(0.0, -90.0, 0.0)
@export var escala_base := Vector3(0.5, 0.5, 0.5)
@export var bob_fuerza := 0.008
@export var bob_velocidad := 8.0
@export var sway_fuerza := 0.003
@export var velocidad_retorno := 8.0
@export var cooldown_disparo := 0.15

var tiempo_bob := 0.0
var jugador: CharacterBody3D = null
var audio: AudioStreamPlayer3D = null
var puede_disparar := true
var timer_disparo := 0.0

func _ready():
	jugador = get_tree().current_scene.get_node_or_null("jugador")
	position = posicion_base
	rotation_degrees = rotacion_base
	scale = escala_base
	visible = false
	_crear_audio()
	print("Viewmodel GLB cargado (oculto hasta recoger arma)")

func _crear_audio():
	audio = AudioStreamPlayer3D.new()
	audio.name = "AudioDisparo"
	audio.volume_db = 0.0
	audio.max_distance = 50.0
	add_child(audio)
	var ruta_sonido = "res://assets/sonidos/disparo_3.wav"
	if ResourceLoader.exists(ruta_sonido):
		audio.stream = load(ruta_sonido)
		print("Sonido de disparo cargado: ", ruta_sonido)

func _process(delta):
	if not puede_disparar:
		timer_disparo -= delta
		if timer_disparo <= 0:
			puede_disparar = true

	if jugador == null:
		return
	var vel = Vector2(jugador.velocity.x, jugador.velocity.z).length()
	if vel > 0.5 and jugador.is_on_floor():
		tiempo_bob += delta * bob_velocidad
		var offset_y = sin(tiempo_bob) * bob_fuerza
		var offset_x = cos(tiempo_bob * 0.5) * bob_fuerza * 0.5
		position = posicion_base + Vector3(offset_x, offset_y, 0)
	else:
		tiempo_bob = 0.0
		position = position.lerp(posicion_base, velocidad_retorno * delta)

func _input(evento):
	if evento is InputEventMouseMotion:
		var sway_x = -evento.relative.x * sway_fuerza
		var sway_y = evento.relative.y * sway_fuerza
		position += Vector3(
			clamp(sway_x, -0.04, 0.04),
			clamp(sway_y, -0.03, 0.03),
			0
		)

	if evento is InputEventMouseButton:
		if evento.button_index == MOUSE_BUTTON_LEFT and evento.pressed:
			if visible and puede_disparar:
				_disparar()

func _disparar():
	if jugador == null:
		return
	if not jugador.get("tiene_arma"):
		return
	var modo_dios = jugador.get("modo_dios")
	if not modo_dios and jugador.get("balas") <= 0:
		return

	puede_disparar = false
	timer_disparo = cooldown_disparo

	if audio != null and audio.stream != null:
		audio.play()

	_animar_disparo()

func _animar_disparo():
	var tween = create_tween()
	var retroceso = posicion_base + Vector3(0, 0.03, 0.08)
	tween.tween_property(self, "position", retroceso, 0.05)
	tween.tween_property(self, "position", posicion_base, 0.1)
