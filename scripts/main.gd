extends Node3D
var store = SaveStore.new()
var progression: Progression
var ui: GameUI
var controls: TouchInput
var world: RaidWorld
var player: Explorer
var enemies: Array[Raider] = []
var camera: Camera3D
var effects: Effects
var sound: GameSound
var mode = "shelter"
var paused = false
var raid: Dictionary = {}
var extract_timer = 0.0
var extract_zone: Dictionary = {}
var autosave = 0.0
var ui_clock = 0.0
var ignore_focus = false
var camera_target = Vector3.ZERO
var web_callbacks: Array = []
var camera_shake = 0.0
var expedition: RaidContent

func _ready() -> void:
	progression = Progression.new(store)
	var args = OS.get_cmdline_user_args()
	if "--isolated" in args:
		store.path = "user://preview.json"
		progression = Progression.new(store)
		if "--capture" in args:
			progression.profile = SaveStore.fresh()
	if "--capture" in args:
		ignore_focus = true
	sound = GameSound.new()
	add_child(sound)
	var input_layer = CanvasLayer.new()
	add_child(input_layer)
	controls = TouchInput.new()
	input_layer.add_child(controls)
	ui = GameUI.new()
	add_child(ui)
	ui.setup(self)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 18.5
	camera.near = 0.1
	camera.far = 100
	add_child(camera)
	camera.current = true
	show_shelter()
	save_settings(false)
	if store.recovered:
		notify("Guardado recuperado desde la copia de respaldo")
	if "--capture" in args:
		capture_preview()
	if OS.has_feature("web"):
		install_web_hooks()
	if OS.is_debug_build() and (OS.has_feature("ios") or OS.has_feature("android")):
		capture_mobile_debug()

func capture_mobile_debug() -> void:
	await get_tree().create_timer(2).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://native-validation-v05.png")
	var file = FileAccess.open("user://native-validation-v05.json",FileAccess.WRITE)
	if file!=null:
		var area = DisplayServer.get_display_safe_area()
		file.store_string(JSON.stringify({"version":ProjectSettings.get_setting("application/config/version"),"os":OS.get_name(),"safe_area":[area.position.x,area.position.y,area.size.x,area.size.y],"state":text_state()}))

func install_web_hooks() -> void:
	var interface = JavaScriptBridge.get_interface("window")
	var callback = JavaScriptBridge.create_callback(func(_args):
		JavaScriptBridge.eval("window._choskovState=" + JSON.stringify(text_state()) + ";", true))
	web_callbacks.append(callback)
	interface.choskovState = callback
	JavaScriptBridge.eval("window.render_game_to_text=()=>{window.choskovState();return JSON.stringify(window._choskovState)}; window.advanceTime=async(ms)=>new Promise(r=>setTimeout(r,ms));",true)

func text_state() -> Dictionary:
	var result = {"version":ProjectSettings.get_setting("application/config/version"),"mode": mode,"paused": paused,"coordinate_system":"world X right, Z south, meters","credits":progression.profile.credits,"crafted":progression.profile.get("crafted",0),"buttons":ui.visible_buttons(),"stash":progression.profile.stash,"equipment":progression.profile.equipment}
	if is_instance_valid(ui.calibration):
		result.touch_test = ui.calibration.state()
	if mode=="raid":
		result.merge({"player":{"x":player.position.x,"z":player.position.z,"health":raid.health,"stamina":player.stamina,"sprinting":player.sprinting,"dodge":player.dodge_timer,"dodge_cooldown":player.dodge_cooldown,"velocity":[player.velocity.x,player.velocity.z],"loaded":raid.loaded,"reserve":raid.bag.get(player.weapon().ammo,0),"reload":player.reload_timer,"heal":player.heal_timer},"controls":{"fingers":controls.fingers.size(),"move":[controls.move_vector.x,controls.move_vector.y],"aim":[controls.aim_vector.x,controls.aim_vector.y]},"bag":raid.bag,"extraction":extract_timer,"enemies":enemies.map(func(e):return {"x":e.position.x,"z":e.position.z,"alive":e.alive,"state":e.mode,"kind":e.kind,"health":e.health}),"nearby":nearest_interaction().get("type", ""),"crouched":player.crouched,"radio_powered":raid.get("radio_powered",false),"journal":progression.profile.journal,"objective":progression.objective(raid),"delivery":raid.get("delivery","waiting"),"delivery_point":raid.get("delivery_point",[]),"decoys":raid.get("decoys",[]),"warden_spawned":raid.get("warden_spawned",false)})
	return result

