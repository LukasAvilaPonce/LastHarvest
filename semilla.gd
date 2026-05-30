extends Area3D

signal semilla_recogida

func _ready():
	body_entered.connect(_al_tocar)

func _al_tocar(cuerpo):
	if cuerpo.name == "jugador":
		semilla_recogida.emit()
		queue_free()
