extends SceneTree
var checks = 0
var failures = 0
func check(value: bool, message: String) -> void:
	checks += 1
	if value:
		print("PASS: ", message)
	else:
		failures += 1
		print("FAIL: ", message)
func _initialize() -> void:
	call_deferred("run")
func frames() -> void:
	for i in 3:
		await physics_frame
		await process_frame
func touch(id: int, point: Vector2, down: bool) -> void:
	var event = InputEventScreenTouch.new()
	event.index = id
	event.position = point
	event.pressed = down
	root.push_input(event, true)
func envelope(path: String, profile: Dictionary) -> void:
	var payload = JSON.stringify(profile)
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"payload":payload,"checksum":payload.sha256_text()}))
	file.close()
func run() -> void:
	var store = SaveStore.new()
	store.path = "user://audit-test.json"
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(store.path+suffix)
	var prog = Progression.new(store)
	prog.profile.stash = {}
	prog.profile.equipment = {"armor":"armor","pack":"pack"}
	prog.profile.credits = 0
	check(prog.emergency(), "emergency weapon available with armor and no weapons")
	check(prog.profile.equipment.get("weapon", "")=="pistol" and prog.profile.equipment.has("armor") and prog.profile.equipment.has("pack"), "emergency preserves equipped armor and backpack")
	var malformed = SaveStore.fresh()
	malformed.stash = {"unknown-item":1}
	envelope(store.path,malformed)
	check(store.read_file(store.path).is_empty(), "checksummed save rejects unknown inventory IDs")
	malformed = SaveStore.fresh()
	malformed.stash.ammo9 = -20
	envelope(store.path,malformed)
	check(store.read_file(store.path).is_empty(), "checksummed save rejects negative quantities")
	malformed = SaveStore.fresh()
	malformed.settings = {}
	envelope(store.path,malformed)
	var loaded = store.read_file(store.path)
	check(not loaded.is_empty() and loaded.settings.get("fps",0)==60 and loaded.settings.get("adaptive_stick",false), "missing settings migrate to safe defaults")
	malformed = SaveStore.fresh()
	malformed.active = {"id":"bad","bag":{}}
	envelope(store.path,malformed)
	check(store.read_file(store.path).is_empty(), "incomplete active raid rejected before scene restore")
	store.write(SaveStore.fresh())
	store.write(SaveStore.fresh())
	malformed = SaveStore.fresh()
	malformed.equipment = {"weapon":"scrap"}
	envelope(store.path,malformed)
	check(store.load_profile().stash.get("pistol",0)==1 and store.recovered, "invalid equipped weapon recovers validated backup")
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frames()
	game.ignore_focus = true
	game.store.path = "user://audit-scene-test.json"
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(game.store.path+suffix)
	game.progression = Progression.new(game.store)
	game.start_raid()
	game.set_process(false)
	game.player.set_physics_process(false)
	for actor in game.enemies:
		actor.set_physics_process(false)
	await frames()
	game.raid.bag.scrap = 3
	game.checkpoint()
	var healthy = game.store.load_profile()
	check(not healthy.is_empty() and healthy.active.enemies.size()==8, "complete live scene survives stricter validation")
	malformed = healthy.duplicate(true)
	malformed.active.loaded = 999
	envelope(store.path, malformed)
	check(store.read_file(store.path).is_empty(), "oversized magazine rejected without inventing ammunition")
	malformed = healthy.duplicate(true)
	malformed.active.enemies[0].kind = "unknown"
	envelope(store.path, malformed)
	check(store.read_file(store.path).is_empty(), "invalid restored enemy rejected before catalog lookup")
	malformed = healthy.duplicate(true)
	malformed.active.containers[0].p = [1]
	envelope(store.path, malformed)
	check(store.read_file(store.path).is_empty(), "invalid container coordinates rejected before restore")
	malformed = healthy.duplicate(true)
	malformed.active.enemies[0].search_timer = -.25
	envelope(store.path, malformed)
	loaded = store.read_file(store.path)
	check(not loaded.is_empty() and loaded.active.enemies[0].search_timer==0, "legacy negative search timer migrates without losing raid")
	var raid_id = game.raid.id
	var credits = game.progression.profile.credits
	game.store.path = "user://missing-audit-directory/profile.json"
	game.finish_raid(true, "")
	check(game.paused and game.raid.result=="success" and game.progression.profile.credits==credits, "failed extraction remains pending without granting reward")
	game.resume()
	check(game.paused and not game.controls.active and not game.ui.hud.visible, "pending result cannot resume gameplay")
	game.open_bag()
	check(game.ui.visible_buttons().any(func(b):return b.text=="Reintentar guardado") and not game.ui.visible_buttons().any(func(b):return b.text=="Volver a la incursión"), "pending result cannot open backpack to alter committed loot")
	game.pause_menu("Focus out")
	check(game.ui.visible_buttons().any(func(b):return b.text=="Reintentar guardado"), "focus interruption preserves result retry panel")
	game.store.path = "user://audit-scene-test.json"
	game.finish_raid(false,"retry with wrong caller argument")
	check(game.mode=="result" and game.progression.profile.credits==credits+35 and game.progression.profile.prepared.get("scrap",0)==3, "retry resolves saved success intent even with stale caller argument")
	check(game.progression.profile.processed.count(raid_id)==1, "retry records exactly one completed raid")
	game.finish_raid(true, "")
	check(game.progression.profile.credits==credits+35, "repeated result signal cannot duplicate rewards")
	game.show_shelter()
	game.start_raid()
	await frames()
	game.player.set_physics_process(false)
	for actor in game.enemies:
		actor.set_physics_process(false)
	credits = game.progression.profile.credits
	game.store.path = "user://missing-audit-directory/profile.json"
	game.player.take_damage(1000)
	game.open_map()
	check(game.paused and not game.player.alive and game.raid.result=="death" and game.ui.visible_buttons().any(func(b):return b.text=="Reintentar guardado"), "pending death blocks map and all gameplay navigation")
	game.store.path = "user://audit-scene-test.json"
	game.finish_raid(true, "stale success callback")
	check(game.mode=="result" and game.progression.profile.equipment.is_empty() and game.progression.profile.prepared.is_empty() and game.progression.profile.credits==credits, "pending death cannot become an extraction on retry")
	# Isolate an off-screen scroll child whose global rectangle overlaps a visible sibling.
	game.show_shelter()
	game.ui.clear_panel()
	var scroll = TouchScroll.new()
	scroll.position = Vector2(100,100)
	scroll.size = Vector2(220,100)
	game.ui.root.add_child(scroll)
	var list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(200,180)
	list.add_child(spacer)
	var clipped = TouchActionButton.new()
	clipped.text = "CLIPPED"
	clipped.custom_minimum_size = Vector2(200,50)
	list.add_child(clipped)
	var calls = [0,0]
	clipped.pressed.connect(func():calls[0]+=1)
	await frames()
	var point = clipped.global_position+clipped.size/2
	var visible = TouchActionButton.new()
	visible.text = "VISIBLE"
	visible.position = clipped.global_position
	visible.size = clipped.size
	visible.pressed.connect(func():calls[1]+=1)
	game.ui.root.add_child(visible)
	await frames()
	touch(89,point,true)
	touch(89,point,false)
	check(calls[0]==0 and calls[1]==1, "clipped scroll buttons cannot intercept a visible sibling tap")
	visible.hide()
	touch(90,point,true)
	touch(90,point,false)
	check(calls[0]==0, "touch outside scroll viewport cannot activate hidden content")
	check(not game.ui.pointer_on_button(point), "clipped buttons do not block aim or movement input")
	scroll.queue_free()
	visible.queue_free()
	game.queue_free()
	await frames()
	await create_timer(.2).timeout
	for path in [store.path,"user://audit-scene-test.json"]:
		for suffix in ["", ".bak", ".tmp"]:
			DirAccess.remove_absolute(path+suffix)
	print("AUDIT_RESULT ",checks," checks, ",failures," failures")
	quit(1 if failures>0 else 0)
