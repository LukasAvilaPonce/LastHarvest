extends ColorRect

func actualizar_vida(vida: int, vida_maxima: int):
	var porcentaje := float(vida) / float(vida_maxima)
	if porcentaje < 0.25:
		color = Color(1.0, 0.0, 0.0, 0.3)
	elif porcentaje < 0.5:
		color = Color(1.0, 0.0, 0.0, 0.15)
	else:
		color = Color(0, 0, 0, 0)
