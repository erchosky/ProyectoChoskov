extends SceneTree
var checks = 0
var failures = 0
func check(value: bool, message: String) -> void:
	checks += 1
	if value:
		print("PASS: ",message)
	else:
		failures += 1
		push_error("FAIL: "+message)
func _initialize() -> void:
	call_deferred("run")
func frames() -> void:
	for i in 3:
		await physics_frame
		await process_frame
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game);await frames()
	game.ignore_focus=true
	game.store.path="user://navigation-scene-test.json"
	for suffix in ["",".bak",".tmp"]:
		DirAccess.remove_absolute(game.store.path+suffix)
	game.progression=Progression.new(game.store)
	game.start_raid();game.set_process(false);game.player.set_physics_process(false)
	for enemy in game.enemies:
		enemy.set_physics_process(false)
	await frames()
	var world=game.world
	var blocked=Vector3(-19,0,5)
	var repaired=world.safe_spawn(blocked)
	check(repaired.distance_to(blocked)>.5 and repaired.distance_to(blocked)<4 and not world.occupied(repaired),"old spawn inside new cover is relocated to nearby free space")
	check(world.safe_spawn(Vector3(-24,0,22))==Vector3(-24,0,22),"valid saved position remains unchanged")
	var routes = [[Vector3(14,0,-22),Vector3(14,0,-10)], [Vector3(-9,0,10),Vector3(-3,0,14)], [Vector3(-22,0,5),Vector3(-16,0,5)]]
	for route in routes:
		var points=world.path(route[0],route[1])
		check(points.size()>1,"route reaches the opposite side of an obstacle")
		var clear=true
		for i in range(1,points.size()):
			clear = clear and world.can_travel(Vector3(points[i-1].x,0,points[i-1].y),Vector3(points[i].x,0,points[i].y))
		check(clear,"every smoothed segment has body clearance")
	check(world.path(Vector3(100,0,100),Vector3.ZERO).is_empty(),"out of map paths fail safely")
	check(not world.can_travel(Vector3(14,0,-22),Vector3(14,0,-16)),"swept body cannot cross a warehouse wall")
	var actor=game.enemies[0]
	for enemy in game.enemies:
		enemy.collision_layer=0
	actor.collision_layer=4
	actor.config.sight=0;actor.config.range=0;actor.config.speed=4
	actor.position=Vector3(-9,0,10);actor.target=Vector3(-3,0,14)
	actor.mode="investigate";actor.search_timer=1000;actor.path.clear();actor.think=0
	await frames()
	var travelled=0.0
	for i in 240:
		await physics_frame
		await process_frame
		var before=actor.position
		actor._physics_process(1.0/60)
		travelled += actor.position.distance_to(before)
	check(actor.position.distance_to(actor.target)<.8,"enemy physically walks around cover and reaches its destination")
	check(travelled>7,"obstacle navigation uses a real detour")
	var other=game.enemies[1]
	other.collision_layer=4
	for e in [actor,other]:
		e.config.sight=0;e.config.range=0;e.config.speed=4
		e.mode="investigate";e.search_timer=1000;e.think=0;e.path.clear();e.velocity=Vector3.ZERO
	actor.position=Vector3(-8,0,24);actor.target=Vector3(0,0,24)
	other.position=Vector3(0,0,24);other.target=Vector3(-8,0,24)
	await frames()
	for i in 360:
		await physics_frame
		await process_frame
		actor._physics_process(1.0/60)
		other._physics_process(1.0/60)
	check(actor.position.distance_to(actor.target)<1 and other.position.distance_to(other.target)<1,"opposing enemies pass each other without remaining stuck")
	game.set_paused(true)
	var before=actor.position
	var timer=actor.repath
	actor._physics_process(1)
	check(actor.position==before and actor.repath==timer,"pause freezes navigation and its timers")
	game.resume()
	actor.health=1;actor.take_damage(10)
	check(not actor.alive and actor.visible and actor.collision_layer==0,"dead enemy remains as a visible nonblocking body")
	var drops=game.world.containers.size()
	actor.take_damage(10)
	check(game.world.containers.size()==drops,"body cannot duplicate kill loot")
	game.queue_free();await frames();await create_timer(.2).timeout
	for suffix in ["",".bak",".tmp"]:
		DirAccess.remove_absolute("user://navigation-scene-test.json"+suffix)
	print("NAVIGATION_RESULT ",checks," checks, ",failures," failures")
	quit(1 if failures>0 else 0)
