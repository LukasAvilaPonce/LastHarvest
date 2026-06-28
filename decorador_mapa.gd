extends Node

var E = "res://assets/zombie_kit/entorno/"
var V = "res://assets/zombie_kit/vehiculos/"
var U = "res://assets/urban kit/GLB format/"
var G = "res://assets/graveyard/GLB format/"

func _ready():
	await get_tree().process_frame
	await get_tree().process_frame
	_poblar_mapa()
	get_tree().tree_changed.connect(_on_scene_changed)

var _escena_actual_id := 0

func _on_scene_changed():
	var escena = get_tree().current_scene
	if escena == null:
		return
	var nuevo_id = escena.get_instance_id()
	if nuevo_id != _escena_actual_id:
		_escena_actual_id = nuevo_id
		call_deferred("_repoblar")

func _repoblar():
	await get_tree().process_frame
	_poblar_mapa()

func _poblar_mapa():
	var padre = get_tree().current_scene
	if padre == null:
		return

	# ═══ REJAS EN EL CONTORNO CON APERTURAS ═══
	_crear_bordes(padre)

	# ═══ VEHÍCULOS DISPERSOS (como la imagen) ═══
	# Zona superior izquierda
	_obj(V+"Vehicle_Pickup.gltf", Vector3(-30, 0, -30), 45, 1.2, padre, true)
	_obj(V+"Vehicle_Sports.gltf", Vector3(-20, 0, -35), 120, 1.2, padre, true)
	# Zona superior derecha
	_obj(V+"Vehicle_Truck.gltf", Vector3(25, 0, -28), -30, 1.2, padre, true)
	_obj(V+"Vehicle_Pickup_Armored.gltf", Vector3(35, 0, -35), 80, 1.2, padre, true)
	# Zona inferior izquierda
	_obj(V+"Vehicle_Sports.gltf", Vector3(-35, 0, 25), -60, 1.2, padre, true)
	_obj(V+"Vehicle_Pickup.gltf", Vector3(-25, 0, 35), 150, 1.2, padre, true)
	# Zona inferior derecha
	_obj(V+"Vehicle_Truck.gltf", Vector3(30, 0, 30), 200, 1.2, padre, true)
	_obj(V+"Vehicle_Sports_Armored.gltf", Vector3(38, 0, 20), -45, 1.2, padre, true)
	# Laterales
	_obj(V+"Vehicle_Pickup.gltf", Vector3(-40, 0, 0), 90, 1.2, padre, true)
	_obj(V+"Vehicle_Truck_Armored.gltf", Vector3(40, 0, -5), -90, 1.2, padre, true)

	# ═══ CONTENEDORES ═══
	_obj(E+"Container_Red.gltf", Vector3(35, 0, -15), 0, 1.2, padre, true)
	_obj(E+"Container_Green.gltf", Vector3(-38, 0, 15), 90, 1.2, padre, true)

	# ═══ BARRICADAS DEFENSIVAS cerca del centro ═══
	_obj(E+"TrafficBarrier_1.gltf", Vector3(-12, 0, -8), 30, 1.2, padre, true)
	_obj(E+"TrafficBarrier_2.gltf", Vector3(12, 0, -8), -30, 1.2, padre, true)
	_obj(E+"TrafficBarrier_1.gltf", Vector3(-12, 0, 8), -30, 1.2, padre, true)
	_obj(E+"TrafficBarrier_2.gltf", Vector3(12, 0, 8), 30, 1.2, padre, true)
	_obj(E+"PlasticBarrier.gltf", Vector3(0, 0, -14), 0, 1.2, padre, true)
	_obj(E+"PlasticBarrier.gltf", Vector3(0, 0, 14), 180, 1.2, padre, true)

	# ═══ ÁRBOLES en los bordes ═══
	_obj(U+"tree-large.glb", Vector3(-44, 0, -44), 0, 1.0, padre, false)
	_obj(U+"tree-park-large.glb", Vector3(44, 0, -44), 45, 1.0, padre, false)
	_obj(U+"tree-pine-large.glb", Vector3(-44, 0, 44), 90, 1.0, padre, false)
	_obj(U+"tree-large.glb", Vector3(44, 0, 44), 135, 1.0, padre, false)
	_obj(U+"tree-small.glb", Vector3(-44, 0, -20), 0, 1.0, padre, false)
	_obj(U+"tree-small.glb", Vector3(-44, 0, 20), 60, 1.0, padre, false)
	_obj(U+"tree-pine-small.glb", Vector3(44, 0, -20), 120, 1.0, padre, false)
	_obj(U+"tree-pine-small.glb", Vector3(44, 0, 20), 180, 1.0, padre, false)
	_obj(U+"tree-shrub.glb", Vector3(-30, 0, -44), 0, 1.0, padre, false)
	_obj(U+"tree-shrub.glb", Vector3(30, 0, -44), 90, 1.0, padre, false)
	_obj(U+"tree-shrub.glb", Vector3(-30, 0, 44), 45, 1.0, padre, false)
	_obj(U+"tree-shrub.glb", Vector3(30, 0, 44), 135, 1.0, padre, false)

	# ═══ POSTES DE LUZ ═══
	_obj(E+"StreetLights.gltf", Vector3(-20, 0, -20), 0, 1.2, padre, false)
	_obj(E+"StreetLights.gltf", Vector3(20, 0, -20), 0, 1.2, padre, false)
	_obj(E+"StreetLights.gltf", Vector3(-20, 0, 20), 0, 1.2, padre, false)
	_obj(E+"StreetLights.gltf", Vector3(20, 0, 20), 0, 1.2, padre, false)

	# ═══ BASURA Y DETALLES DISPERSOS ═══
	var detalles = [
		[E+"Barrel.gltf", Vector3(-18, 0, -30)],
		[E+"Barrel.gltf", Vector3(15, 0, 32)],
		[E+"TrashBag_1.gltf", Vector3(-8, 0, -25)],
		[E+"TrashBag_2.gltf", Vector3(10, 0, 28)],
		[E+"TrashBag_1.gltf", Vector3(25, 0, -10)],
		[E+"Wheel.gltf", Vector3(-28, 0, 10)],
		[E+"Wheels_Stack.gltf", Vector3(32, 0, 12)],
		[E+"CinderBlock.gltf", Vector3(-15, 0, 18)],
		[E+"CinderBlock.gltf", Vector3(18, 0, -18)],
		[E+"Pallet.gltf", Vector3(-32, 0, -18)],
		[E+"Pallet_Broken.gltf", Vector3(28, 0, 22)],
		[E+"FireHydrant.gltf", Vector3(-22, 0, 0)],
		[E+"FireHydrant.gltf", Vector3(22, 0, 5)],
		[E+"Couch.gltf", Vector3(-25, 0, -12)],
		[E+"Pipes.gltf", Vector3(30, 0, -22)],
		[E+"TrafficCone_1.gltf", Vector3(-5, 0, -30)],
		[E+"TrafficCone_2.gltf", Vector3(5, 0, 30)],
		[E+"TrafficCone_1.gltf", Vector3(-30, 0, -5)],
		[E+"TrafficCone_2.gltf", Vector3(30, 0, 5)],
		[E+"Chest.gltf", Vector3(-15, 0, -35)],
		[E+"Chest_Special.gltf", Vector3(15, 0, 35)],
	]
	for d in detalles:
		_obj(d[0], d[1], randf_range(0, 360), 1.2, padre, false)

	# ═══ MANCHAS DE SANGRE ═══
	var sangre = [
		Vector3(-10, 0.1, -15), Vector3(8, 0.1, 12),
		Vector3(-25, 0.1, 5), Vector3(20, 0.1, -25),
		Vector3(0, 0.1, -35), Vector3(-5, 0.1, 30),
	]
	for pos in sangre:
		var blood = ["Blood_1.gltf", "Blood_2.gltf", "Blood_3.gltf"]
		_obj(E + blood[randi() % 3], pos, randf_range(0, 360), 1.0, padre, false)

	# ═══ DUMPSTERS / BASUREROS ═══
	_obj(U+"detail-dumpster-open.glb", Vector3(-35, 0, -10), 45, 1.0, padre, true)
	_obj(U+"detail-dumpster-closed.glb", Vector3(35, 0, 10), -45, 1.0, padre, true)

	# ═══ MUROS ROTOS (esquina tipo edificio destruido) ═══
	_obj(U+"wall-broken-type-a.glb", Vector3(-40, 0, -40), 0, 1.2, padre, true)
	_obj(U+"wall-broken-type-b.glb", Vector3(-40, 0, -36), 0, 1.2, padre, true)
	_obj(U+"wall-a-flat-window.glb", Vector3(-36, 0, -40), 90, 1.2, padre, true)

	print("Decorador: mapa poblado estilo apocalíptico")