func clear_world() -> void:
	if is_instance_valid(world):
		remove_child(world)
		world.queue_free()
	world = RaidWorld.new()
	add_child(world)
	enemies.clear()
	player = null
	effects = Effects.new()
	world.add_child(effects)

func show_shelter() -> void:
	if mode == "raid":
		checkpoint()
	mode = "shelter"
	paused = false
	controls.active = false
	controls.clear()
	extract_timer = 0
	extract_zone = {}
	clear_world()
	world.build(42,true)
	var explorer = Node3D.new()
	world.add_child(explorer)
	explorer.position = Vector3(-24,0,23)
	Art.animal(explorer,Color("718b75"),true).rotation.y = -0.5
	Art.label(world,"NILO\nExplorador de la Linde",Vector3(-24,3.3,23),Color("f2dfae"),35)
	camera.size = 18
	camera_target = Vector3(-20,0,22)
	camera.position = camera_target + Vector3(0,23,16)
	camera.look_at(camera_target,Vector3.UP)
	ui.shelter()
	save_settings(false)

func start_raid() -> void:
	var resume_existing = not progression.profile.active.is_empty()
	raid = progression.begin(randi() % 2147483647)
	if raid.is_empty():
		notify("No se pudo preparar o guardar la incursión")
		return
	if not raid.get("result", "").is_empty():
		mode = "raid"
		finish_raid(raid.result=="success","Interrupción durante el resultado")
		return
	mode = "raid"
	paused = false
	controls.active = true
	controls.clear()
	clear_world()
	world.build(int(raid.seed))
	player = Explorer.new()
	world.add_child(player)
	player.configure(self,raid)
	player.damaged.connect(cancel_extraction)
	player.damaged.connect(func(): ui.damage_flash.color.a=0.22)
	player.died.connect(func(): finish_raid(false,"Nilo ha caído"))
	if raid.get("initialized",false):
		# Restore every container, including drops, without rolling loot twice.
		for c in world.containers:
			c.node.queue_free()
		world.containers.clear()
		for c in raid.containers:
			world.add_container(Vector2(c.p[0],c.p[1]),c.items.duplicate(true),c.name,c.get("locked_key",""),c.get("kind","supplies"))
		for e in raid.enemies:
			spawn_enemy(e.kind,Vector3(e.p[0],0,e.p[1]),e)
	else:
		var rng = RandomNumberGenerator.new()
		rng.seed = int(raid.seed)
		for spec in [{"kind":"runner","p":Vector2(-8,13)},{"kind":"runner","p":Vector2(-18,-2)},{"kind":"runner","p":Vector2(-5,-13)},{"kind":"runner","p":Vector2(5,17)},{"kind":"sentinel","p":Vector2(12,-11)},{"kind":"sentinel","p":Vector2(20,-5)},{"kind":"sentinel","p":Vector2(27,-10)},{"kind":"sentinel","p":Vector2(-15,-25)}]:
			var p: Vector2 = spec.p + Vector2(rng.randf_range(-0.7,0.7),rng.randf_range(-0.7,0.7))
			spawn_enemy(spec.kind,Vector3(p.x,0,p.y))
		raid.initialized = true
	expedition = RaidContent.new(self)
	camera.size = 18.5
	camera_target = player.position
	camera.position = camera_target + Vector3(0,23,16)
	camera.look_at(camera_target,Vector3.UP)
	extract_timer = 0
	extract_zone = {}
	ui.raid_hud()
	autosave = 0
	checkpoint()
	save_settings(false)
	if resume_existing:
		pause_menu("Incursión recuperada")
	else:
		notify("Linde de Bruma · elige cuánto arriesgar")

