extends SceneTree
var checks = 0
var failures = 0
func check(value: bool, name: String) -> void:
	checks += 1
	if value:
		print("PASS: ",name)
	else:
		failures += 1
		push_error("FAIL: " + name)
func _initialize() -> void:
	call_deferred("run")
func frames() -> void:
	for i in 3:
		await physics_frame
		await process_frame
func run() -> void:
	var store = SaveStore.new()
	store.path = "user://upgrade-test.json"
	for suffix in ["",".bak",".tmp"]:
		DirAccess.remove_absolute(store.path+suffix)
	var prog = Progression.new(store)
	check(Inventory.add({},"ammo9",-10,12)==0,"negative quantity cannot create inventory")
	check(Inventory.add({},"unknown",1,12)==0,"unknown item safely rejected")
	var before = prog.profile.duplicate(true)
	check(not prog.purchase("ammo9",-10) and before==prog.profile,"negative purchase cannot generate credits")
	check(not prog.purchase("unknown",1),"unknown purchase safely rejected")
	prog.prepare()
	var raid = prog.begin(2026)
	before = prog.profile.duplicate(true)
	check(not prog.equip("rifle"),"suspended raid blocks equipment changes")
	check(not prog.purchase("bandage",1) and not prog.sell("rifle"),"suspended raid blocks buying and selling")
	check(prog.move_supply("ammo9",false,1)==0 and not prog.store_bag(),"suspended raid blocks inventory transfer")
	prog.prepare()
	check(prog.profile==before,"suspended preparation cannot duplicate or overwrite gear")
	check(prog.discover("first_light") and not prog.discover("first_light"),"journal discoveries stored once")
	check(not prog.discover("invented"),"journal rejects nonexistent page")
	prog.finish(false)
	check(prog.profile.journal.has("first_light"),"death preserves discovered lore")
	check(prog.track("blackbox") and prog.tracked().id=="blackbox","tracking selects a valid mission")
	check(not prog.track("unknown"),"tracking rejects nonexistent mission")
	check(prog.objective({"bag":{"recorder":1}}).contains("en riesgo"),"objective distinguishes carried loot from safe materials")
	# Inject an unwritable destination; transactions must roll back all rewards/items.
	before = prog.profile.duplicate(true)
	store.path = "user://missing-parent/upgrade.json"
	check(not prog.purchase("bandage",1) and prog.profile==before,"failed purchase rolls back credits and stock")
	check(not prog.equip("rifle") and prog.profile==before,"failed equipment save rolls back swap")
	check(not prog.discover("sealed_orders") and prog.profile==before,"failed lore save does not lose discovery opportunity")
	store.path = "user://upgrade-test.json"
	var pending = prog.begin(777)
	before = prog.profile.duplicate(true)
	store.path = "user://missing-parent/upgrade.json"
	check(not prog.finish(true) and prog.profile==before,"failed result save keeps active raid and rolls back reward")
	store.path = "user://upgrade-test.json"
	# A genuine v1 envelope with a live raid migrates without losing inventory.
	var legacy = SaveStore.fresh()
	legacy.version = 1
	legacy.erase("journal");legacy.erase("tracked_mission")
	legacy.active = raid.duplicate(true)
	legacy.active.bag.recorder = 1
	var payload = JSON.stringify(legacy)
	var file = FileAccess.open(store.path,FileAccess.WRITE)
	file.store_string(JSON.stringify({"payload":payload,"checksum":payload.sha256_text()}));file.close()
	var migrated = store.load_profile()
	check(migrated.version==SaveStore.VERSION and migrated.journal.is_empty(),"v1 save migrates with journal defaults")
	check(migrated.active.id==raid.id and migrated.active.bag.recorder==1,"migration preserves active raid and carried loot")
	check(store.write(migrated) and store.read_file(store.path).version==SaveStore.VERSION,"migrated profile persists in current format")
	# Actual scene systems and layout, isolated from player save.
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frames()
	game.ignore_focus=true
	game.store.path="user://upgrade-scene-test.json"
	for suffix in ["",".bak",".tmp"]:
		DirAccess.remove_absolute(game.store.path+suffix)
	game.progression=Progression.new(game.store)
	game.start_raid()
	game.set_process(false)
	game.player.set_physics_process(false)
	for enemy in game.enemies:
		enemy.set_physics_process(false)
	await frames()
	game.controls.radius=110.5
	var press = InputEventScreenTouch.new()
	press.index=41;press.pressed=true
	press.position=game.ui.stealth_button.global_position+Vector2(2,15)
	root.push_input(press,true)
	check(game.controls.fingers.is_empty(),"large joystick cannot steal a touch from stealth button")
	press.pressed=false;root.push_input(press,true)
	check(game.player.crouched,"touch stealth toggle works at button edge")
	game.player.toggle_crouch()
	check(game.world.notes.size()==Catalog.notes.size(),"all story props available in scene")
	check(Catalog.notes.all(func(note): return not game.world.nav.is_point_solid(Vector2i(note.p[0],note.p[1]))),"story props stay clear of generated obstacles")
	check(game.world.containers[10].items.get("battery",0)>0,"northern supply crate guarantees radio battery")
	game.player.toggle_crouch()
	check(game.player.crouched and game.player.detection_scale()==0.55,"crouching reduces visibility")
	game.player.cooldown=0;game.player.shoot()
	check(game.player.detection_scale()==1.0,"shooting temporarily reveals crouched player")
	game.player._physics_process(4.1)
	check(game.player.detection_scale()==0.55,"visibility returns after exposure ends")
	var saved_player = game.raid.duplicate(true)
	game.checkpoint()
	check(game.store.load_profile().active.crouched,"crouched stance persists in active save")
	game.player.position=Vector3(-23,0,16)
	await frames()
	game.interact()
	check(game.paused and game.progression.profile.journal.has("first_light"),"interacting reads and persists lore while pausing action")
	game.resume()
	game.player.position=Vector3(27,0,-24)
	game.raid.bag.erase("battery")
	await frames()
	game.interact()
	check(game.extract_timer==0 and not game.raid.radio_powered,"unpowered radio refuses extraction without battery")
	game.raid.bag.battery=2
	game.interact()
	check(game.extract_timer==6 and game.raid.bag.battery==1 and game.raid.radio_powered,"radio consumes exactly one battery and begins extraction")
	game.cancel_extraction();game.interact()
	check(game.raid.bag.battery==1 and game.extract_timer==6,"cancelled radio extraction does not consume another battery")
	game.cancel_extraction();game.checkpoint()
	check(game.store.load_profile().active.radio_powered,"radio power survives interrupted save")
	# Telegraph lets player evade a runner; test range and pause during windup.
	var enemy = game.enemies[0]
	enemy.position=Vector3(-25,0,22)
	game.player.position=Vector3(-24,0,22)
	enemy.mode="patrol";enemy.cooldown=0;enemy.think=0;enemy.windup=0
	await frames()
	var hp = game.raid.health
	enemy._physics_process(0.1)
	check(enemy.windup>0 and game.raid.health==hp,"runner warns before dealing damage")
	game.paused=true
	var windup = enemy.windup
	enemy._physics_process(1)
	check(enemy.windup==windup,"pause freezes enemy attack warning")
	game.paused=false
	game.player.position=Vector3(-20,0,22)
	enemy._physics_process(1)
	check(game.raid.health==hp,"leaving melee range evades warned attack")
	enemy.position=Vector3(-25,0,22);game.player.position=Vector3(-24,0,22)
	enemy.cooldown=0;enemy.think=0;enemy._physics_process(.1)
	var snapshot = enemy.snapshot()
	check(snapshot.windup>0 and snapshot.attack_target.size()==2,"attack warning and locked target saved")
	enemy._physics_process(1)
	check(game.raid.health<hp,"remaining in melee range resolves warned attack")
	game.open_map();await frames()
	check(game.paused and game.ui.content.find_children("*","Minimap",true,false).size()==1,"route map pauses action and presents minimap")
	var route = game.ui.content.find_children("*","Minimap",true,false)[0]
	check(route.size.x>=360 and absf(route.size.x-route.size.y)<1,"route map retains readable square dimensions")
	game.resume();game.open_bag();await frames()
	game.ui.bag_item("ammo9");await frames()
	game.ui.bag_item("bandage");await frames()
	var detail_count = 0
	for node in game.ui.content.get_children():
		if node is VBoxContainer:
			detail_count+=1
	check(detail_count==1,"item selection replaces detail card without accumulating actions")
	game.queue_free();await frames()
	await create_timer(0.2).timeout
	for path in ["user://upgrade-test.json","user://upgrade-scene-test.json"]:
		for suffix in ["",".bak",".tmp"]:
			DirAccess.remove_absolute(path+suffix)
	print("UPGRADE_RESULT ",checks," checks, ",failures," failures")
	quit(1 if failures>0 else 0)
