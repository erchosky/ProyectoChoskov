class_name RaidWorld
extends Node3D
var nav = AStarGrid2D.new()
const LOOT_LOCATIONS = [Vector2(-21, 18), Vector2(-25, 8), Vector2(-20, -3), Vector2(-8, 8), Vector2(-4, -10), Vector2(4, 17), Vector2(20, 15), Vector2(9, -12), Vector2(19, -15), Vector2(17, -5), Vector2(26, -15), Vector2(-17, -23)]
var containers: Array = []
var extraction_zones: Array = [{"name": "Sendero del sur", "p": Vector2(-26, 19), "radio":false}, {"name": "Torre de radio", "p": Vector2(27, -24), "radio":true}]
var notes: Array = []
var roofs: Array[MeshInstance3D] = []
var rng = RandomNumberGenerator.new()
var clearance_shape = SphereShape3D.new()
const CELL_SIZE = 0.5

func build(seed_value: int, shelter: bool = false) -> void:
	rng.seed = seed_value
	nav.region = Rect2i(-68, -68, 136, 136)
	nav.cell_size = Vector2.ONE*CELL_SIZE
	clearance_shape.radius = .44
	nav.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	nav.update()
	var env = WorldEnvironment.new()
	var resource = Environment.new()
	resource.background_mode = Environment.BG_COLOR
	resource.background_color = Color("6d818b")
	resource.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	resource.ambient_light_color = Color("9bb5c3")
	resource.ambient_light_energy = 0.65
	resource.fog_enabled = true
	resource.fog_density = 0.004
	resource.fog_light_color = Color("849398")
	resource.fog_sky_affect = 0.0
	resource.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.environment = resource
	add_child(env)
	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-38, -32, 0)
	sun.light_color = Color("f2c595")
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 58
	add_child(sun)
	Art.box(self, Vector3(0, -0.26, 0), Vector3(110, 0.5, 110), Color("49544d")).material_override = Art.surface(Color("49544d"),.045)
	# Hand-authored network: safe south camp, crossing roads, warehouse north-east.
	Art.box(self, Vector3(-13, 0.02, 1), Vector3(5, 0.03, 57), Color("414b50")).material_override = Art.surface(Color("414b50"),.18)
	Art.box(self, Vector3(3, 0.025, 12), Vector3(56, 0.04, 4), Color("414b50")).material_override = Art.surface(Color("414b50"),.18)
	Art.box(self, Vector3(14, 0.04, -10), Vector3(18, 0.08, 18), Color("686e6b")).material_override = Art.concrete(Color("a8afae"),.12)
	for p in [Vector3(-34, 0.4, 0), Vector3(34, 0.4, 0)]:
		obstacle(p, Vector3(1, 0.8, 68), Color("53634f"))
	for p in [Vector3(0, 0.4, -34), Vector3(0, 0.4, 34)]:
		obstacle(p, Vector3(68, 0.8, 1), Color("53634f"))
	# Warehouse walls, three routes in. Roof disappears near/inside the building.
	obstacle(Vector3(14, 1.6, -19), Vector3(19, 3.2, 0.6), Color("737b7b"))
	obstacle(Vector3(23, 1.6, -11), Vector3(0.6, 3.2, 16), Color("626c6f"))
	obstacle(Vector3(5, 1.6, -15), Vector3(0.6, 3.2, 8), Color("737b7b"))
	obstacle(Vector3(5, 1.6, -4.5), Vector3(0.6, 3.2, 3), Color("737b7b"))
	obstacle(Vector3(8, 1.6, -2), Vector3(6, 3.2, 0.6), Color("737b7b"))
	obstacle(Vector3(19, 1.6, -2), Vector3(8, 3.2, 0.6), Color("737b7b"))
	roofs.append(Art.box(self, Vector3(14, 3.3, -10), Vector3(19.5, 0.22, 18), Color("374950")))
	Art.label(self, "ALMACÉN 07", Vector3(14, 4.3, -1), Color("f8dca1"), 48)
	for p in [Vector3(9, 0.8, -15), Vector3(18, 0.8, -8), Vector3(10, 0.8, -7)]:
		obstacle(p, Vector3(2.5, 1.6, 2.5), Color("5f7176"))
		Art.box(self, p + Vector3(0, 0.86, 0), Vector3(2.6, 0.12, 2.6), Color("667b7b"))
	# Small abandoned service station and low cover.
	obstacle(Vector3(-20, 1.4, -8), Vector3(7, 2.8, 0.5), Color("68756c"))
	obstacle(Vector3(-23.5, 1.4, -4), Vector3(0.5, 2.8, 8), Color("68756c"))
	Art.box(self, Vector3(-20, 0.05, -4), Vector3(7, 0.1, 8), Color("687068"))
	Art.label(self, "PUESTO FORESTAL", Vector3(-20, 3.5, -8), Color("d5dfc1"), 34)
	for p in [Vector3(-6, 0.65, 12), Vector3(-10, 0.65, 2), Vector3(1, 0.65, 4), Vector3(22, 0.65, 9), Vector3(-8, 0.65, -16)]:
		obstacle(p, Vector3(3, 1.3, 1.2), Color("7b8464"))
		Art.box(self, p + Vector3(0, 0.68, 0), Vector3(3.1, 0.1, 1.3), Color("a6aa81"))
	var wreck = obstacle(Vector3(-19,1,5),Vector3(2,2,3.7),Color("59686b"))
	wreck.get_child(0).visible = false
	Art.wreck_van(self,Vector3(-19,0,5))
	for i in 50:
		var edge = Vector3(rng.randf_range(-48,48),0,rng.randf_range(-48,48))
		if absf(edge.x)>35 or absf(edge.z)>35:
			tree(edge)
	for i in 70:
		var x = rng.randf_range(-31, 31)
		var z = rng.randf_range(-31, 31)
		if absf(x + 13) < 4 or absf(z - 12) < 4 or (x > 2 and x < 26 and z > -22 and z < 1) or Vector2(x, z).distance_to(Vector2(-24, 22)) < 9:
			continue
		var point = Vector2(x,z)
		if point.distance_to(Vector2(-19,5))<4 or point.distance_to(Vector2(-26,-22))<8 or Catalog.expedition.supply_points.any(func(p): return point.distance_to(Vector2(p[0],p[1]))<6):
			continue
		if Catalog.notes.any(func(note): return point.distance_to(Vector2(note.p[0],note.p[1]))<2.5) or LOOT_LOCATIONS.any(func(p): return point.distance_to(p)<2) or extraction_zones.any(func(zone): return point.distance_to(zone.p)<4):
			continue
		tree(Vector3(x, 0, z))
	# An optional fortified clearing in the north-west, with a southern entrance.
	Art.box(self,Vector3(-27,.05,-23),Vector3(10,.1,10),Color("606962"))
	obstacle(Vector3(-27,1.5,-28),Vector3(10,3,.5),Color("525e60"))
	obstacle(Vector3(-32,1.5,-23),Vector3(.5,3,10),Color("525e60"))
	obstacle(Vector3(-22,1.5,-26),Vector3(.5,3,4),Color("525e60"))
	Art.label(self,"PUESTO NORTE",Vector3(-27,3.5,-28),Color("e5bd94"),40)
	for zone in extraction_zones:
		var p: Vector2 = zone.p
		var ring = Art.cylinder(self, Vector3(p.x, 0.1, p.y), 2.8, 0.12, Color("a6d391"))
		ring.material_override = Art.material(Color("edb26c") if zone.radio else Color("91cda4"), true)
		ring.mesh.radial_segments = 32
		zone.ring = ring
		zone.inner = Art.cylinder(self, Vector3(p.x, 0.18, p.y), 2.45, 0.12, Color("856d50") if zone.radio else Color("527e65"))
		zone.inner.mesh.radial_segments = 32
		if not shelter:
			Art.label(self, ("RADIO · 1 BATERÍA\n" if zone.radio else "EXTRACCIÓN\n") + zone.name, Vector3(p.x, 3.6, p.y), Color("d5fac7"), 36)
		Art.cylinder(self, Vector3(p.x + 2, 1.8, p.y), 0.08, 3.6, Color("d4dfb6"))
		Art.box(self, Vector3(p.x + 2.7, 3.2, p.y), Vector3(1.3, 0.65, 0.1), Color("acd87d"))
	var locations = LOOT_LOCATIONS
	var common = ["scrap", "wire", "cloth", "ammo9", "bandage", "filter", "battery"]
	var rare = ["circuit", "ammo556", "medkit", "armor", "pack"]
	for i in locations.size():
		var contents: Dictionary = {}
		var pool: Array = rare if i in [7, 8, 9] else common
		for n in 3:
			var id: String = pool[rng.randi_range(0, pool.size() - 1)]
			var qty = rng.randi_range(10, 24) if id.begins_with("ammo") else rng.randi_range(1, 3)
			if Catalog.items[id].stack == 1:
				qty = 1
			contents[id] = int(contents.get(id, 0)) + qty
		if i == 0:
			contents = {"scrap": 3, "wire": 2, "bandage": 1, "decoy":1}
		if i == 2:
			contents["outpost_key"] = 1
			contents["cloth"] = 3
		if i == 8:
			contents["recorder"] = 1
		if i == 9:
			contents["rifle"] = 1
		if i == 10:
			contents["battery"] = maxi(1,int(contents.get("battery",0)))
		add_container(locations[i], contents, "Caja de suministros" if i < 7 else "Reserva industrial")
	add_container(Vector2(-27,-25),{"shotgun":1,"ammo20":18,"cipher":1,"circuit":2},"Reserva del puesto norte","outpost_key","locked")
	if shelter:
		Art.box(self, Vector3(-24, 0.15, 24), Vector3(10, 0.3, 9), Color("5d665d"))
		obstacle(Vector3(-24, 1.6, 28), Vector3(10, 3.2, 0.4), Color("596e70"))
		Art.box(self, Vector3(-28, 0.9, 25), Vector3(1.8, 1.8, 2.5), Color("a78354"))
		Art.box(self, Vector3(-20, 0.5, 25), Vector3(2, 1, 3), Color("6c8875"))

	industrial_details()
	var excluded: Array = []
	excluded.append_array(roofs)
	for child in get_children():
		if child is Effects:
			excluded.append(child)
	for c in containers:
		excluded.append(c.node)
	for zone in extraction_zones:
		excluded.append(zone.ring)
		excluded.append(zone.inner)
	Art.batch_world(self,excluded)
	# Interactive story props remain outside immutable scenery batches.
	for note in ([] if shelter else Catalog.notes):
		var node = Node3D.new()
		node.position = Vector3(note.p[0],0,note.p[1])
		add_child(node)
		Art.box(node,Vector3(0,0.7,0),Vector3(0.7,0.12,0.45),Color("a8c4da"))
		var icon = Art.label(node,"DIARIO",Vector3(0,1.6,0),Color("b1dbed"),25)
		notes.append({"id":note.id,"node":node,"icon":icon})
	# Original tower silhouette gives the northern exit a visual landmark.
	for x in [-0.6,0.6]:
		Art.cylinder(self,Vector3(29+x,3,-24),0.08,6,Color("a2b4a9"))
	Art.box(self,Vector3(29,4.8,-24),Vector3(2.5,0.15,0.2),Color("d8c098"))
	Art.cylinder(self,Vector3(29,6.3,-24),0.07,2.5,Color("d8c098"))