func spawn_enemy(kind: String,p: Vector3,saved: Dictionary={}) -> Raider:
	var enemy = Raider.new()
	world.add_child(enemy)
	enemy.configure(self,kind,p,saved)
	enemies.append(enemy)
	return enemy

func _process(delta: float) -> void:
	ui_clock += delta
	if ui_clock >= 0.1:
		ui.update(ui_clock)
		ui_clock = 0
	if mode != "raid" or player == null or paused:
		return
	raid.time += delta
	expedition.tick(delta)
	autosave += delta
	if autosave > 5:
		autosave = 0
		checkpoint()
	var lead = Vector3(player.aim.x,0,player.aim.y)*1.2 if controls.aim_vector.length()>0.05 or controls.mouse_fire else player.velocity*0.16
	camera_target = camera_target.lerp(player.position+lead,1-exp(-delta*10))
	camera.size = lerpf(camera.size,20.5 if player.sprinting else 18.5,1-exp(-delta*3))
	camera_shake = move_toward(camera_shake,0,delta*0.8)
	camera.position = camera_target + Vector3(sin(raid.time*83)*camera_shake,23,16+cos(raid.time*97)*camera_shake)
	camera.look_at(camera_target,Vector3.UP)
	world.update_roof(player.position)
	if extract_timer>0:
		if Vector2(player.position.x,player.position.z).distance_to(extract_zone.p)>2.8:
			cancel_extraction()
		else:
			extract_timer -= delta
			if extract_timer<=0:
				finish_raid(true,"")
	if mode=="raid" and raid.time>=600:
		finish_raid(false,"La bruma cerró las rutas · tiempo agotado")

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode==KEY_F:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)
		if mode!="raid":
			return
		match event.physical_keycode:
			KEY_ESCAPE:
				if paused:
					resume()
				else:
					pause_menu()
			KEY_TAB:
				if paused:
					resume()
				else:
					open_bag()
			KEY_R:
				if not paused:
					player.reload_weapon()
			KEY_H:
				if not paused:
					player.heal()
			KEY_G:
				if not paused:
					expedition.throw_decoy()
			KEY_SPACE:
				if not paused:
					player.dodge()
			KEY_C:
				if not paused:
					player.toggle_crouch()
			KEY_M:
				if not paused:
					open_map()
			KEY_E:
				if not paused:
					interact()

func _notification(what: int) -> void:
	if progression==null:
		return
	if what in [NOTIFICATION_APPLICATION_PAUSED,NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_WM_WINDOW_FOCUS_OUT]:
		if mode=="raid" and not ignore_focus:
			pause_menu("Aplicación interrumpida")
		else:
			progression.persist()
	if what==NOTIFICATION_WM_CLOSE_REQUEST:
		checkpoint()

func mouse_world() -> Vector3:
	var mouse = get_viewport().get_mouse_position()
	var ray_origin = camera.project_ray_origin(mouse)
	var ray_direction = camera.project_ray_normal(mouse)
	var hit = Plane(Vector3.UP,1.15).intersects_ray(ray_origin,ray_direction)
	return hit if hit!=null else player.position

func visible_between(from: Vector3,to: Vector3,exclude: Array=[]) -> bool:
	var exclusions: Array[RID] = []
	exclusions.assign(exclude)
	var query = PhysicsRayQueryParameters3D.create(from+Vector3(0,1.15,0),to+Vector3(0,1.15,0),1,exclusions)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func make_noise(p: Vector3,radius: float) -> void:
	for enemy in enemies:
		enemy.noise(p,radius)

func nearest_interaction() -> Dictionary:
	if player==null:
		return {}
	var p = Vector2(player.position.x,player.position.z)
	var best = 2.5
	var result: Dictionary = {}
	for c in world.containers:
		var dist = p.distance_to(Vector2(c.p[0],c.p[1]))
		if not c.items.is_empty() and dist<best and visible_between(player.position,c.node.position,[player.get_rid()]):
			best = dist
			result = {"type":"loot","container":c}
	for note in world.notes:
		var dist = player.position.distance_to(note.node.position)
		if not progression.profile.journal.has(note.id) and dist<best and visible_between(player.position,note.node.position,[player.get_rid()]):
			best = dist
			result = {"type":"note","id":note.id}
	if result.is_empty():
		for zone in world.extraction_zones:
			if p.distance_to(zone.p)<2.8:
				return {"type":"exit","zone":zone}
	return result

