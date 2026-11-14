class_name TouchInput
extends Control
var move_vector = Vector2.ZERO
var aim_vector = Vector2.ZERO
var fingers: Dictionary = {}
var offsets = {"move": Vector2.ZERO, "aim": Vector2.ZERO}
var radius = 65.0
var sensitivity = 1.0
var active = false
var mouse_fire = false
var settings: Dictionary
var pointer_on_button: Callable
var floating_origin: Variant = null
var aim_latched = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(clear)

func centers() -> Dictionary:
	return {"move": floating_origin if floating_origin!=null else Vector2(116, size.y - 117), "aim": Vector2(size.x - 150, size.y - 120)}

func clear() -> void:
	fingers.clear()
	floating_origin = null
	aim_latched = false
	offsets.move = Vector2.ZERO
	offsets.aim = Vector2.ZERO
	move_vector = Vector2.ZERO
	aim_vector = Vector2.ZERO
	mouse_fire = false
	queue_redraw()

func _input(event: InputEvent) -> void:
	if not active:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			if fingers.has(event.index):
				return
			if pointer_on_button.is_valid() and pointer_on_button.call(event.position):
				return
			for side in ["move", "aim"]:
				if not side in fingers.values() and (event.position - global_position).distance_to(centers()[side]) < radius * 1.45:
					fingers[event.index] = side
					update_finger(event.index, event.position)
					get_viewport().set_input_as_handled()
					break
			var point = event.position-global_position
			if not fingers.has(event.index) and not "move" in fingers.values() and settings!=null and settings.get("adaptive_stick",true) and point.x<size.x*.4 and point.y>size.y*.45:
				floating_origin = Vector2(clampf(point.x,radius+10,size.x*.4),clampf(point.y,size.y*.45,size.y-radius-10))
				fingers[event.index] = "move"
				update_finger(event.index,event.position)
				get_viewport().set_input_as_handled()
		elif fingers.has(event.index):
			var side: String = fingers[event.index]
			fingers.erase(event.index)
			offsets[side] = Vector2.ZERO
			if side == "move":
				move_vector = Vector2.ZERO
				floating_origin = null
			else:
				aim_vector = Vector2.ZERO
				aim_latched = false
			queue_redraw()
	if event is InputEventScreenDrag and fingers.has(event.index):
		update_finger(event.index, event.position)
		get_viewport().set_input_as_handled()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var over_button = pointer_on_button.is_valid() and pointer_on_button.call(event.position)
		mouse_fire = event.pressed and not over_button

func update_finger(index: int, point: Vector2) -> void:
	var side: String = fingers[index]
	var raw: Vector2 = (point - global_position - centers()[side]) / radius
	offsets[side] = raw.limit_length() * radius
	if side=="aim":
		if raw.length()>.29:
			aim_latched = true
		elif raw.length()<.21:
			aim_latched = false
	var deadzone = (.21 if aim_latched else .29) if side=="aim" else .12
	var value = Vector2.ZERO
	if raw.length() > deadzone:
		value = raw.normalized() * clampf((raw.length() - deadzone) / (1 - deadzone), 0, 1)
	if side == "move":
		move_vector = value
	else:
		aim_vector = value
	queue_redraw()

func movement() -> Vector2:
	var keyboard = Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)), float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
	return keyboard.limit_length() if keyboard.length() > 0 else move_vector

func _draw() -> void:
	if not active:
		return
	for side in ["move", "aim"]:
		var center: Vector2 = centers()[side]
		var c = Color("e4d6ad") if side == "move" else Color("eeb374")
		draw_circle(center, radius, Color(c, 0.09))
		draw_arc(center, radius, 0, TAU, 48, Color(c, 0.5), 2, true)
		draw_circle(center, radius * 0.24, Color(c, 0.07))
		draw_circle(center + offsets[side], radius * 0.39, Color(c, 0.45))
		draw_arc(center + offsets[side], radius * 0.39, 0, TAU, 32, Color(c, 0.8), 2, true)
		draw_string(ThemeDB.fallback_font, center + Vector2(-30, radius + 25), "MOVER" if side == "move" else "APUNTAR", HORIZONTAL_ALIGNMENT_CENTER, 60, 13, Color(c, 0.8))
