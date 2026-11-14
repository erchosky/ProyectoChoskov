class_name Effects
extends Node3D
var slots: Array = []
var cursor = 0
var fragments: Array = []
var fragment_cursor = 0

func _ready() -> void:
	for i in 40:
		var mesh = Art.box(self, Vector3.ZERO, Vector3.ONE, Color("ffe4ad"))
		mesh.visible = false
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		slots.append({"mesh": mesh, "life": 0.0})

	for i in 64:
		var mesh = Art.box(self,Vector3.ZERO,Vector3(.06,.06,.12),Color("ffbd65"))
		mesh.visible = false
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		fragments.append({"mesh":mesh,"life":0.0,"velocity":Vector3.ZERO})

func burst(p: Vector3, direction: Vector3, color: Color, count: int) -> void:
	for i in count:
		var slot = fragments[fragment_cursor]
		fragment_cursor = (fragment_cursor+1)%fragments.size()
		slot.mesh.position = p
		slot.mesh.visible = true
		slot.mesh.material_override = Art.material(color,true)
		slot.velocity = direction*randf_range(1,3)+Vector3(randf_range(-1,1),randf_range(.2,2),randf_range(-1,1))
		slot.life = randf_range(.12,.32)

func beam(from: Vector3, to: Vector3, enemy: bool = false) -> void:
	var slot: Dictionary = slots[cursor]
	cursor = (cursor + 1) % slots.size()
	var mesh: MeshInstance3D = slot.mesh
	mesh.visible = true
	mesh.position = (from + to) / 2
	mesh.scale = Vector3(0.025, 0.025, maxf(0.1, from.distance_to(to)))
	if from.distance_to(to) > 0.01:
		mesh.look_at(to, Vector3.UP)
	mesh.material_override = Art.material(Color("ed9975") if enemy else Color("ffe4ad"), true)
	slot.life = 0.09

func _process(delta: float) -> void:
	for slot in slots:
		if slot.life > 0:
			slot.life -= delta
			slot.mesh.visible = slot.life > 0

	for slot in fragments:
		if slot.life>0:
			slot.life -= delta
			slot.velocity.y -= delta*6
			slot.mesh.position += slot.velocity*delta
			slot.mesh.visible = slot.life>0
