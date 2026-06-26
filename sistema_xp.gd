extends Node

var xp := 0
var nivel := 1
var xp_para_siguiente := 100
var oleadas_completadas := 0

signal nivel_subio(nivel_nuevo)
signal xp_cambio(xp_actual, xp_necesario)
signal planta_desbloqueada(indice)

var _tabla_xp := {
	1: 100,
	2: 250,
	3: 500,
	4: 900,
}

func agregar_xp(cantidad: int):
	xp += cantidad
	print("XP +", cantidad, " (total: ", xp, "/", xp_para_siguiente, ")")
	xp_cambio.emit(xp, xp_para_siguiente)
	while xp >= xp_para_siguiente:
		xp -= xp_para_siguiente
		nivel += 1
		if _tabla_xp.has(nivel):
			xp_para_siguiente = _tabla_xp[nivel]
		else:
			xp_para_siguiente = nivel * 400
		print("NIVEL SUBIDO: ", nivel, " — siguiente: ", xp_para_siguiente, " XP")
		nivel_subio.emit(nivel)

func completar_oleada():
	oleadas_completadas += 1
	var nuevas = get_plantas_desbloqueadas()
	print("Oleada ", oleadas_completadas, " completada — plantas desbloqueadas: ", nuevas.size(), "/6")
	planta_desbloqueada.emit(oleadas_completadas)

func get_plantas_desbloqueadas() -> Array:
	# Oleada 0 (inicio): Caminante, Girasol
	# Oleada 1: + Hongo
	# Oleada 2: + Enredadera
	# Oleada 3: + Chile
	# Oleada 4+: + Centinela
	match oleadas_completadas:
		0: return [0, 1]
		1: return [0, 1, 2]
		2: return [0, 1, 2, 3]
		3: return [0, 1, 2, 3, 4]
		_: return [0, 1, 2, 3, 4, 5]
