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
func touch(index: int, point: Vector2, down: bool) -> void:
	var event = InputEventScreenTouch.new()
	event.index=index;event.position=point;event.pressed=down
	root.push_input(event,true)
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game);await frames()
	game.ignore_focus=true
	game.store.path="user://mobility-scene-test.json"
	for suffix in ["",".bak",".tmp"]:
		DirAccess.remove_absolute(game.store.path+suffix)
	game.progression=Progression.new(game.store)
	game.start_raid();game.set_process(false);game.player.set_physics_process(false)
	for enemy in game.enemies:
		enemy.set_physics_process(false)
	await frames()
	var player=game.player
	game.controls.move_vector=Vector2(1,0)
	player._physics_process(.05)
	check(player.velocity.x>0 and player.velocity.x<4.5,"movement accelerates without snapping to top speed")
	player._physics_process(.2)
	check(is_equal_approx(player.velocity.length(),4.5),"walking reaches defined speed")
	game.controls.move_vector=Vector2.ZERO
	player._physics_process(.2)
	check(player.velocity.length()<.01,"release brakes to a full stop without sustained drift")
	var p=player.position
	player._physics_process(.2)
	check(player.position.distance_to(p)<.01,"idle character remains stationary")
	game.controls.move_vector=Vector2(1,0);player.toggle_sprint();player._physics_process(.3)
	check(player.sprinting and player.velocity.length()>6 and player.stamina<100,"sprint increases speed and consumes resistance")
	game.controls.aim_vector=Vector2(0,-1);player._physics_process(.1)
	check(not player.sprinting and player.velocity.length()<=4.5,"aiming retains controlled strafe speed")
	game.controls.aim_vector=Vector2.ZERO
	player.stamina=1;player._physics_process(.1)
	check(player.exhausted and player.stamina==0,"exhaustion stops continuous unlimited sprint")
	player._physics_process(.1)
	check(not player.sprinting,"exhausted player cannot immediately sprint again")
	player.sprint_requested=false;game.controls.move_vector=Vector2.ZERO
	player._physics_process(2)
	check(player.stamina>25,"resistance recovers after active recovery delay")
	player._physics_process(.1)
	check(not player.exhausted,"recovery restores ability to sprint")
	player.stamina=100;player.dodge_cooldown=0;player.reload_timer=0;player.cooldown=0;player.aim=Vector2(0,-1)
	var loaded=game.raid.loaded
	check(player.dodge() and player.stamina==75 and player.dodge_timer>0,"dodge has a fixed resistance cost and duration")
	check(not player.dodge() and player.stamina==75,"cooldown prevents repeated dodge costs")
	player.shoot()
	check(game.raid.loaded==loaded,"dodge blocks firing during its movement burst")
	var health=game.raid.health
	player.take_damage(10)
	check(game.raid.health==health-10,"dodge does not grant hidden invulnerability")
	game.set_paused(true)
	var timer=player.dodge_timer
	player._physics_process(2)
	check(player.dodge_timer==timer and player.stamina==75,"pause freezes dodge and resistance")
	game.checkpoint();game.show_shelter();game.start_raid();await frames()
	player=game.player;player.set_physics_process(false);game.set_process(false)
	for enemy in game.enemies:
		enemy.set_physics_process(false)
	check(game.paused and player.stamina==75 and is_equal_approx(player.dodge_timer,timer),"unfinished dodge and resistance survive interrupted raid")
	game.resume();player.dodge_timer=0;player.dodge_cooldown=0;player.stamina=100
	player.position=Vector3(14,0,-18);player.velocity=Vector3.ZERO;player.aim=Vector2(0,-1)
	await frames()
	player.dodge()
	for i in 14:
		await physics_frame
		player._physics_process(1.0/60)
	check(player.position.z> -18.4,"dodge cannot tunnel through the warehouse wall")
	player.position=Vector3(-24,0,22);player.velocity=Vector3.ZERO;player.dodge_timer=0;player.dodge_cooldown=0;player.stamina=100
	await frames()
	var pads=game.controls.centers()
	touch(70,pads.move+Vector2(40,0),true);touch(71,pads.aim+Vector2(0,-40),true)
	var point=game.ui.dodge_button.global_position+game.ui.dodge_button.size/2
	touch(72,point,true);touch(72,point,false)
	check(player.dodge_timer>0 and game.controls.fingers.size()==2,"third finger dodge preserves movement and aiming fingers")
	touch(70,pads.move,false);touch(71,pads.aim,false)
	player.dodge_timer=0;player.sprint_requested=false;player.footstep_timer=0
	game.controls.move_vector=Vector2(1,0)
	var enemy=game.enemies[0];enemy.position=player.position+Vector3(7,0,0);enemy.mode="patrol"
	player._physics_process(.1)
	check(enemy.mode=="patrol","normal footsteps do not attract a distant patrol")
	player.toggle_sprint();player.footstep_timer=0;player._physics_process(.1)
	check(enemy.mode=="investigate","louder sprint footsteps attract the same patrol")
	check(player.model.get_node("LegLeft").rotation.x!=player.model.get_node("LegRight").rotation.x,"articulated legs move independently while travelling")
	check(Catalog.missions.all(func(m):return not m.get("aftermath","").is_empty()),"all contracts include persistent narrative consequences")
	game.queue_free();await frames();await create_timer(.2).timeout
	for suffix in ["",".bak",".tmp"]:
		DirAccess.remove_absolute("user://mobility-scene-test.json"+suffix)
	print("MOBILITY_RESULT ",checks," checks, ",failures," failures")
	quit(1 if failures>0 else 0)
