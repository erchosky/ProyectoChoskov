class_name Minimap
extends Control
var game: Node3D
var panel_style := StyleBoxFlat.new()
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = custom_minimum_size.max(Vector2(156,156))
	panel_style.bg_color = Color("172b2b")
	panel_style.border_color = Color("708478")
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(14)
func point(p: Vector2) -> Vector2:
	return size*0.5 + p * (size.x/74.0)
func _draw() -> void:
	draw_style_box(panel_style, Rect2(Vector2.ZERO, size))
	draw_line(point(Vector2(-13,-30)),point(Vector2(-13,30)),Color("8f9079"),5)
	draw_line(point(Vector2(-30,12)),point(Vector2(30,12)),Color("8f9079"),4)
	draw_rect(Rect2(point(Vector2(5,-19)), Vector2(18,17)*(size.x/74.0)),Color("adbaaa"),false,2)
	if game.world == null:
		return
	for c in game.world.containers:
		if not c.items.is_empty():
			draw_circle(point(Vector2(c.p[0], c.p[1])),4 if c.get("kind")=="airdrop" else 2,Color("9cdae3") if c.get("kind")=="airdrop" else Color("d4b66a"))
	var boss = point(Vector2(Catalog.expedition.boss_position[0],Catalog.expedition.boss_position[1]))
	draw_line(boss-Vector2(4,4),boss+Vector2(4,4),Color("e9987e"),2)
	draw_line(boss+Vector2(-4,4),boss+Vector2(4,-4),Color("e9987e"),2)
	if game.raid.get("delivery", "waiting")=="incoming":
		var p = game.raid.delivery_point
		draw_circle(point(Vector2(p[0],p[1])),7,Color("9cdae3"),false,2)
	for zone in game.world.extraction_zones:
		var ready = not zone.radio or game.raid.get("radio_powered",false)
		draw_circle(point(zone.p),5,Color("a6db97") if ready else Color("f4be76"),false,2)
	for note in Catalog.notes:
		if not game.progression.profile.journal.has(note.id):
			draw_rect(Rect2(point(Vector2(note.p[0],note.p[1]))-Vector2(2,2),Vector2(4,4)),Color("a8d4ee"))
	var mission = game.progression.tracked()
	if not mission.is_empty() and mission.has("target"):
		var target = point(Vector2(mission.target[0],mission.target[1]))
		draw_arc(target,8,0,TAU,16,Color("ebd388"),2)
	if game.player != null:
		var player_point = point(Vector2(game.player.position.x,game.player.position.z))
		draw_line(player_point,player_point+game.player.aim*10,Color("fff0cc"),2)
		draw_circle(point(Vector2(game.player.position.x,game.player.position.z)),4,Color("fff0cc"))
	draw_string(ThemeDB.fallback_font,Vector2(12,18),"N  ^",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("c3d6c5"))
