class_name TouchCalibration
extends Control
var game: Node3D
var controls: TouchInput
var status: Label
var action_button: TouchActionButton
var back_button: TouchActionButton
var action_count = 0
var combo_count = 0
var buttons: Array[Button] = []
var previous_contacts: Dictionary = {}
var samples: Array = []
var released_move = false
var released_aim = false
var original_resources: Dictionary = {}

func configure(host: Node3D) -> void:
	game = host
	original_resources = resources()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var background = ColorRect.new()
	background.color = Color("14212bfa")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var heading = Label.new()
	heading.text = "PRUEBA DE CONTROLES"
	heading.position = Vector2(40,35)
	heading.add_theme_font_size_override("font_size",30)
	add_child(heading)
	var instructions = Label.new()
	instructions.text = "Mantén movimiento y apuntado. Pulsa ACCIÓN con un tercer dedo.\nSuelta un joystick: el otro debe seguir respondiendo. Aquí no gastas equipo."
	instructions.position = Vector2(40,92)
	instructions.add_theme_font_size_override("font_size",19)
	add_child(instructions)
	status = Label.new()
	status.position = Vector2(40,205)
	status.add_theme_font_size_override("font_size",24)
	add_child(status)
	controls = TouchInput.new()
	add_child(controls)
	controls.settings = game.progression.profile.settings
	controls.radius = game.controls.radius
	controls.active = true
	controls.pointer_on_button = Callable(self,"pointer_on_button")
	action_button = TouchActionButton.new()
	action_button.text = "ACCIÓN"
	action_button.size = Vector2(230,76)
	action_button.pressed.connect(func():
		action_count += 1
		if controls.fingers.size()==2 and controls.move_vector.length()>.05 and controls.aim_vector.length()>.05:
			combo_count += 1)
	add_child(action_button)
	buttons.append(action_button)
	back_button = TouchActionButton.new()
	back_button.text = "Volver a Ajustes"
	back_button.size = Vector2(230,60)
	back_button.pressed.connect(func(): game.ui.settings_panel())
	add_child(back_button)
	buttons.append(back_button)
	resized.connect(layout)
	layout()

func layout() -> void:
	if not is_instance_valid(controls):
		return
	controls.clear()
	action_button.clear_touch()
	back_button.clear_touch()
	action_button.position = Vector2(size.x/2-115,size.y-180)
	back_button.position = Vector2(size.x-270,35)

func pointer_on_button(point: Vector2) -> bool:
	return buttons.any(func(b):return b.get_global_rect().has_point(point))

func _process(_delta: float) -> void:
	if not is_instance_valid(controls):
		return
	status.text = "Movimiento: %s\nApuntado: %s\nAcciones: %d\nTercer dedo con ambos sticks: %s" % ["ACTIVO" if controls.move_vector.length()>.05 else "en reposo","ACTIVO" if controls.aim_vector.length()>.05 else "en reposo",action_count,"OK (%d)" % combo_count if combo_count>0 else "pendiente"]
	record_contacts()

func resources() -> Dictionary:
	return {"health":game.raid.health,"loaded":game.raid.loaded,"time":game.raid.time} if game.mode=="raid" else {}

func record_contacts() -> void:
	var contact = {"fingers":controls.fingers.size(),"move_active":controls.move_vector.length()>.05,"aim_active":controls.aim_vector.length()>.05,"actions":action_count,"combos":combo_count}
	if contact==previous_contacts:
		return
	var capture = contact.combos>previous_contacts.get("combos",0)
	if previous_contacts.get("fingers",0)==2 and contact.fingers==1:
		released_move = released_move or (not contact.move_active and contact.aim_active)
		released_aim = released_aim or (contact.move_active and not contact.aim_active)
	previous_contacts = contact.duplicate()
	samples.append(contact)
	if samples.size()>64:
		samples.pop_front()
	# Export a local report on native phones only; no network or player identity.
	if OS.has_feature("ios") or OS.has_feature("android"):
		var file = FileAccess.open("user://touch-validation-v05.json",FileAccess.WRITE)
		if file!=null:
			file.store_string(JSON.stringify({"version":ProjectSettings.get_setting("application/config/version"),"os":OS.get_name(),"utc":Time.get_datetime_string_from_system(true),"viewport":[size.x,size.y],"actions":action_count,"combos":combo_count,"released_move":released_move,"released_aim":released_aim,"resources_preserved":resources()==original_resources,"samples":samples}))
		if capture:
			capture_report_image()

func capture_report_image() -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://touch-validation-v05.png")

func state() -> Dictionary:
	return {"move":[controls.move_vector.x,controls.move_vector.y],"aim":[controls.aim_vector.x,controls.aim_vector.y],"fingers":controls.fingers.size(),"actions":action_count,"combos":combo_count,"released_move":released_move,"released_aim":released_aim}

func shutdown() -> void:
	controls.active = false
	controls.clear()
	record_contacts()
	for b in buttons:
		b.clear_touch()
	hide()