func tree(p: Vector3) -> void:
	var h = rng.randf_range(2.8, 5.2)
	var body = StaticBody3D.new()
	body.position = p
	body.collision_layer = 1
	add_child(body)
	var shape = CollisionShape3D.new()
	var resource = CylinderShape3D.new()
	resource.radius = 0.32
	resource.height = 2.5
	shape.shape = resource
	shape.position.y = 1.25
	body.add_child(shape)
	Art.cylinder(body, Vector3(0, h * 0.3, 0), 0.25, h * 0.6, Color("514b41"))
	for tier in 4:
		var branch = Art.cylinder(body,Vector3(.12*sin(tier*2),h*(.43+tier*.15),.1*cos(tier*2)),1.55-tier*.28,h*.38,Color("2d4947") if tier%2==0 else Color("3a5149"),true)
		branch.rotation_degrees.z = 4 if tier%2==0 else -5
	Art.cylinder(body, Vector3(0, h * 0.95, 0), 1.0, h * 0.55, Color("3f5b51"), true)
	mark(p, Vector3(1, 2, 1))

func obstacle(p: Vector3, size: Vector3, color: Color) -> StaticBody3D:
	var body = StaticBody3D.new()
	body.position = p
	body.collision_layer = 1
	add_child(body)
	Art.box(body, Vector3.ZERO, size, color).material_override = Art.surface(color,.09)
	var shape = CollisionShape3D.new()
	var resource = BoxShape3D.new()
	resource.size = size
	shape.shape = resource
	body.add_child(shape)
	mark(p, size)
	return body

