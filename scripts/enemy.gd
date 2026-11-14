class_name Raider
extends CharacterBody3D
var game: Node3D
var kind = "runner"
var config: Dictionary
var model: Node3D
var health = 65.0
var alive = true
var mode = "patrol"
var home = Vector3.ZERO
var target = Vector3.ZERO
var last_seen = Vector3.ZERO
var seen_timer = 0.0
var think = 0.0
var cooldown = 1.0
var search_timer = 0.0
var path = PackedVector2Array()
var waypoint = 0
var label: Label3D
var patrol_index = 0
var windup = 0.0
var attack_target = Vector3.ZERO
var warning: MeshInstance3D
var stride = 0.0
var repath = 0.0
var path_goal = Vector3.INF
var blocked_for = 0.0
var detour = Vector3.ZERO
var detour_timer = 0.0
var hit_reaction = 0.0
var spawn_checked = false

func configure(host: Node3D, type_value: String, p: Vector3, saved: Dictionary = {}) -> void:
	game = host
	kind = type_value
	config = Catalog.enemies[kind].duplicate(true)
	health = saved.get("health", config.health)
	alive = health > 0
	position = p
	home = Vector3(saved.get("home", [p.x, p.z])[0], 0, saved.get("home", [p.x, p.z])[1])
	mode = saved.get("mode", "patrol")
	last_seen = Vector3(saved.get("last", [p.x, p.z])[0], 0, saved.get("last", [p.x, p.z])[1])
	seen_timer = saved.get("seen_timer", 0)
	search_timer = saved.get("search_timer", 0)
	cooldown = saved.get("cooldown", 1)
	target = Vector3(saved.get("target", [p.x + 2, p.z])[0], 0, saved.get("target", [p.x + 2, p.z])[1])
	collision_layer = 4 if alive else 0
	collision_mask = 1 | 2 | 4
	var shape = CollisionShape3D.new()
	var capsule = CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.8
	shape.shape = capsule
	shape.position.y = 0.9
	add_child(shape)
	model = Art.animal(self, Color(config.color))
	label = Art.label(self, "", Vector3(0, 2.6, 0), Color("ffd295"), 30)
	windup = saved.get("windup",0.0)
	var locked: Array = saved.get("attack_target",[p.x,p.z])
	attack_target = Vector3(locked[0],0,locked[1])
	warning = Art.cylinder(self,Vector3(0,0.08,0),0.8,0.04,Color("f3a16c"))
	warning.material_override = Art.material(Color("f3a16c"),true)
	warning.visible = windup>0
	if kind in ["sentinel","warden"]:
		Art.box(model,Vector3(0,1.84,0),Vector3(0.84,0.3,0.76),Color("675967"))
	else:
		Art.box(model,Vector3(0,1.1,0.55),Vector3(0.5,0.6,0.25),Color("c78b58"))
	if kind == "warden":
		model.scale = Vector3.ONE*1.25
		model.set_meta("height_scale",1.25)
		Art.box(model,Vector3(0,1.0,-.5),Vector3(.85,.9,.18),Color("615d4d"))
		label.position.y = 3.3
		label.text = "CAPATAZ · 210"
	patrol_index = int(saved.get("patrol_index",0))
	visible = true
	if not alive:
		show_body()

