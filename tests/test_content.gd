extends SceneTree
var checks = 0
var failures = 0
func check(value: bool, name: String) -> void:
	checks += 1
	if value:
		print("PASS: ",name)
	else:
		failures += 1
		push_error("FAIL: "+name)
func _initialize() -> void:
	call_deferred("run")
func frames() -> void:
	for i in 3:
		await physics_frame
		await process_frame
func touch(index: int, point: Vector2, pressed: bool) -> void:
	var event=InputEventScreenTouch.new()
	event.index=index;event.position=point;event.pressed=pressed
	root.push_input(event,true)
func run() -> void:
	var store = SaveStore.new()
	store.path="user://content-core-test.json"
	for suffix in ["",".bak",".tmp"]:
		DirAccess.remove_absolute(store.path+suffix)
	var prog = Progression.new(store)
	check(Catalog.items.size()==21 and Catalog.weapons.size()==3,"expanded catalog contains 21 items and three weapons")
	check(Catalog.missions.size()==6 and Catalog.recipes.size()==5,"six contracts and five crafting recipes available")
	var before = prog.profile.duplicate(true)
	check(not prog.craft("unknown") and prog.profile==before,"unknown recipe cannot alter profile")
	check(not prog.craft("medkit") and prog.profile==before,"insufficient ingredients do not consume anything")
	prog.profile.stash.cloth=6
	check(prog.craft("bandages") and prog.profile.stash.cloth==4 and prog.profile.stash.bandage==6,"crafting consumes ingredients and creates exact output")
	prog.craft("bandages");prog.craft("bandages")
	var mission = Catalog.missions.filter(func(m): return m.id=="craftsman")[0]
	check(prog.profile.crafted==3 and prog.mission_ready(mission),"three batches unlock crafting contract")
	check(prog.claim(mission) and not prog.claim(mission),"crafting reward paid once")
	prog.profile.stash.scrap=2
	before = prog.profile.duplicate(true)
	store.path="user://missing-parent/content.json"
	check(not prog.craft("shells") and prog.profile==before,"failed craft save rolls back materials output and statistics")
	store.path="user://content-core-test.json"
	prog.profile.stash={"scrap":360}
	before=prog.profile.duplicate(true)
	check(not prog.craft("shells") and prog.profile==before,"full stash refuses crafting output without wasting materials")
	prog.profile=SaveStore.fresh()
	prog.begin(123)
	before=prog.profile.duplicate(true)
	check(not prog.craft("bandages") and prog.profile==before,"suspended raid blocks crafting")
	prog.profile=SaveStore.fresh();prog.profile.stash={"shotgun":1};prog.profile.credits=0
	var raid = prog.begin(345)
	check(raid.equipment.weapon=="shotgun" and raid.loaded==6,"shotgun-only recovery remains playable without credits")
	check(not prog.emergency(),"active shotgun raid cannot create a duplicate emergency weapon")
	# Migrate a real v2 payload with an unfinished raid and preserved radio state.
	var legacy = prog.profile.duplicate(true)
	legacy.version=2;legacy.erase("crafted")
	legacy.active.radio_powered=true
	var payload = JSON.stringify(legacy)
	var file = FileAccess.open(store.path,FileAccess.WRITE)
	file.store_string(JSON.stringify({"payload":payload,"checksum":payload.sha256_text()}));file.close()
	var migrated=store.load_profile()
	check(migrated.version==3 and migrated.crafted==0 and migrated.active.radio_powered,"v2 migration preserves raid and supplies crafting default")
	# Actual scene, isolated, with controlled actors and time.
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game);await frames()
	game.ignore_focus=true;game.store.path="user://content-scene-test.json"
	for suffix in ["",".bak",".tmp"]:
		DirAccess.remove_absolute(game.store.path+suffix)
	game.progression=Progression.new(game.store)
	game.start_raid();game.set_process(false);game.player.set_physics_process(false)
	for enemy in game.enemies:
		enemy.set_physics_process(false)
	await frames()
	check(game.raid.delivery=="waiting" and game.enemies.size()==8,"new raid starts without delivery or forced boss encounter")
	check(game.world.containers[2].items.get("outpost_key",0)==1,"forest station guarantees the reserve key")
	var cache = game.world.containers.filter(func(c): return c.get("kind")=="locked")[0]
	game.player.position=Vector3(-27,0,-23.5);await frames()
	game.interact()
	check(not game.paused and cache.locked_key=="outpost_key","locked reserve cannot be opened without key")
	Inventory.transfer(game.world.containers[2].items,game.raid.bag,"outpost_key",1,game.player.capacity())
	game.interact()
	check(game.paused and cache.locked_key.is_empty() and not game.raid.bag.has("outpost_key"),"opening reserve consumes exactly one key")
	check(cache.items.shotgun==1 and cache.items.cipher==1,"locked reserve contains weapon and story objective")
	Inventory.transfer(cache.items,game.raid.bag,"shotgun",1,game.player.capacity())
	Inventory.transfer(cache.items,game.raid.bag,"ammo20",18,game.player.capacity())
	game.equip_raid("shotgun")
	check(game.raid.equipment.weapon=="shotgun" and game.raid.loaded==0 and game.raid.bag.pistol==1,"equipping found shotgun returns prior weapon and magazine")
	game.resume();game.player.reload_weapon();game.player._physics_process(2.5)
	check(game.raid.loaded==6 and game.raid.bag.ammo20==12,"shotgun reload consumes six cartridges")
	var enemy = game.enemies[0]
	enemy.position=Vector3(-24,0,20);enemy.health=100
	game.player.position=Vector3(-24,0,22);game.player.aim=Vector2(0,-1);game.player.cooldown=0
	await frames()
	var loaded = game.raid.loaded
	game.player.shoot()
	check(game.raid.loaded==loaded-1 and enemy.health<70,"one shotgun cartridge produces multiple damaging pellets")
	# Lure works for patrols, respects cooldown, walls and pause, and can be recovered.
	game.raid.bag.decoy=2
	game.player.aim=Vector2(1,0)
	enemy.mode="patrol"
	game.ui.update(.1)
	var pads=game.controls.centers()
	touch(91,pads.move+Vector2(25,0),true)
	touch(92,pads.aim+Vector2(0,-35),true)
	var button_point=game.ui.decoy_button.global_position+game.ui.decoy_button.size/2
	touch(93,button_point,true);touch(93,button_point,false)
	check(game.raid.decoys.size()==1,"señuelo thrown using actual touch button")
	check(game.controls.fingers.size()==2 and game.controls.move_vector.length()>0 and game.controls.aim_vector.length()>0,"third finger lure preserves active movement and aiming")
	var mouse=InputEventMouseButton.new()
	mouse.position=button_point;mouse.button_index=MOUSE_BUTTON_LEFT;mouse.pressed=true
	root.push_input(mouse,true)
	check(not game.controls.mouse_fire,"direct mouse press on UI is excluded before hover updates")
	mouse.pressed=false;root.push_input(mouse,true)
	touch(91,pads.move,false);touch(92,pads.aim,false)
	check(game.raid.bag.decoy==1 and game.raid.decoys.size()==1 and enemy.mode=="investigate","lure consumes one item and attracts a patrol")
	check(not game.expedition.throw_decoy() and game.raid.bag.decoy==1,"lure cooldown prevents double consumption")
	var duration=game.raid.decoys[0].remaining
	game.set_paused(true);game.expedition.tick(3)
	check(game.raid.decoys[0].remaining==duration,"paused lure does not expire")
	game.show_shelter();game.start_raid();await frames()
	game.set_process(false);game.player.set_physics_process(false)
	for actor in game.enemies:
		actor.set_physics_process(false)
	check(game.paused and game.raid.decoys.size()==1 and game.expedition.beacons.size()==1,"saved lure restored once with remaining time")
	cache=game.world.containers.filter(func(c): return c.get("kind")=="locked")[0]
	check(cache.locked_key.is_empty() and not cache.items.has("shotgun"),"reserve stays unlocked and looted after resume")
	game.resume();game.expedition.tick(8.1)
	check(game.raid.decoys.is_empty(),"lure expires after eight active seconds")
	game.player.position=Vector3(14,0,-16);game.player.aim=Vector2(0,-1)
	await frames()
	check(game.expedition.throw_decoy() and game.raid.decoys[0].p[1]>-19,"thrown lure stops before warehouse wall")
	# Boss is optional and cannot be created twice after interruption.
	game.player.position=Vector3(-26,0,-17);game.expedition.tick(.1)
	var bosses=game.enemies.filter(func(actor):return actor.kind=="warden")
	check(game.raid.warden_spawned and bosses.size()==1,"approaching north outpost activates optional boss")
	var boss=bosses[0];boss.set_physics_process(false)
	boss.take_damage(10)
	check(is_equal_approx(boss.health,203),"boss armor absorbs thirty percent of damage")
	var actor_count=game.enemies.size()
	game.expedition.tick(.1)
	check(game.enemies.size()==actor_count,"boss encounter cannot duplicate")
	boss.take_damage(1000)
	var drops=game.world.containers.size();boss.take_damage(1000)
	check(game.world.containers.size()==drops and game.world.containers.any(func(c):return c.items.has("warden_badge")),"boss drops unique contract proof without duplicate loot")
	# Announce -> land -> reinforcements -> save/resume is one persistent event.
	game.player.position=Vector3(-24,0,22)
	game.raid.time=90;game.expedition.tick(.1)
	check(game.raid.delivery=="incoming" and is_instance_valid(game.expedition.delivery_marker),"ninety-second signal starts visible supply delivery")
	game.set_paused(true)
	game.expedition.tick(30)
	check(game.raid.delivery=="incoming","pause freezes incoming delivery")
	game.resume();game.raid.time=105
	actor_count=game.enemies.size()
	game.expedition.tick(.1)
	for actor in game.enemies:
		actor.set_physics_process(false)
	var delivery=game.world.containers.filter(func(c):return c.get("kind")=="airdrop")
	check(game.raid.delivery=="landed" and delivery.size()==1 and delivery[0].items.ammo20==18,"delivery lands with expected supplies")
	check(game.enemies.size()==actor_count+2,"landing attracts two reinforcements")
	game.expedition.tick(1)
	check(game.enemies.size()==actor_count+2,"landed event cannot duplicate reinforcement or chest")
	game.pause_menu();game.show_shelter();game.start_raid();await frames()
	check(game.paused and game.raid.delivery=="landed" and game.enemies.size()==actor_count+2,"resumed raid preserves single delivery and reinforcement count")
	game.ui.shelter_tab="Fabricar";game.show_shelter();await frames()
	var craft_buttons=game.ui.content.find_children("*","Button",true,false).filter(func(node):return node.text.begins_with("Fabricar:"))
	check(craft_buttons.size()==5 and craft_buttons.all(func(node):return node.disabled),"suspended crafting tab presents five disabled recipes")
	game.queue_free();await frames();await create_timer(.2).timeout
	for path in ["user://content-core-test.json","user://content-scene-test.json"]:
		for suffix in ["",".bak",".tmp"]:
			DirAccess.remove_absolute(path+suffix)
	print("CONTENT_RESULT ",checks," checks, ",failures," failures")
	quit(1 if failures>0 else 0)
