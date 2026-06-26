extends "res://zombie.gd"

var hp_maximo_boss := 10000
var fase_actual := 1
var timer_rugido := 0.0
var intervalo_rugido := 5.0
var radio_rugido := 20.0
var dano_rugido := 15
var timer_piedra := 0.0
var intervalo_piedra := 10.0
var dano_piedra := 50
var boss_bar_label: Label = null
var boss_bar_rect: ColorRect = null

func _ready():
	super._ready()
	velocidad = 4
	hp = 10000
	dano = 60
	tiempo_entre_ataques = 3.0
	distancia_atacar = 5.0
	distancia_perseguir = 1000.0
	scale = Vector3(3.0, 3.0, 3.0)
	for child in get_children():
		if child.has_method("actualizar"):
			child.queue_free()
			break
	_colorear(Color(0.9, 0.05, 0.05))
	_crear_barra_boss()
	print(">>> FINAL BOSS CARGADO — 10000 HP <<<")

func _crear_barra_boss():
	var canvas = get_tree().current_scene.get_node_or_null("CanvasLayer")
	if canvas == null:
		return
	# Ocultar timer y fase
	var timer_label = canvas.get_node_or_null("LabelTimer")
	if timer_label:
		timer_label.visible = false
	var fase_label = canvas.get_node_or_null("LabelFase")
	if fase_label:
		fase_label.visible = false

	var fondo = ColorRect.new()
	fondo.name = "BossFondo"
	fondo.anchor_left = 0.15
	fondo.anchor_right = 0.85
	fondo.anchor_top = 0.02
	fondo.anchor_bottom = 0.08
	fondo.color = Color(0.0, 0.0, 0.0, 0.8)
	canvas.add_child(fondo)

	var barra_fondo = ColorRect.new()
	barra_fondo.anchor_left = 0.01
	barra_fondo.anchor_right = 0.99
	barra_fondo.anchor_top = 0.45
	barra_fondo.anchor_bottom = 0.95
	barra_fondo.color = Color(0.3, 0.0, 0.0)
	fondo.add_child(barra_fondo)

	var barra = ColorRect.new()
	barra.name = "BossBar"
	barra.anchor_left = 0.01
	barra.anchor_right = 0.99
	barra.anchor_top = 0.45
	barra.anchor_bottom = 0.95
	barra.color = Color(0.9, 0.05, 0.05)
	fondo.add_child(barra)
	boss_bar_rect = barra

	var label = Label.new()
	label.name = "BossLabel"
	label.text = "ZOMBIE GIGANTE — 10000 HP"
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.anchor_left = 0.0
	label.anchor_right = 1.0
	label.anchor_top = 0.0
	label.anchor_bottom = 0.45
	fondo.add_child(label)
	boss_bar_label = label

func _actualizar_barra_boss():
	var porcentaje = clampf(float(hp) / float(hp_maximo_boss), 0.0, 1.0)
	if boss_bar_rect != null:
		boss_bar_rect.anchor_right = 0.01 + (0.98 * porcentaje)
	if boss_bar_label != null:
		boss_bar_label.text = "ZOMBIE GIGANTE — " + str(hp) + " / " + str(hp_maximo_boss) + " HP"
	if hp <= 5000 and fase_actual == 1:
		fase_actual = 2
		velocidad = 6
		dano = 80
		intervalo_rugido = 3.0
		intervalo_piedra = 7.0
		print("BOSS FASE 2 — más rápido y más daño")
	if hp <= 2000 and fase_actual == 2:
		fase_actual = 3
		velocidad = 8
		dano = 100
		intervalo_rugido = 2.0
		intervalo_piedra = 5.0
		print("BOSS FASE 3 — MODO FURIA")

func recibir_dano(cantidad: int):
	if muriendo:
		return
	hp -= cantidad
	hp = max(hp, 0)
	_actualizar_barra_boss()
	print("BOSS recibió daño: -", cantidad, " HP restante: ", hp)
	if hp <= 0:
		_morir_boss()

func _morir_boss():
	muriendo = true
	velocity = Vector3.ZERO
	if boss_bar_label != null:
		boss_bar_label.text = "ZOMBIE GIGANTE DERROTADO"
	if anim != null:
		anim.play("zombie death/mixamo_com")
	var xp_node = get_node_or_null("/root/SistemaXP")
	if xp_node:
		xp_node.agregar_xp(500)
	print("!!! FINAL BOSS DERROTADO !!!")
	await get_tree().create_timer(3.0).timeout
	var canvas = get_tree().current_scene.get_node_or_null("CanvasLayer")
	if canvas:
		var boss_fondo = canvas.get_node_or_null("BossFondo")
		if boss_fondo:
			boss_fondo.queue_free()
		var timer_label = canvas.get_node_or_null("LabelTimer")
		if timer_label:
			timer_label.visible = true
		var fase_label = canvas.get_node_or_null("LabelFase")
		if fase_label:
			fase_label.visible = true
	queue_free()

