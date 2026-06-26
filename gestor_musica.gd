extends Node

var player_musica: AudioStreamPlayer = null
var player_stinger: AudioStreamPlayer = null

var pista_loot = null
var canciones_oleada := []
var pista_actual := ""
var volumen_musica := -10.0
var duracion_fade := 2.0

func _ready():
	_crear_players()
	_cargar_pistas()
	print("Gestor de música inicializado")

func _crear_players():
	player_musica = AudioStreamPlayer.new()
	player_musica.name = "PlayerMusica"
	player_musica.volume_db = volumen_musica
	player_musica.bus = "Master"
	add_child(player_musica)

	player_stinger = AudioStreamPlayer.new()
	player_stinger.name = "PlayerStinger"
	player_stinger.volume_db = -5.0
	player_stinger.bus = "Master"
	add_child(player_stinger)

func _cargar_pistas():
	var ruta_loot = "res://assets/sonidos/musica/fase_de_loot.wav"
	if ResourceLoader.exists(ruta_loot):
		pista_loot = load(ruta_loot)
		print("Pista loot: ", ruta_loot)

	var rutas_canciones = [
		"res://assets/sonidos/musica/cancion_1.wav",
		"res://assets/sonidos/musica/cancion_2.wav",
		"res://assets/sonidos/musica/cancion_3.wav",
	]
	for ruta in rutas_canciones:
		if ResourceLoader.exists(ruta):
			canciones_oleada.append(load(ruta))
			print("Canción oleada: ", ruta)

func reproducir_fase(fase: String, numero_oleada: int = 0):
	if fase == pista_actual:
		return
	pista_actual = fase

	var nueva_pista = null
	match fase:
		"loot", "espera":
			nueva_pista = pista_loot
		"oleada", "caos", "boss":
			if canciones_oleada.size() > 0:
				var idx = (numero_oleada - 1) % canciones_oleada.size()
				if idx < 0:
					idx = 0
				nueva_pista = canciones_oleada[idx]

	_hacer_fade(nueva_pista)

func _hacer_fade(nueva_pista):
	var tween = create_tween()
	tween.tween_property(player_musica, "volume_db", -80.0, duracion_fade * 0.5)
	tween.tween_callback(func():
		if nueva_pista != null:
			player_musica.stream = nueva_pista
			player_musica.play()
		else:
			player_musica.stop()
	)
	tween.tween_property(player_musica, "volume_db", volumen_musica, duracion_fade * 0.5)

func silencio():
	var tween = create_tween()
	tween.tween_property(player_musica, "volume_db", -80.0, duracion_fade)
	tween.tween_callback(player_musica.stop)
	pista_actual = ""
