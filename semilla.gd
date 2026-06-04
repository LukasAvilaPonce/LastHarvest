extends Area3D

signal semilla_recogida

var jugador_cerca = false

func _ready():
	body_entered.connect(_al_entrar)
	body_exited.connect(_al_salir)

func _al_entrar(cuerpo):
	if cuerpo.name == "jugador":
		jugador_cerca = true

func _al_salir(cuerpo):
	if cuerpo.name == "jugador":
		jugador_cerca = false

func _process(_delta):
	if jugador_cerca and Input.is_action_just_pressed("recoger"):
		semilla_recogida.emit()
		queue_free()