func mark(p: Vector3, size: Vector3) -> void:
	for x in range(floori((p.x-size.x/2-.46)/CELL_SIZE),ceili((p.x+size.x/2+.46)/CELL_SIZE)+1):
		for z in range(floori((p.z-size.z/2-.46)/CELL_SIZE),ceili((p.z+size.z/2+.46)/CELL_SIZE)+1):
			if nav.is_in_boundsv(Vector2i(x, z)):
				nav.set_point_solid(Vector2i(x, z))

func add_container(p: Vector2, items: Dictionary, title: String, locked_key: String = "", kind: String = "supplies") -> Dictionary:
	var node = Node3D.new()
	node.position = Vector3(p.x, 0, p.y)
	add_child(node)
	Art.box(node, Vector3(0, 0.45, 0), Vector3(1.25, 0.9, 0.85), Color("82aeb4") if kind=="airdrop" else (Color("9d7863") if kind=="locked" else Color("88775a")))
	Art.box(node, Vector3(0, 0.94, 0), Vector3(1.3, 0.12, 0.9), Color("b2a17d"))
	Art.box(node, Vector3(0, 0.49, -0.44), Vector3(0.18, 0.25, 0.02), Color("dee4c4"))
	var icon = Art.label(node, "+", Vector3(0, 1.7, 0), Color("ffe0a2"), 40)
	var result = {"p": [p.x, p.y], "items": items, "name": title, "node": node, "icon": icon,"locked_key":locked_key,"kind":kind}
	containers.append(result)
	return result

