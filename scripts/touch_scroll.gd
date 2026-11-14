class_name TouchScroll
extends ScrollContainer
var fingers: Dictionary = {}
var starts: Dictionary = {}

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		fingers.clear()
		starts.clear()
		return
	if event is InputEventScreenTouch:
		if event.pressed and get_global_rect().has_point(event.position):
			fingers[event.index] = event.position
			starts[event.index] = event.position
		elif not event.pressed:
			fingers.erase(event.index)
			starts.erase(event.index)
	if event is InputEventScreenDrag and fingers.has(event.index):
		if event.position.distance_to(starts[event.index]) > 12:
			scroll_vertical -= int(event.position.y - fingers[event.index].y)
		fingers[event.index] = event.position