func _obj(ruta: String, pos: Vector3, rot_y: float, escala: float, padre: Node, _unused := false):
	if not ResourceLoader.exists(ruta):
		return
	var escena = load(ruta)
	if escena == null:
		return
	var inst = escena.instantiate()
	var body = StaticBody3D.new()
	body.position = pos
	body.rotation_degrees.y = rot_y
	body.scale = Vector3(escala, escala, escala)
	body.add_child(inst)
	# Calcular AABB del modelo para crear colisión que respete su tamaño
	padre.add_child(body)
	call_deferred("_agregar_colision_aabb", body, inst)

func _agregar_colision_aabb(body: StaticBody3D, modelo: Node):
	var aabb = AABB()
	var encontro := false
	for child in _buscar_meshes(modelo):
		if child is MeshInstance3D and child.mesh != null:
			var mesh_aabb = child.mesh.get_aabb()
			if not encontro:
				aabb = mesh_aabb
				encontro = true
			else:
				aabb = aabb.merge(mesh_aabb)
	if not encontro:
		aabb = AABB(Vector3(-0.5, 0, -0.5), Vector3(1, 2, 1))
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = aabb.size
	col.shape = shape
	col.position = aabb.position + aabb.size * 0.5
	body.add_child(col)

func _buscar_meshes(nodo: Node) -> Array:
	var resultado := []
	if nodo is MeshInstance3D:
		resultado.append(nodo)
	for hijo in nodo.get_children():
		resultado.append_array(_buscar_meshes(hijo))
	return resultado