# Swept volume, not just a center ray: every smoothed segment clears a body.
func occupied(p: Vector3) -> bool:
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = clearance_shape
	query.transform.origin = Vector3(p.x,1,p.z)
	query.collision_mask = 1
	query.margin = .015
	return not get_world_3d().direct_space_state.intersect_shape(query,1).is_empty()

# Old saves can overlap scenery introduced by an update. Only repair a spawn,
# never teleport a character trying to move through a wall during gameplay.
func safe_spawn(p: Vector3) -> Vector3:
	if not occupied(p):
		return p
	var center = Vector2i(roundi(p.x/CELL_SIZE),roundi(p.z/CELL_SIZE))
	var best = p
	var distance = INF
	for dx in range(-8,9):
		for dz in range(-8,9):
			var cell = center+Vector2i(dx,dz)
			if not nav.is_in_boundsv(cell) or nav.is_point_solid(cell):
				continue
			var point = Vector3(cell.x*CELL_SIZE,0,cell.y*CELL_SIZE)
			if point.distance_to(p)<distance and not occupied(point):
				best = point
				distance = point.distance_to(p)
	return best

func can_travel(from: Vector3, to: Vector3) -> bool:
	if from.distance_to(to)<.01:
		return true
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = clearance_shape
	query.transform.origin = Vector3(from.x,1,from.z)
	query.motion = Vector3(to.x-from.x,0,to.z-from.z)
	query.collision_mask = 1
	query.margin = .015
	var fractions = get_world_3d().direct_space_state.cast_motion(query)
	return fractions[0]>=.999

func nearest_cell(p: Vector3) -> Variant:
	var center = Vector2i(roundi(p.x/CELL_SIZE),roundi(p.z/CELL_SIZE))
	if not nav.is_in_boundsv(center):
		return null
	var best: Variant = null
	var best_distance = INF
	for ring in range(0,7):
		for dx in range(-ring,ring+1):
			for dz in range(-ring,ring+1):
				if maxi(absi(dx),absi(dz))!=ring:
					continue
				var candidate = center+Vector2i(dx,dz)
				if not nav.is_in_boundsv(candidate) or nav.is_point_solid(candidate):
					continue
				var point = Vector3(candidate.x*CELL_SIZE,0,candidate.y*CELL_SIZE)
				var distance = point.distance_to(p)
				if distance<best_distance and can_travel(p,point):
					best = candidate
					best_distance = distance
		if best!=null:
			break
	return best

func path(from: Vector3, to: Vector3) -> PackedVector2Array:
	var a = nearest_cell(from)
	var b = nearest_cell(to)
	if a==null or b==null:
		return PackedVector2Array()
	var raw = nav.get_point_path(a,b)
	if raw.is_empty():
		return raw
	raw.insert(0,Vector2(from.x,from.z))
	var result = PackedVector2Array([raw[0]])
	var anchor = 0
	while anchor<raw.size()-1:
		var next = anchor+1
		for i in range(anchor+1,mini(raw.size(),anchor+13)):
			if not can_travel(Vector3(raw[anchor].x,0,raw[anchor].y),Vector3(raw[i].x,0,raw[i].y)):
				break
			next = i
		result.append(raw[next])
		anchor = next
	return result

func update_roof(p: Vector3) -> void:
	for roof in roofs:
		roof.visible = not (p.x > 0 and p.x < 28 and p.z > -24 and p.z < 4)

