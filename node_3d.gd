extends Node3D

@export var semilla_escena = preload("res://semilla.tscn")

var timer_semilla = 0.0
var intervalo_semilla = 5.0  # 30 segundos en segundos

var zonas_spawn = [
	Vector3(5, 1.5, 5),
	Vector3(-5, 1.5, 5),
	Vector3(5, 1.5, -5),
	Vector3(-5, 1.5, -5),
	Vector3(10, 1.5, 0),
	Vector3(-10, 1.5, 0),
	Vector3(0, 1.5, 10),
	Vector3(0, 1.5, -10),
	Vector3(8, 1.5, 8),
	Vector3(-8, 1.5, -8),
]

func _ready():
	# Spawnea 3 semillas al inicio
	for i in range(3):
		spawnear_semilla()

func _process(delta):
	timer_semilla += delta
	if timer_semilla >= intervalo_semilla:
		timer_semilla = 0.0
		spawnear_semilla()

func spawnear_semilla():
	var pos = zonas_spawn[randi() % zonas_spawn.size()]
	var nueva_semilla = semilla_escena.instantiate()
	nueva_semilla.position = pos
	add_child(nueva_semilla)
	nueva_semilla.semilla_recogida.connect(_on_semilla_recogida)

func _on_semilla_recogida():
	get_node("jugador").recoger_semilla()