func interact() -> void:
	if mode!="raid" or paused:
		return
	var nearby = nearest_interaction()
	if nearby.get("type")=="loot":
		var container: Dictionary = nearby.container
		if not container.get("locked_key", "").is_empty():
			if not Inventory.remove(raid.bag,container.locked_key,1):
				notify("Reserva cerrada · busca la llave en el puesto forestal")
				return
			container.locked_key = ""
			notify("Reserva abierta · la llave se ha consumido")
		set_paused(true)
		ui.loot(container)
	elif nearby.get("type")=="note":
		if not progression.discover(nearby.id):
			notify("No se pudo guardar la página")
			return
		set_paused(true)
		ui.story(nearby.id)
	elif nearby.get("type")=="exit":
		if nearby.zone.radio and not raid.get("radio_powered",false):
			if not Inventory.remove(raid.bag,"battery",1):
				notify("Torre sin energía · necesitas 1 batería")
				return
			raid.radio_powered = true
			checkpoint()
		extract_zone = nearby.zone
		extract_timer = 6
		notify("Permanece en el círculo · el daño cancela la extracción")

func cancel_extraction() -> void:
	if extract_timer>0:
		notify("Extracción cancelada")
	extract_timer = 0
	extract_zone = {}

func set_paused(value: bool) -> void:
	paused = value
	ui.clear_touch_buttons()
	controls.active = not value and mode=="raid"
	controls.clear()
	if value:
		ui.hud.visible = false
		if player!=null:
			player.velocity = Vector3.ZERO
			player.sprint_requested = false
			player.sprinting = false
		cancel_extraction()
		checkpoint()

func pause_menu(reason: String="") -> void:
	if mode!="raid":
		return
	if pending_result():
		return
	set_paused(true)
	ui.pause_panel(reason)

func open_bag() -> void:
	if mode!="raid":
		return
	if pending_result():
		return
	set_paused(true)
	ui.bag()

func resume() -> void:
	if mode!="raid":
		return
	if pending_result():
		return
	set_paused(false)
	ui.raid_hud()

func equip_raid(id: String) -> void:
	if raid.bag.get(id,0)<1:
		return
	var slot = "weapon" if Catalog.items[id].category=="arma" else id
	var trial: Dictionary = raid.bag.duplicate(true)
	Inventory.remove(trial,id,1)
	if slot=="weapon":
		var old_weapon: String = raid.equipment.weapon
		var ammo: String = Catalog.weapons[old_weapon].ammo
		if Inventory.add(trial,old_weapon,1,player.capacity())!=1 or Inventory.add(trial,ammo,raid.loaded,player.capacity())!=raid.loaded:
			notify("Necesitas espacio para el arma y su cargador")
			return
		player.reload_timer = 0
		player.heal_timer = 0
		raid.loaded = 0
	if slot != "weapon" and raid.equipment.has(slot):
		Inventory.add(trial,raid.equipment[slot],1,player.capacity())
	raid.bag = trial
	raid.equipment[slot] = id
	if slot=="weapon":
		player.update_weapon_model()
	checkpoint()

func loot_value() -> int:
	var value = 0
	for id in raid.get("bag",{}):
		value += int(raid.bag[id])*int(Catalog.items[id].price)
	return value

func checkpoint() -> void:
	if mode=="raid" and not raid.is_empty() and player!=null:
		player.snapshot()
		raid.enemies = enemies.map(func(e):return e.snapshot())
		raid.containers = world.containers.map(func(c):return {"p":c.p,"items":c.items.duplicate(true),"name":c.name,"locked_key":c.get("locked_key",""),"kind":c.get("kind","supplies")})
		progression.profile.active = raid
	if not progression.persist() and ui!=null:
		notify("No se pudo guardar · revisa el espacio disponible")