func update_exits(radio_powered: bool) -> void:
	for zone in extraction_zones:
		if zone.radio:
			zone.ring.material_override = Art.material(Color("91cda4") if radio_powered else Color("edb26c"),true)
			zone.inner.material_override = Art.material(Color("527e65") if radio_powered else Color("856d50"))

# Decoration uses the existing cover footprint, keeping routes and ballistics intact.
func industrial_details() -> void:
	for z in range(-25,29,4):
		Art.box(self,Vector3(-13,.046,z),Vector3(.12,.015,1.4),Color("b7ae87"))
		for x in [-15.3,-10.7]:
			Art.box(self,Vector3(x,.052,z),Vector3(.08,.018,2.8),Color("777e73"))
	for x in range(-23,30,5):
		Art.box(self,Vector3(x,.06,12),Vector3(1.7,.015,.12),Color("b7ae87"))
	var water = Art.material(Color("52666c")).duplicate()
	water.roughness = .19
	water.metallic = .25
	for p in [Vector3(-14.8,.055,5),Vector3(-11.3,.055,-13),Vector3(2,.08,13.1),Vector3(24,.08,11),Vector3(-16.5,.06,-8)]:
		var puddle = Art.sphere(self,p,Vector3(2.8,.018,1.4),Color("52666c"))
		puddle.material_override = water
	for z in [-20,-12,3,18,25]:
		var crack = Art.box(self,Vector3(-12.4,.058,z),Vector3(2,.015,.035),Color("2e393f"))
		crack.rotation.y = .4
	# Corrugated steel, rust seams and a broken intake on the warehouse walls.
	for x in range(5,24):
		Art.box(self,Vector3(x,1.6,-18.65),Vector3(.045,3,.08),Color("4e5a5c"))
	for x in [8,14,20]:
		Art.box(self,Vector3(x,2.5,-18.6),Vector3(2.2,.045,.06),Color("a79b78"))
		Art.box(self,Vector3(x,.65,-18.62),Vector3(.32,1.1,.035),Color("79634f"))
	Art.box(self,Vector3(22.6,.7,-12),Vector3(.12,.9,3),Color("3e484b"))
	for z in range(-13,-9):
		Art.box(self,Vector3(22.5,.75,z),Vector3(.06,.04,.65),Color("8c8676"))
	for p in [Vector3(9,0,-15),Vector3(18,0,-8),Vector3(10,0,-7)]:
		for x in [-.9,.9]:
			Art.box(self,p+Vector3(x,.85,-1.27),Vector3(.07,1.6,.03),Color("504c3d"))
		for z in [-.9,.9]:
			Art.box(self,p+Vector3(0,1.73,z),Vector3(2.55,.04,.07),Color("514e45"))
	for p in [Vector3(-19,0,-7.5),Vector3(22.65,0,-17),Vector3(-31.5,0,-25)]:
		for x in [-.42,.42]:
			Art.cylinder(self,p+Vector3(x,.6,0),.37,1.2,Color("6d5546"))
			for y in [.14,1.08]:
				Art.cylinder(self,p+Vector3(x,y,0),.39,.07,Color("333e40"))
	for p in [Vector3(-23.3,0,-6),Vector3(22.7,0,-4),Vector3(-31.7,0,-27),Vector3(-27,0,27.6)]:
		Art.cylinder(self,p+Vector3(0,1.8,0),.065,3.6,Color("39494f"))
		var lamp = Art.box(self,p+Vector3(0,3.2,.23),Vector3(.25,.18,.5),Color("f1bf75"))
		lamp.material_override = Art.material(Color("e6ad65"),true)
		var light = OmniLight3D.new()
		light.position = p+Vector3(0,2.8,.3)
		light.light_color = Color("efb069")
		light.light_energy = 1.1
		light.omni_range = 5
		add_child(light)
	for i in 160:
		var p = Vector3(rng.randf_range(-32,32),.09,rng.randf_range(-32,32))
		if absf(p.x+13)<3 or absf(p.z-12)<2.6 or (p.x>2 and p.x<26 and p.z>-22 and p.z<1) or Vector2(p.x,p.z).distance_to(Vector2(-24,22))<7:
			continue
		var grass = Art.box(self,p,Vector3(.045,rng.randf_range(.25,.45),.15),Color("66705a"))
		grass.rotation.y = rng.randf_range(0,PI)
		grass.rotation.z = .35
	Art.label(self,"CUARENTENA / SECTOR 07",Vector3(14,2.6,-18.4),Color("c3b597"),24)
	Art.label(self,"NO HAY EVACUACIÓN CIVIL",Vector3(-20,1.7,-7.6),Color("c6b197"),19)
