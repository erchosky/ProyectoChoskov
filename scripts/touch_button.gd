class_name TouchActionButton
extends Button
var finger := -1
var start := Vector2.ZERO
var cancelled := false

func _input(event: InputEvent) -> void:
	if disabled or not is_visible_in_tree():
		clear_touch()
		return
	if event is InputEventScreenTouch:
		var inside = accepts_point(event.position)
		if event.pressed and finger == -1 and inside:
			forward_scroll(event)
			get_viewport().set_input_as_handled()
			finger = event.index
			start = event.position
			cancelled = false
			set_pressed_no_signal(true)
		elif not event.pressed and event.index == finger:
			forward_scroll(event)
			get_viewport().set_input_as_handled()
			var activate = inside and not cancelled and not event.canceled
			clear_touch()
			if activate:
				pressed.emit()
	if event is InputEventScreenDrag and event.index == finger:
		forward_scroll(event)
		get_viewport().set_input_as_handled()
		if event.position.distance_to(start) > 12:
			cancelled = true
			set_pressed_no_signal(false)

# Native Button also handles ScreenTouch in newer engines. Consume our owned
# touch once, but keep the enclosing scroll container informed of its gesture.
func forward_scroll(event: InputEvent) -> void:
	var ancestor = get_parent()
	while ancestor!=null:
		if ancestor is TouchScroll:
			ancestor._input(event)
			return
		ancestor = ancestor.get_parent()

func clear_touch() -> void:
	finger = -1
	cancelled = false
	set_pressed_no_signal(false)

# _input bypasses Godot's GUI hit testing, including ancestor clipping.
func accepts_point(point: Vector2) -> bool:
	if not is_visible_in_tree() or not get_global_rect().has_point(point):
		return false
	var ancestor = get_parent()
	while ancestor != null:
		if ancestor is Control and ancestor.clip_contents and not ancestor.get_global_rect().has_point(point):
			return false
		ancestor = ancestor.get_parent()
	return true