func finish_raid(success: bool,reason: String) -> void:
	if mode!="raid" or raid.is_empty():
		return
	var value = loot_value()
	var kills: int = raid.kills
	# First terminal outcome owns the result, including retries after a write error.
	if raid.get("result", "").is_empty():
		raid.result = "success" if success else "death"
	success = raid.result == "success"
	checkpoint()
	if not progression.finish(success):
		paused = true
		controls.active = false
		controls.clear()
		ui.pending_result(success,reason)
		return
	if success:
		progression.profile.tutorial = true
		progression.persist()
	mode = "result"
	paused = true
	controls.active = false
	controls.clear()
	extract_timer = 0
	extract_zone = {}
	if success:
		sound.play("extract")
	ui.result(success,value,kills,reason)

func notify(text_value: String) -> void:
	if ui==null:
		return
	ui.toast.text = text_value
	ui.toast_timer = 3.5

func save_settings(persist_value: bool=true) -> void:
	var settings: Dictionary = progression.profile.settings
	Engine.max_fps = int(settings.fps)
	controls.settings = settings
	controls.radius = (85 if OS.has_feature("mobile") else 65) * float(settings.control_size)
	controls.sensitivity = settings.sensitivity
	controls.queue_redraw()
	sound.enabled = settings.sound
	if world!=null:
		for child in world.get_children():
			if child is DirectionalLight3D:
				child.shadow_enabled = settings.quality>0
	if persist_value:
		progression.persist()

func preview_image_path(filename: String) -> String:
	return "user://capture-"+filename if OS.has_feature("mobile") else "res://builds/"+filename

func capture_preview() -> void:
	await get_tree().create_timer(2).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(preview_image_path("refugio.png"))
	progression.profile.stash.merge({"cloth":6,"scrap":8,"wire":4,"filter":2,"circuit":2})
	ui.shelter_tab="Fabricar"
	ui.shelter()
	await get_tree().create_timer(.3).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(preview_image_path("v05-fabricar.png"))
	start_raid()
	resume()
	await get_tree().create_timer(2).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(preview_image_path("incursion.png"))
	player.position = Vector3(13,0,-6)
	await get_tree().create_timer(2).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(preview_image_path("almacen.png"))
	open_map()
	await get_tree().create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(preview_image_path("rutas.png"))
	progression.discover("first_light")
	ui.story("first_light")
	await get_tree().create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(preview_image_path("diario.png"))
	resume()
	for actor in enemies:
		actor.set_physics_process(false)
	player.position=Vector3(-26,0,-17)
	expedition.tick(.1)
	for actor in enemies:
		actor.set_physics_process(false)
	await get_tree().create_timer(1).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(preview_image_path("v05-puesto.png"))
	player.position=Vector3(-3,0,23)
	raid.delivery_point=[-3,23]
	raid.time=96
	expedition.tick(.1)
	await get_tree().create_timer(1).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(preview_image_path("v05-suministros.png"))
	open_map()
	await get_tree().create_timer(.3).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(preview_image_path("v05-rutas.png"))
	resume()
	player.position=Vector3(-17,0,7)
	await get_tree().create_timer(1).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(preview_image_path("v05-vehiculo.png"))
	set_paused(true)
	camera.size=5
	camera.position=player.position+Vector3(0,4,-4)
	camera.look_at(player.position+Vector3(0,1,0))
	await get_tree().create_timer(.3).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(preview_image_path("v05-personaje.png"))
	ui.touch_calibration()
	await get_tree().create_timer(.3).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(preview_image_path("v05-controles.png"))
	print("CAPTURE_STATE ",JSON.stringify(text_state()))
	print("DESKTOP_FPS ",Engine.get_frames_per_second()," DRAW_CALLS ",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	get_tree().quit()

func open_map() -> void:
	if mode!="raid":
		return
	if pending_result():
		return
	set_paused(true)
	ui.route_map()

func pending_result() -> bool:
	if raid.get("result", "").is_empty():
		return false
	paused = true
	controls.active = false
	controls.clear()
	ui.clear_touch_buttons()
	ui.pending_result(raid.result == "success", "")
	return true

func camera_impulse(amount: float) -> void:
	if progression.profile.settings.get("shake",true):
		camera_shake = minf(0.2,camera_shake+amount)