func _physics_process(delta: float) -> void:
	if not alive or game.paused or game.mode != "raid":
		return
	if not spawn_checked:
		position = game.world.safe_spawn(position)
		spawn_checked = true
	hit_reaction = maxf(0,hit_reaction-delta)
	repath -= delta
	detour_timer = maxf(0,detour_timer-delta)
	if windup>0:
		windup = maxf(0,windup-delta)
		warning.visible = true
		label.text = "¡ATAQUE!"
		model.rotation.y = atan2(position.x-attack_target.x,position.z-attack_target.z)
		velocity = Vector3.ZERO
		Art.animate(model,stride,0,delta)
		if windup == 0:
			warning.visible = false
			attack(game.player)
		return
	warning.visible = false
	cooldown = maxf(0, cooldown - delta)
	think -= delta
	seen_timer += delta
	if think <= 0:
		think = 0.35
		var player: Explorer = game.player
		var dist = position.distance_to(player.position)
		var sees: bool = dist < config.sight * player.detection_scale() and game.visible_between(position, player.position, [get_rid(), player.get_rid()])
		if sees:
			mode = "chase"
			last_seen = player.position
			seen_timer = 0
			target = last_seen
		elif mode == "chase" and seen_timer > 2:
			mode = "search"
			search_timer = 7
			target = last_seen
		if mode in ["search", "investigate"]:
			search_timer = maxf(0, search_timer - 0.35)
			if search_timer <= 0:
				mode = "return"
				target = home
		if mode == "return" and position.distance_to(home) < 1.2:
			mode = "patrol"
		if mode == "patrol" and position.distance_to(target) < 1.3:
			patrol_index = (patrol_index + 1) % 4
			var offsets = [Vector3(2.5, 0, 0), Vector3(0, 0, 2.5), Vector3(-2.5, 0, 0), Vector3(0, 0, -2.5)]
			target = home + offsets[patrol_index]
		if path.is_empty() or target.distance_to(path_goal)>.7 or repath<=0:
			path = game.world.path(position,target)
			path_goal = target
			waypoint = 1 if path.size()>1 else 0
			repath = .45 if mode=="chase" else .9
		label.text = "!" if sees else ("?" if mode in ["search", "investigate"] else "")
		if sees and dist < config.range and cooldown <= 0:
			windup = float(config.get("windup",0.65 if kind == "sentinel" else 0.45))
			attack_target = player.position
			warning.visible = true
			return
	var dest = target
	while path.size()>waypoint and position.distance_to(Vector3(path[waypoint].x,0,path[waypoint].y))<.24 and waypoint<path.size()-1:
		waypoint += 1
	if path.size()>waypoint:
		dest = Vector3(path[waypoint].x,0,path[waypoint].y)
	if detour_timer>0:
		dest = detour
	var direction = dest-position
	direction.y = 0
	var stop: bool = kind in ["sentinel","warden"] and mode=="chase" and position.distance_to(game.player.position)<9 and seen_timer<.5
	var speed = float(config.speed)*(.55 if mode in ["patrol","return"] else 1.0)
	var desired = direction.normalized()*speed if direction.length()>.2 and not stop else Vector3.ZERO
	if path.is_empty() and not game.world.can_travel(position,dest):
		desired = Vector3.ZERO
	velocity = velocity.move_toward(steer(desired),delta*14)
	var before = position
	move_and_slide()
	var actual_speed = position.distance_to(before)/maxf(delta,.001)
	if desired.length()>.5 and actual_speed<.18:
		blocked_for += delta
		if blocked_for>.65:
			recover_route(direction)
	else:
		blocked_for = 0
	if mode=="chase" and seen_timer<.5:
		direction = game.player.position-position
	if direction.length()>.2:
		model.rotation.y = lerp_angle(model.rotation.y,atan2(-direction.x,-direction.z),1-exp(-delta*14))
	stride += actual_speed*delta*2.6
	Art.animate(model,stride,actual_speed,delta,false,false,model.basis.inverse()*velocity,"idle",hit_reaction)

func steer(desired: Vector3) -> Vector3:
	if desired.length()<.01:
		return Vector3.ZERO
	var separation = Vector3.ZERO
	for other in game.enemies:
		if other==self or not other.alive:
			continue
		var away = position-other.position
		away.y = 0
		var distance = away.length()
		if distance<1.5 and distance>.01:
			separation += away.normalized()*(1.5-distance)*2.2
	var adjusted = (desired+separation).limit_length(desired.length())
	if game.world.can_travel(position,position+adjusted.normalized()*.6):
		return adjusted
	return desired if game.world.can_travel(position,position+desired.normalized()*.6) else Vector3.ZERO

