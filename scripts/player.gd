class_name Explorer
extends CharacterBody3D
signal damaged
signal died
var raid: Dictionary
var game: Node3D
var model: Node3D
var cooldown = 0.0
var recoil = 0.0
var aim = Vector2(0, -1)
var heal_timer = 0.0
var reload_timer = 0.0
var heal_item = ""
var alive = true
var crouched = false
var exposed = 0.0
var footstep_timer = 0.0
var stamina = 100.0
var sprint_requested = false
var sprinting = false
var exhausted = false
var recovery_delay = 0.0
var dodge_timer = 0.0
var dodge_cooldown = 0.0
var dodge_direction = Vector2(0,-1)
var stride = 0.0
var spawn_checked = false
var hit_reaction = 0.0

func configure(host: Node3D, state: Dictionary) -> void:
	game = host
	raid = state
	collision_layer = 2
	collision_mask = 1 | 4
	var shape = CollisionShape3D.new()
	var capsule = CapsuleShape3D.new()
	capsule.radius = 0.42
	capsule.height = 1.5
	shape.shape = capsule
	shape.position.y = 0.75
	add_child(shape)
	model = Art.animal(self, Color("718b75"), true)
	update_weapon_model()
	position = Vector3(raid.position[0], 0, raid.position[1])
	heal_timer = raid.get("heal", 0)
	reload_timer = raid.get("reload", 0)
	heal_item = raid.get("heal_item", "")
	aim = Vector2(raid.aim[0], raid.aim[1])
	crouched = raid.get("crouched",false)
	exposed = raid.get("exposed",0.0)
	stamina = clampf(raid.get("stamina",100.0),0,100)
	exhausted = raid.get("exhausted",false)
	recovery_delay = raid.get("recovery_delay",0.0)
	dodge_timer = raid.get("dodge_timer",0.0)
	dodge_cooldown = raid.get("dodge_cooldown",0.0)
	var saved_direction = raid.get("dodge_direction",[aim.x,aim.y])
	dodge_direction = Vector2(saved_direction[0],saved_direction[1]).normalized()

func weapon() -> Dictionary:
	return Catalog.weapons[raid.equipment.weapon]

func capacity() -> int:
	return 16 if raid.equipment.has("pack") else 12

