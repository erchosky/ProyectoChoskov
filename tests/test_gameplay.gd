extends SceneTree
var checks := 0
var failures := 0
var game: Node3D
func check(condition: bool, name: String) -> void:
	checks += 1
	if condition:
		print("PASS: ",name)
	else:
		failures += 1
		push_error("FAIL: "+name)
func _initialize() -> void:
	call_deferred("run")
func frames(n: int = 2) -> void:
	for i in n:
		await physics_frame
		await process_frame
func touch(index: int, position_value: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index=index;event.position=position_value;event.pressed=pressed
	root.push_input(event,true)
func drag(index: int, position_value: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index=index;event.position=position_value
	root.push_input(event,true)
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frames()
	game.ignore_focus=true
	game.store.path="user://gameplay-test.json"
	for suffix in ["",".bak",".tmp"]:
		DirAccess.remove_absolute(game.store.path+suffix)
	game.progression=Progression.new(game.store)
	game.start_raid()
	await frames()
	check(game.mode=="raid" and game.enemies.size()==8,"raid spawns player and two enemy types")
	# Real Godot input events with independent pointer IDs.
	var origin: Vector3=game.player.position
	var loaded: int=game.raid.loaded
	var centers: Dictionary=game.controls.centers()
	touch(2,centers.move,true)
	drag(2,centers.move+Vector2(52,0))
	touch(7,centers.aim,true)
	drag(7,centers.aim+Vector2(0,-55))
	await frames(12)
	check(game.player.position.x>origin.x and game.raid.loaded<loaded,"simultaneous movement and aimed shooting")
	check(game.controls.fingers.size()==2,"independent finger ownership")
	var reload_button: Button = game.ui.interact_button.get_parent().get_child(0)
	var reload_point: Vector2 = reload_button.global_position + reload_button.size/2
	touch(19,reload_point,true)
	touch(19,reload_point,false)
	check(game.player.reload_timer>0 and game.controls.fingers.size()==2,"third action reload leaves both fingers active")
	touch(7,centers.aim,false)
	check(game.controls.aim_vector==Vector2.ZERO and game.controls.move_vector.length()>0,"releasing aim preserves movement finger")
	touch(2,centers.move,false)
	check(game.controls.fingers.is_empty(),"release clears both controls")
	touch(11,centers.aim+Vector2(4,0),true)
	check(game.controls.aim_vector==Vector2.ZERO,"aim deadzone avoids accidental fire")
	touch(11,centers.aim,false)
	var ammo_before: int=game.raid.bag.ammo9+game.raid.loaded
	game.player._physics_process(2)
	check(game.player.reload_timer==0 and game.raid.loaded==12,"reload duration completes magazine")
	check(game.raid.bag.ammo9+game.raid.loaded==ammo_before,"reload conserves ammunition")
	# Controlled test actors: wall blocks detection, aim assistance and bullets.
	game.player.position=Vector3(14,0,-22)
	for enemy in game.enemies:
		enemy.set_physics_process(false)
	var enemy: Raider=game.enemies[4]
	enemy.position=Vector3(14,0,-16)
	enemy.health=90
	await frames()
	check(not game.visible_between(game.player.position,enemy.position,[game.player.get_rid(),enemy.get_rid()]),"warehouse wall blocks line of sight")
	game.player.aim=Vector2(0,1)
	game.player.cooldown=0
	game.player.shoot()
	check(enemy.health==90,"wall blocks weapon damage")
	enemy.think=0;enemy.mode="patrol"
	enemy._physics_process(.4)
	check(enemy.mode!="chase","enemy cannot see through wall")
	var input_aim:=Vector2(.12,1).normalized()
	check(game.player.assisted(input_aim).is_equal_approx(input_aim),"assist respects occluding wall")
	game.player.position=Vector3(14,0,-14)
	enemy.position=Vector3(14,0,-10)
	await frames()
	check(game.visible_between(game.player.position,enemy.position,[game.player.get_rid(),enemy.get_rid()]),"clear line of sight visible")
	game.player.aim=Vector2(0,1);game.player.cooldown=0
	game.player.shoot()
	check(enemy.health<90,"unobstructed shot damages enemy")
	enemy.think=0;enemy._physics_process(.4)
	check(enemy.mode=="chase","enemy detects visible player")
	game.player.position=Vector3(14,0,-23)
	await frames()
	enemy.windup=0;enemy.seen_timer=3;enemy.think=0;enemy._physics_process(.4)
	check(enemy.mode=="search","enemy loses sight and searches last position")
	enemy.search_timer=.1;enemy.think=0;enemy._physics_process(.4)
	check(enemy.mode=="return","search expires and returns to patrol")
	enemy.mode="patrol";enemy.noise(game.player.position,20)
	check(enemy.mode=="investigate","noise triggers investigation without permanent sight")
	game.player.position=Vector3(14,0,-14)
	enemy.position=Vector3(14,0,-10)
	await frames()
	var drops_before: int=game.world.containers.size()
	for i in 3:
		game.player.aim=Vector2(0,1);game.player.cooldown=0;game.player.shoot()
	check(not enemy.alive and game.raid.kills==1 and game.world.containers.size()==drops_before+1,"lethal shots drop loot and count a sentinel")
	enemy.take_damage(100)
	check(game.raid.kills==1 and game.world.containers.size()==drops_before+1,"enemy death cannot duplicate loot or kills")
	# Loot UI path, including action pause.
	game.player.position=Vector3(-21,0,19)
	await frames()
	game.interact()
	check(game.paused and is_instance_valid(game.ui.panel),"interact opens loot panel and pauses")
	var container: Dictionary=game.world.containers[0]
	await frames()
	var grid: GridContainer
	for child in game.ui.content.get_children():
		if child is GridContainer:
			grid = child
	var loot_button: Button
	for item in grid.get_children():
		if item.text.contains(Catalog.items.scrap.name):
			loot_button = item
	var loot_point: Vector2 = loot_button.global_position + loot_button.size/2
	touch(4,loot_point,true)
	touch(4,loot_point,false)
	var taken: int = game.raid.bag.get("scrap",0)
	game.checkpoint()
	check(taken==3 and game.raid.bag.scrap==3 and not container.items.has("scrap"),"loot transfer removes container items")
	game.resume()
	check(not game.paused and game.controls.active,"closing loot resumes controls")
	# Pause/focus clears input; no elapsed raid time or incoming damage.
	touch(2,game.controls.centers().move,true)
	drag(2,game.controls.centers().move+Vector2(50,0))
	game.ignore_focus=false
	game._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(game.paused and game.controls.fingers.is_empty(),"focus loss pauses and clears every finger")
	var hp: float=game.raid.health
	var clock: float=game.raid.time
	game.player.take_damage(15)
	game._process(2)
	check(game.raid.health==hp and game.raid.time==clock,"paused raid cannot advance or damage player")
	game.ignore_focus=true
	game.resume()
	game.raid.health=55
	game.player.heal()
	check(game.player.heal_timer>0 and game.raid.bag.bandage==1,"healing consumes one item at start")
	game.player._physics_process(2.1)
	check(game.raid.health==80,"timed healing restores correct amount")
	# Extraction cancellations and end-to-end reward.
	game.player.position=Vector3(-26,0,19)
	await frames()
	game.interact()
	check(game.extract_timer==6,"valid zone activates extraction")
	game.player.position=Vector3(-20,0,22)
	game._process(.1)
	check(game.extract_timer==0,"leaving zone cancels extraction")
	game.player.position=Vector3(-26,0,19)
	await frames()
	game.interact();game.player.take_damage(1)
	check(game.extract_timer==0,"damage cancels extraction")
	game.interact()
	game._process(6.1)
	check(game.mode=="result" and game.progression.profile.active.is_empty(),"countdown completes extraction transaction")
	check(game.progression.profile.prepared.scrap==3,"extraction keeps loot")
	var credits: int=game.progression.profile.credits
	game.finish_raid(true,"")
	check(game.progression.profile.credits==credits,"repeated result signal grants nothing")
	game.show_shelter();game.start_raid()
	await frames()
	check(game.mode=="raid" and game.raid.bag.scrap==3,"next raid carries persisted prepared bag")
	game.checkpoint()
	var snapshot: Dictionary=game.store.load_profile()
	game.pause_menu();game.show_shelter();game.start_raid()
	await frames()
	check(game.paused and game.raid.id==snapshot.active.id,"interrupted raid reopens paused with same identity")
	check(game.world.containers.size()==snapshot.active.containers.size(),"resume restores containers without regenerating drops")
	game.resume()
	var stash_before: Dictionary=game.progression.profile.stash.duplicate(true)
	game.player.take_damage(1000)
	check(game.mode=="result" and game.progression.profile.prepared.is_empty() and game.progression.profile.equipment.is_empty(),"lethal damage loses carried equipment")
	check(game.progression.profile.stash==stash_before,"death leaves storage intact")
	game.show_shelter();game.start_raid()
	await frames()
	check(game.mode=="raid" and game.player.alive,"another raid works after death")
	game.queue_free()
	await frames()
	# Allow the asynchronous audio server to retire stopped playback before quit.
	await create_timer(0.2).timeout
	for suffix in ["",".bak",".tmp"]:
		DirAccess.remove_absolute("user://gameplay-test.json"+suffix)
	print("GAMEPLAY_RESULT ",checks," checks, ",failures," failures")
	quit(1 if failures>0 else 0)