func recover_route(direction: Vector3) -> void:
	blocked_for = 0
	repath = 0
	if direction.length()<.01:
		return
	var side = direction.normalized().cross(Vector3.UP)
	var parity = 1.0 if game.enemies.find(self)%2==0 else -1.0
	for sign_value in [parity,-parity]:
		var point = position+side*sign_value*1.1
		var crowded = game.enemies.any(func(e):return e!=self and e.alive and e.position.distance_to(point)<.9)
		if not crowded and game.world.can_travel(position,point):
			detour = point
			detour_timer = .65
			return
	# Blocked patrol goals are skipped, never traversed through a wall.
	if mode in ["patrol","return"]:
		patrol_index = (patrol_index+1)%4
		target = home+[Vector3(2.5,0,0),Vector3(0,0,2.5),Vector3(-2.5,0,0),Vector3(0,0,-2.5)][patrol_index]
	think = 0

func show_body() -> void:
	velocity = Vector3.ZERO
	label.visible = false
	warning.visible = false
	model.rotation.x = -PI/2
	model.position.y = .22
	model.position.z = .4


func attack(player: Explorer) -> void:
	cooldown = config.interval
	if kind == "runner":
		if position.distance_to(player.position)<=float(config.range)+0.2 and game.visible_between(position,player.position,[get_rid(),player.get_rid()]):
			player.take_damage(config.damage)
	else:
		var from = position + Vector3(0, 1.15, 0)
		var direction = (attack_target + Vector3(0, 1.0, 0) - from).normalized()
		# Visible warning and deterministic mild angular variation.
		direction = direction.rotated(Vector3.UP, sin(game.raid.time * 3) * 0.04)
		var endpoint = from + direction * float(config.range)
		var query = PhysicsRayQueryParameters3D.create(from, endpoint, 1 | 2 | 4, [get_rid()])
		var hit = get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty():
			endpoint = hit.position
			if hit.collider == player:
				player.take_damage(config.damage)
		game.effects.beam(from, endpoint, true)
		game.sound.play("shot")

func noise(p: Vector3, radius: float) -> void:
	if not alive or mode == "chase" or position.distance_to(p) > radius:
		return
	mode = "investigate"
	target = p
	last_seen = p
	search_timer = 8
	think = 0

func take_damage(amount: float) -> void:
	if not alive:
		return
	health = maxf(0, health - amount*float(config.get("armor",1.0)))
	hit_reaction = .22
	game.effects.burst(position+Vector3(0,1.1,0),(position-game.player.position).normalized(),Color("8f473b"),7)
	game.sound.play("hit")
	label.text = "%s %d/%d" % [config.name,roundi(health),config.health]
	noise(game.player.position, 100)
	if health <= 0:
		alive = false
		collision_layer = 0
		show_body()
		if kind == "sentinel":
			game.raid.kills += 1
		var loot = {"ammo9" if kind == "runner" else "ammo556":12,"scrap":1}
		if kind=="warden":
			loot = {"warden_badge":1,"ammo20":12,"medkit":1,"circuit":2}
		game.world.add_container(Vector2(position.x,position.z),loot,"Mochila del " + config.name.to_lower(),"","boss" if kind=="warden" else "supplies")
		game.notify("Enemigo derrotado · puedes saquear su mochila")
		game.checkpoint()

func snapshot() -> Dictionary:
	return {"patrol_index":patrol_index,"kind": kind, "p": [position.x, position.z], "home": [home.x, home.z], "health": health, "mode": mode, "last": [last_seen.x, last_seen.z], "target": [target.x, target.z], "seen_timer": seen_timer, "search_timer": search_timer, "cooldown": cooldown,"windup":windup,"attack_target":[attack_target.x,attack_target.z]}