func _physics_process(delta):
	super._physics_process(delta)
	if muriendo:
		return
	timer_rugido -= delta
	if timer_rugido <= 0:
		timer_rugido = intervalo_rugido
		_rugido_area()
	timer_piedra -= delta
	if timer_piedra <= 0:
		timer_piedra = intervalo_piedra
		_lanzar_piedra()

func _rugido_area():
	var jugador_nodo = get_tree().current_scene.get_node_or_null("jugador")
	if jugador_nodo != null and is_instance_valid(jugador_nodo):
		if global_position.distance_to(jugador_nodo.global_position) <= radio_rugido:
			if jugador_nodo.has_method("recibir_dano"):
				jugador_nodo.recibir_dano(dano_rugido)
	for planta in get_tree().get_nodes_in_group("plantas"):
		if is_instance_valid(planta) and planta is Node3D:
			if global_position.distance_to(planta.global_position) <= radio_rugido:
				if planta.has_method("recibir_dano"):
					planta.recibir_dano(dano_rugido)
	print("BOSS RUGIDO — daño ", dano_rugido, " en radio ", radio_rugido, "m")
	# Onda visual roja
	var esfera = MeshInstance3D.new()
	var mesh_esfera = SphereMesh.new()
	mesh_esfera.radius = 1.0
	mesh_esfera.height = 2.0
	esfera.mesh = mesh_esfera
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.1, 0.1, 0.4)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	esfera.material_override = mat
	esfera.global_position = global_position + Vector3(0, 1, 0)
	get_tree().current_scene.add_child(esfera)
	var tween = esfera.create_tween()
	tween.tween_property(esfera, "scale", Vector3(radio_rugido * 2, radio_rugido * 2, radio_rugido * 2), 0.8)
	tween.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.8)
	tween.tween_callback(esfera.queue_free)

func _lanzar_piedra():
	var madre: Node3D = null
	for m in get_tree().get_nodes_in_group("planta_madre"):
		if is_instance_valid(m):
			madre = m
			break
	if madre == null:
		return

	var piedra = MeshInstance3D.new()
	var mesh_piedra = SphereMesh.new()
	mesh_piedra.radius = 1.0
	mesh_piedra.height = 2.0
	piedra.mesh = mesh_piedra
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.3, 0.2)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	piedra.material_override = mat

	var inicio = global_position + Vector3(0, 5, 0)
	var destino_pos = madre.global_position + Vector3(0, 3, 0)
	var punto_alto = (inicio + destino_pos) / 2.0 + Vector3(0, 15, 0)
	piedra.global_position = inicio
	piedra.scale = Vector3(1.5, 1.5, 1.5)
	get_tree().current_scene.add_child(piedra)

	print("BOSS lanza piedra a Planta Madre!")

	var tween = piedra.create_tween()
	tween.tween_property(piedra, "global_position", punto_alto, 0.5).set_ease(Tween.EASE_OUT)
	tween.tween_property(piedra, "global_position", destino_pos, 0.5).set_ease(Tween.EASE_IN)
	tween.tween_callback(func():
		if is_instance_valid(madre) and madre.has_method("recibir_dano"):
			madre.recibir_dano(dano_piedra)
			print("PIEDRA impactó Planta Madre: -", dano_piedra, " HP")
		# Efecto de impacto
		var impacto = MeshInstance3D.new()
		var mesh_imp = SphereMesh.new()
		mesh_imp.radius = 0.5
		mesh_imp.height = 1.0
		impacto.mesh = mesh_imp
		var mat_imp = StandardMaterial3D.new()
		mat_imp.albedo_color = Color(0.6, 0.3, 0.0, 0.7)
		mat_imp.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat_imp.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		impacto.material_override = mat_imp
		impacto.global_position = destino_pos
		get_tree().current_scene.add_child(impacto)
		var tw = impacto.create_tween()
		tw.tween_property(impacto, "scale", Vector3(6, 6, 6), 0.4)
		tw.parallel().tween_property(mat_imp, "albedo_color:a", 0.0, 0.4)
		tw.tween_callback(impacto.queue_free)
		piedra.queue_free()
	)