func _physics_process(delta: float) -> void:
	if not alive or game.mode != "raid" or game.paused:
		return
	if not spawn_checked:
		position = game.world.safe_spawn(position)
		spawn_checked = true
	hit_reaction = maxf(0,hit_reaction-delta)
	cooldown = maxf(0, cooldown - delta)
	exposed = maxf(0,exposed-delta)
	footstep_timer -= delta
	recoil = move_toward(recoil, 0, delta * 3)
	model.position.z = recoil * 0.25
	var move: Vector2 = game.controls.movement()
	var aiming = game.controls.aim_vector.length()>0.05 or game.controls.mouse_fire
	dodge_cooldown = maxf(0,dodge_cooldown-delta)
	recovery_delay = maxf(0,recovery_delay-delta)
	if exhausted and stamina>=25:
		exhausted = false
	sprinting = (sprint_requested or Input.is_physical_key_pressed(KEY_SHIFT)) and move.length()>0.2 and not crouched and not aiming and heal_timer<=0 and reload_timer<=0 and dodge_timer<=0 and not exhausted and stamina>0
	if sprinting:
		stamina = maxf(0,stamina-delta*20)
		recovery_delay = 0.8
		if stamina==0:
			exhausted = true
	elif recovery_delay<=0 and dodge_timer<=0:
		stamina = minf(100,stamina+delta*22)
	if dodge_timer>0:
		velocity = Vector3(dodge_direction.x,0,dodge_direction.y)*11
		dodge_timer = maxf(0,dodge_timer-delta)
	else:
		var speed = 2.1 if crouched else (2.8 if heal_timer>0 else (6.7 if sprinting else 4.5))
		var desired_velocity = Vector3(move.x,0,move.y)*speed
		velocity = velocity.move_toward(desired_velocity,delta*(34 if move.length()<0.05 else 26))
	move_and_slide()
	stride += velocity.length()*delta*2.6
	Art.animate(model,stride,velocity.length(),delta,crouched,dodge_timer>0,model.basis.inverse()*velocity,"reload" if reload_timer>0 else ("heal" if heal_timer>0 else "idle"),hit_reaction)
	if velocity.length()>0.7 and footstep_timer<=0:
		footstep_timer = 0.32 if sprinting else (0.8 if crouched else 0.55)
		game.sound.play("step",.25 if crouched else (.7 if sprinting else .45),randf_range(.9,1.1))
		game.make_noise(position,1.5 if crouched else (9.0 if sprinting else 4.5))
	var firing: bool = game.controls.aim_vector.length() > 0.05
	if firing:
		var desired: Vector2 = game.controls.aim_vector.normalized()
		var angle = lerp_angle(aim.angle(),desired.angle(),1-exp(-delta*18*float(game.progression.profile.settings.sensitivity)))
		aim = Vector2.from_angle(angle)
	elif game.controls.mouse_fire:
		var p: Vector3 = game.mouse_world()
		var direction = Vector2(p.x - position.x, p.z - position.z)
		if direction.length() > 0.1:
			aim = direction.normalized()
		firing = true
	elif move.length()>0.15 and dodge_timer<=0:
		# Face travel without fighting the right stick's independent strafe aim.
		aim = Vector2.from_angle(lerp_angle(aim.angle(),move.angle(),1-exp(-delta*15)))
	if game.progression.profile.settings.assist and firing:
		aim = assisted(aim)
	model.rotation.y = lerp_angle(model.rotation.y,atan2(-aim.x,-aim.y),1-exp(-delta*22))
	if reload_timer > 0:
		reload_timer = maxf(0, reload_timer - delta)
		if reload_timer == 0:
			var w = weapon()
			var needed = mini(int(w.capacity) - int(raid.loaded), int(raid.bag.get(w.ammo, 0)))
			Inventory.remove(raid.bag, w.ammo, needed)
			raid.loaded += needed
			game.checkpoint()
	if heal_timer > 0:
		heal_timer = maxf(0, heal_timer - delta)
		if heal_timer == 0:
			raid.health = minf(100, raid.health + (60 if heal_item == "medkit" else 25))
			heal_item = ""
			game.sound.play("heal")
			game.checkpoint()
	if firing:
		shoot()

func assisted(direction: Vector2) -> Vector2:
	var best = 0.976
	var target = direction
	for enemy in game.enemies:
		if not enemy.alive:
			continue
		var diff: Vector3 = enemy.position - position
		var dist = Vector2(diff.x, diff.z).length()
		if dist > weapon().range or dist < 0.1:
			continue
		var candidate = Vector2(diff.x, diff.z).normalized()
		var dot = direction.dot(candidate)
		if dot > best and game.visible_between(position, enemy.position, [get_rid(), enemy.get_rid()]):
			best = dot
			target = candidate
	return direction.lerp(target, 0.32).normalized()

func shoot() -> void:
	if cooldown > 0 or reload_timer > 0 or heal_timer > 0 or dodge_timer > 0:
		return
	if raid.loaded <= 0:
		reload_weapon()
		return
	var w = weapon()
	raid.loaded -= 1
	exposed = 4.0
	cooldown = w.interval
	recoil = 0.7 if raid.equipment.weapon == "rifle" else 1.0
	var spread: float = w.spread * (0.7 if game.progression.profile.workshop else 1.0)
	var origin = position + Vector3(0, 1.15, 0)
	var pellets = int(w.get("pellets",1))
	for i in pellets:
		var deviation = lerpf(-spread,spread,float(i)/float(pellets-1)) if pellets>1 else randf_range(-spread,spread)
		var direction = aim.rotated(deviation)
		var endpoint = origin+Vector3(direction.x,0,direction.y)*float(w.range)
		var query = PhysicsRayQueryParameters3D.create(origin,endpoint,1|4,[get_rid()])
		var hit = get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty():
			endpoint = hit.position
			if hit.collider.has_method("take_damage"):
				hit.collider.take_damage(w.damage)
			else:
				game.effects.burst(hit.position,hit.normal,Color("ba9b78"),3)
		game.effects.beam(origin+Vector3(direction.x,0,direction.y)*.7,endpoint)
	game.effects.burst(origin+Vector3(aim.x,0,aim.y)*0.8,Vector3(aim.x,0,aim.y),Color("ffbd65"),6)
	game.camera_impulse(0.09 if raid.equipment.weapon=="rifle" else 0.16)
	game.sound.play("shotgun" if raid.equipment.weapon=="shotgun" else ("rifle" if raid.equipment.weapon=="rifle" else "shot"))
	game.make_noise(position, 18 if raid.equipment.weapon == "shotgun" else (16 if raid.equipment.weapon == "rifle" else 12))