func _crear_bordes(padre: Node):
	var reja = G + "iron-fence.glb"
	var col_reja = G + "iron-fence-border-column.glb"
	var limite = 48.0
	var espaciado = 2.0
	var apertura = 5.0
	var esc = Vector3(1.8, 2.5, 1.8)

	for borde in [
		{"eje": "x", "fijo": "z", "val": -limite, "rot": 0},
		{"eje": "x", "fijo": "z", "val": limite, "rot": 180},
		{"eje": "z", "fijo": "x", "val": -limite, "rot": 90},
		{"eje": "z", "fijo": "x", "val": limite, "rot": -90},
	]:
		var v = -limite
		while v <= limite:
			if abs(v) < apertura:
				v += espaciado
				continue
			var pos = Vector3.ZERO
			if borde["eje"] == "x":
				pos = Vector3(v, 0, borde["val"])
			else:
				pos = Vector3(borde["val"], 0, v)
			_poner_reja(reja, pos, borde["rot"], esc, padre)
			v += espaciado

	# Muros invisibles
	_muro(Vector3(0, 3, -limite), Vector3(limite * 2, 8, 1), padre)
	_muro(Vector3(0, 3, limite), Vector3(limite * 2, 8, 1), padre)
	_muro(Vector3(-limite, 3, 0), Vector3(1, 8, limite * 2), padre)
	_muro(Vector3(limite, 3, 0), Vector3(1, 8, limite * 2), padre)

func _poner_reja(ruta: String, pos: Vector3, rot_y: float, escala: Vector3, padre: Node):
	if not ResourceLoader.exists(ruta):
		return
	var inst = load(ruta).instantiate()
	inst.position = pos
	inst.rotation_degrees.y = rot_y
	inst.scale = escala
	padre.add_child(inst)

func _muro(pos: Vector3, tamano: Vector3, padre: Node):
	var body = StaticBody3D.new()
	body.position = pos
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = tamano
	col.shape = shape
	body.add_child(col)
	padre.add_child(body)
