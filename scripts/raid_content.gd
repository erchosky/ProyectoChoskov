class_name RaidContent
extends RefCounted
var game: Node3D
var beacons: Dictionary = {}
var delivery_marker: Node3D

func _init(host: Node3D) -> void:
	game = host
	var raid: Dictionary = game.raid
	if not raid.has("delivery"):
		raid.delivery = "waiting"
	if not raid.has("delivery_point"):
		var points: Array = Catalog.expedition.supply_points
		raid.delivery_point = points[posmod(int(raid.seed),points.size())].duplicate()
	if not raid.has("warden_spawned"):
		raid.warden_spawned = game.enemies.any(func(enemy): return enemy.kind=="warden")
	if not raid.has("decoys"):
		raid.decoys = []
	if not raid.has("decoy_serial"):
		raid.decoy_serial = 0
	if not raid.has("decoy_cd"):
		raid.decoy_cd = 0.0
	for decoy in raid.decoys:
		create_beacon(decoy)
	if raid.delivery=="incoming":
		create_delivery_marker()

func tick(delta: float) -> void:
	if game.mode!="raid" or game.paused:
		return
	var raid: Dictionary = game.raid
	raid.decoy_cd = maxf(0,float(raid.decoy_cd)-delta)
	var surviving: Array = []
	for decoy in raid.decoys:
		decoy.remaining = maxf(0,float(decoy.remaining)-delta)
		if decoy.remaining>0:
			surviving.append(decoy)
			game.make_noise(Vector3(decoy.p[0],0,decoy.p[1]),22)
			if is_instance_valid(beacons.get(decoy.id)):
				beacons[decoy.id].scale = Vector3.ONE*(1+0.12*sin(float(raid.time)*9))
		else:
			if is_instance_valid(beacons.get(decoy.id)):
				beacons[decoy.id].queue_free()
			beacons.erase(decoy.id)
	raid.decoys = surviving
	var boss: Array = Catalog.expedition.boss_position
	if not raid.warden_spawned and game.player.position.distance_to(Vector3(boss[0],0,boss[1]))<13:
		raid.warden_spawned = true
		game.spawn_enemy("warden",Vector3(boss[0],0,boss[1]))
		game.notify("Puesto norte · el capataz está cerca")
		game.checkpoint()
	if raid.delivery=="waiting" and raid.time>=Catalog.expedition.announce:
		raid.delivery = "incoming"
		create_delivery_marker()
		game.notify("Vera: «Entrega en 15 segundos. La señal aparece en el mapa.»")
		game.checkpoint()
	if raid.delivery=="incoming":
		if is_instance_valid(delivery_marker):
			delivery_marker.position.y = lerpf(14,1,clampf((float(raid.time)-float(Catalog.expedition.announce))/15,0,1))
		if raid.time>=Catalog.expedition.arrival:
			land_delivery()

func create_delivery_marker() -> void:
	if is_instance_valid(delivery_marker):
		return
	var p: Array = game.raid.delivery_point
	delivery_marker = Node3D.new()
	delivery_marker.position = Vector3(p[0],14,p[1])
	game.world.add_child(delivery_marker)
	Art.box(delivery_marker,Vector3.ZERO,Vector3(1.4,1,1),Color("83b4b2"))
	Art.sphere(delivery_marker,Vector3(0,3,0),Vector3(3,0.6,3),Color("e3d7a9"))
	for x in [-.6,.6]:
		Art.cylinder(delivery_marker,Vector3(x,1.6,0),.035,2.5,Color("ecdfae"))
	Art.label(delivery_marker,"SUMINISTROS",Vector3(0,4.2,0),Color("aedbe0"),32)

func land_delivery() -> void:
	if game.raid.delivery!="incoming":
		return
	# Event flag, chest and reinforcements are included in the same checkpoint.
	game.raid.delivery = "landed"
	if is_instance_valid(delivery_marker):
		delivery_marker.queue_free()
	var p = Vector2(game.raid.delivery_point[0],game.raid.delivery_point[1])
	game.world.add_container(p,{"ammo20":18,"medkit":1,"circuit":2,"decoy":1},"Entrega de Vera","","airdrop")
	for offset in [Vector2(-4,0),Vector2(4,0)]:
		var point = p+offset
		game.spawn_enemy("runner",Vector3(point.x,0,point.y))
	game.notify("Suministros recibidos · dos merodeadores siguen la señal")
	game.checkpoint()

func throw_decoy() -> bool:
	if game.mode!="raid" or game.paused or game.raid.decoy_cd>0:
		return false
	if not game.raid.bag.has("decoy"):
		game.notify("No llevas señuelos · fabrícalos en el refugio")
		return false
	# Stop at a wall rather than spawning the lure on its far side.
	var origin: Vector3 = game.player.position+Vector3(0,1.15,0)
	var direction = Vector3(game.player.aim.x,0,game.player.aim.y)
	var endpoint = origin+direction*7
	var query = PhysicsRayQueryParameters3D.create(origin,endpoint,1,[game.player.get_rid()])
	var hit = game.get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		endpoint = hit.position-direction*.7
	var point = Vector2(clampf(endpoint.x,-32,32),clampf(endpoint.z,-32,32))
	Inventory.remove(game.raid.bag,"decoy",1)
	game.raid.decoy_cd = 3.0
	game.raid.decoy_serial += 1
	var decoy = {"id":str(game.raid.decoy_serial),"p":[point.x,point.y],"remaining":8.0}
	game.raid.decoys.append(decoy)
	create_beacon(decoy)
	game.make_noise(Vector3(point.x,0,point.y),22)
	game.sound.play("loot")
	game.notify("Señuelo activo · las patrullas investigan el ruido")
	game.checkpoint()
	return true

func create_beacon(decoy: Dictionary) -> void:
	var node = Node3D.new()
	node.position = Vector3(decoy.p[0],0,decoy.p[1])
	game.world.add_child(node)
	Art.cylinder(node,Vector3(0,.12,0),.3,.24,Color("8bc4c5"))
	Art.label(node,"RUIDO",Vector3(0,1.2,0),Color("b1dfe0"),24)
	beacons[decoy.id] = node

func status() -> String:
	if game.raid.delivery=="incoming":
		return "ENTREGA EN %d s · mira la señal azul" % ceili(maxf(0,float(Catalog.expedition.arrival)-float(game.raid.time)))
	if game.raid.delivery=="landed" and game.world.containers.any(func(c): return c.get("kind","")=="airdrop" and not c.items.is_empty()):
		return "Entrega disponible · otros siguen la señal"
	return ""