func reload_weapon() -> void:
	var w = weapon()
	if reload_timer > 0 or heal_timer > 0 or raid.loaded >= w.capacity:
		return
	if raid.bag.get(w.ammo, 0) <= 0:
		game.notify("No queda munición de reserva")
		return
	reload_timer = w.reload
	game.sound.play("reload")
	game.checkpoint()

func heal(preferred: String = "") -> void:
	if heal_timer > 0 or reload_timer > 0 or raid.health >= 100:
		return
	var id = preferred
	if id.is_empty():
		id = "bandage" if raid.bag.has("bandage") else "medkit"
	if id not in ["bandage","medkit"]:
		return
	if not Inventory.remove(raid.bag, id, 1):
		game.notify("No tienes curación")
		return
	heal_item = id
	heal_timer = 3.5 if id == "medkit" else 2.0
	game.checkpoint()

func take_damage(amount: float) -> void:
	if not alive or game.paused:
		return
	hit_reaction = .22
	var armor = 0.75 if raid.equipment.has("armor") else 1.0
	raid.health = maxf(0, raid.health - amount * armor)
	heal_timer = 0
	heal_item = ""
	game.sound.play("hit")
	damaged.emit()
	if raid.health <= 0:
		alive = false
		died.emit()

func snapshot() -> void:
	raid.position = [position.x, position.z]
	raid.aim = [aim.x, aim.y]
	raid.reload = reload_timer
	raid.heal = heal_timer
	raid.heal_item = heal_item
	raid.crouched = crouched
	raid.exposed = exposed
	raid.stamina = stamina
	raid.exhausted = exhausted
	raid.recovery_delay = recovery_delay
	raid.dodge_timer = dodge_timer
	raid.dodge_cooldown = dodge_cooldown
	raid.dodge_direction = [dodge_direction.x,dodge_direction.y]

func toggle_crouch() -> void:
	if game.paused or not alive:
		return
	crouched = not crouched
	if crouched:
		sprint_requested = false
	game.notify("Sigilo · menos visible, pasos suaves" if crouched else "En marcha · velocidad normal")
	game.checkpoint()

func detection_scale() -> float:
	return 0.55 if crouched and exposed <= 0 else 1.0

func update_weapon_model() -> void:
	var mesh = model.get_node("Weapon")
	mesh.scale = Vector3(1.8,1.3,.85) if raid.equipment.weapon=="shotgun" else (Vector3(1,1,1.2) if raid.equipment.weapon=="rifle" else Vector3.ONE)

func toggle_sprint() -> void:
	if game.paused or not alive:
		return
	sprint_requested = not sprint_requested
	if sprint_requested:
		crouched = false

func dodge() -> bool:
	if game.paused or not alive or dodge_cooldown>0 or stamina<25 or heal_timer>0 or reload_timer>0:
		return false
	var move: Vector2 = game.controls.movement()
	dodge_direction = move.normalized() if move.length()>0.1 else aim.normalized()
	dodge_timer = 0.22
	dodge_cooldown = 1.1
	stamina -= 25
	recovery_delay = 0.8
	crouched = false
	game.sound.play("dodge",.55)
	game.make_noise(position,6)
	game.effects.burst(position+Vector3(0,.12,0),-Vector3(dodge_direction.x,0,dodge_direction.y),Color("86918d"),5)
	game.checkpoint()
	return true
