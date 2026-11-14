class_name Art
extends RefCounted
static var materials: Dictionary = {}
static var bevel_mesh: ArrayMesh

static func material(color: Color, emission: bool = false) -> StandardMaterial3D:
	var key = str(color) + str(emission)
	if materials.has(key):
		return materials[key]
	var m = StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.95
	if emission:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = 0.65
	materials[key] = m
	return m

static func box(parent: Node3D, position: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh = BoxMesh.new()
	mesh.size = size
	return instance(parent, mesh, position, color)

static func sphere(parent: Node3D, position: Vector3, scale_value: Vector3, color: Color) -> MeshInstance3D:
	var mesh = SphereMesh.new()
	mesh.radial_segments = 10
	mesh.rings = 5
	var node = instance(parent, mesh, position, color)
	node.scale = scale_value
	return node

static func cylinder(parent: Node3D, position: Vector3, radius: float, height: float, color: Color, cone: bool = false) -> MeshInstance3D:
	var mesh = CylinderMesh.new()
	mesh.top_radius = 0.0 if cone else radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	return instance(parent, mesh, position, color)

static func instance(parent: Node3D, mesh: Mesh, position: Vector3, color: Color) -> MeshInstance3D:
	var node = MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material(color)
	node.position = position
	parent.add_child(node)
	return node

# Original articulated field gear. Small exposed ears retain the lirón identity.
static func animal(parent: Node3D, color: Color, player: bool = false) -> Node3D:
	var root = Node3D.new()
	parent.add_child(root)
	var coat = color.darkened(0.3)
	bevel_box(root,Vector3(0,1.08,0),Vector3(.66,.76,.4),coat)
	bevel_box(root,Vector3(0,.77,.02),Vector3(.7,.25,.44),coat.darkened(.1))
	bevel_box(root,Vector3(0,1.23,-.23),Vector3(.52,.42,.12),Color("353c3c"))
	for x in [-.16,.16]:
		bevel_box(root,Vector3(x,1.08,-.32),Vector3(.13,.21,.13),Color("656655"))
	bevel_box(root,Vector3(0,.78,-.24),Vector3(.65,.09,.08),Color("22282b"))
	sphere(root,Vector3(0,1.69,.015),Vector3(.74,.73,.65),coat.darkened(.15))
	sphere(root,Vector3(0,1.62,-.18),Vector3(.52,.43,.35),Color("948877"))
	for x in [-.29,.29]:
		sphere(root,Vector3(x,1.94,.02),Vector3(.16,.23,.12),Color("766a5a"))
	bevel_box(root,Vector3(0,1.72,-.365),Vector3(.54,.14,.055),Color("171d22"))
	for x in [-.145,.145]:
		bevel_box(root,Vector3(x,1.73,-.4),Vector3(.19,.095,.035),Color("ada67e") if player else Color("88796a"))
	bevel_box(root,Vector3(0,1.51,-.31),Vector3(.4,.22,.16),Color("3b4242"))
	for x in [-.22,.22]:
		var leg = Node3D.new()
		leg.name = "LegLeft" if x<0 else "LegRight"
		leg.position = Vector3(x,.72,0)
		root.add_child(leg)
		bevel_box(leg,Vector3(0,-.15,0),Vector3(.24,.32,.26),coat)
		var knee = Node3D.new()
		knee.name = "Knee"
		knee.position = Vector3(0,-.3,0)
		leg.add_child(knee)
		bevel_box(knee,Vector3(0,-.13,0),Vector3(.21,.3,.23),coat.darkened(.06))
		bevel_box(knee,Vector3(0,-.02,-.14),Vector3(.25,.18,.09),Color("4a4f4c"))
		bevel_box(knee,Vector3(0,-.29,-.09),Vector3(.28,.22,.44),Color("20282b"))
		batch_world(knee,[])
		batch_world(leg,[knee])
	for x in [-.39,.39]:
		var arm = Node3D.new()
		arm.name = "ArmLeft" if x<0 else "ArmRight"
		arm.position = Vector3(x,1.36,0)
		root.add_child(arm)
		bevel_box(arm,Vector3(0,-.21,-.05),Vector3(.23,.44,.24),coat)
		var elbow = Node3D.new()
		elbow.name = "Elbow"
		elbow.position = Vector3(0,-.36,-.12)
		arm.add_child(elbow)
		bevel_box(elbow,Vector3(0,0,-.14),Vector3(.2,.2,.32),coat)
		bevel_box(elbow,Vector3(0,0,-.35),Vector3(.18,.17,.18),Color("22292b"))
		batch_world(elbow,[])
		batch_world(arm,[elbow])
	bevel_box(root,Vector3(0,1.11,.35),Vector3(.57,.7,.32),Color("4e5348"))
	for x in [-.25,.25]:
		bevel_box(root,Vector3(x,1.26,.06),Vector3(.075,.54,.56),Color("272f2e"))
	var gun = Node3D.new()
	gun.position = Vector3(.12,1.12,-.62)
	root.add_child(gun)
	bevel_box(gun,Vector3.ZERO,Vector3(.105,.15,.65),Color("1d2429"))
	gun.name = "Weapon"
	var barrel = cylinder(gun,Vector3(0,0,-.37),.037,.24,Color("252d30"))
	barrel.rotation.x = PI/2
	bevel_box(gun,Vector3(0,.075,.1),Vector3(.045,.075,.055),Color("76776a"))
	bevel_box(gun,Vector3(0,.08,-.02),Vector3(.06,.06,.22),Color("626762"))
	bevel_box(gun,Vector3(0,-.13,.12),Vector3(.08,.17,.13),Color("353b3a"))
	bevel_box(root,Vector3(-.25,1.38,-.24),Vector3(.08,.06,.025),Color("c5b899") if player else Color("8e4433"))
	batch_world(root,[root.get_node("LegLeft"),root.get_node("LegRight"),root.get_node("ArmLeft"),root.get_node("ArmRight"),gun])
	return root

static func animate(root: Node3D, phase: float, speed: float, delta: float, crouched: bool = false, dodging: bool = false, local_motion: Vector3 = Vector3.ZERO, pose: String = "idle", reaction: float = 0.0) -> void:
	var clock = float(root.get_meta("animation_clock",0.0))+delta
	root.set_meta("animation_clock",clock)
	var amplitude = clampf(speed/6.7,0,1)*.65
	var direction = atan2(-local_motion.x,-local_motion.z) if local_motion.length()>.2 else 0.0
	# Hips follow travel while the upper body keeps independent weapon aim.
	if absf(direction)>PI/2:
		direction = wrapf(direction+PI,-PI,PI)
	for pair in [["LegLeft",1.0],["LegRight",-1.0]]:
		var limb = root.get_node(pair[0])
		var swing = sin(phase)*pair[1]
		limb.rotation.x = swing*amplitude*(.65 if crouched else 1.0)-(.2 if crouched else 0.0)
		limb.rotation.y = lerp_angle(limb.rotation.y,direction*.65,1-exp(-delta*12))
		limb.get_node("Knee").rotation.x = maxf(0,-swing)*amplitude*.9+(.45 if crouched else 0.0)
	for pair in [["ArmLeft",-1.0],["ArmRight",1.0]]:
		var arm = root.get_node(pair[0])
		arm.rotation.x = sin(phase)*amplitude*.12*pair[1]
		arm.rotation.z = 0
		arm.get_node("Elbow").rotation.x = 0
	if pose=="reload":
		root.get_node("ArmLeft").rotation.z = -.38
		root.get_node("ArmLeft/Elbow").rotation.x = .35+.3*sin(clock*12)
	elif pose=="heal":
		root.get_node("ArmLeft").rotation.x = -.5
		root.get_node("ArmRight").rotation.x = -.4
		root.get_node("ArmLeft/Elbow").rotation.x = -.4
	var gun = root.get_node("Weapon")
	gun.rotation.z = lerpf(gun.rotation.z,.32 if pose=="reload" else 0.0,1-exp(-delta*16))
	root.scale.y = lerpf(root.scale.y,float(root.get_meta("height_scale",1.0))*(.8 if crouched else 1.0),1-exp(-delta*15))
	root.position.y = absf(sin(phase))*amplitude*.045+sin(clock*2.1)*.009
	root.rotation.x = lerpf(root.rotation.x,-.4 if dodging else (-.1 if speed>5 else 0.0),1-exp(-delta*16))
	root.rotation.z = lerpf(root.rotation.z,clampf(local_motion.x*.014,-.09,.09)+sin(clock*42)*reaction*.75,1-exp(-delta*18))

# A shared beveled cube catches edge light without a high polygon character mesh.
static func bevel_box(parent: Node3D, position: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	if bevel_mesh==null:
		var surface = SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		var cut = .42
		for axis in 3:
			for sign_value in [-1.0,1.0]:
				var n = Vector3.ZERO
				n[axis] = sign_value
				var vertices: Array[Vector3] = []
				for pair in [[-1,-1],[1,-1],[1,1],[-1,1]]:
					var v = n*.5
					v[(axis+1)%3] = pair[0]*cut
					v[(axis+2)%3] = pair[1]*cut
					vertices.append(v)
				bevel_face(surface,vertices,n)
		for axis in 3:
			for a_sign in [-1.0,1.0]:
				for b_sign in [-1.0,1.0]:
					var a_axis = (axis+1)%3
					var b_axis = (axis+2)%3
					var n = Vector3.ZERO
					n[a_axis] = a_sign;n[b_axis] = b_sign
					var vertices: Array[Vector3] = []
					for pair in [[-cut,true],[cut,true],[cut,false],[-cut,false]]:
						var v = Vector3.ZERO
						v[axis] = pair[0]
						v[a_axis] = a_sign*(.5 if pair[1] else cut)
						v[b_axis] = b_sign*(cut if pair[1] else .5)
						vertices.append(v)
					bevel_face(surface,vertices,n.normalized())
		for x in [-1,1]:
			for y in [-1,1]:
				for z in [-1,1]:
					bevel_face(surface,[Vector3(x*.5,y*cut,z*cut),Vector3(x*cut,y*.5,z*cut),Vector3(x*cut,y*cut,z*.5)],Vector3(x,y,z).normalized())
		bevel_mesh = surface.commit()
	var node = instance(parent,bevel_mesh,position,color)
	node.scale = size
	return node

static func bevel_face(surface: SurfaceTool, points: Array, normal: Vector3) -> void:
	for i in range(1,points.size()-1):
		var triangle = [points[0],points[i],points[i+1]]
		if (triangle[1]-triangle[0]).cross(triangle[2]-triangle[0]).dot(normal)>0:
			triangle.reverse()
		for point in triangle:
			surface.set_normal(normal)
			surface.add_vertex(point)

static func surface(color: Color, scale_value: float = .4) -> StandardMaterial3D:
	var key = "surface"+str(color)+str(scale_value)
	if materials.has(key):
		return materials[key]
	var noise = FastNoiseLite.new()
	noise.seed = 716
	noise.frequency = .075
	noise.fractal_octaves = 4
	var ramp = Gradient.new()
	ramp.colors = PackedColorArray([color.darkened(.12),color.lightened(.05)])
	var texture = NoiseTexture2D.new()
	texture.width = 256
	texture.height = 256
	texture.noise = noise
	texture.color_ramp = ramp
	texture.seamless = true
	var m = StandardMaterial3D.new()
	m.albedo_texture = texture
	m.roughness = .88
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE*scale_value
	materials[key] = m
	return m

static func label(parent: Node3D, text_value: String, position: Vector3, color: Color, size: int = 40) -> Label3D:
	var node = Label3D.new()
	node.text = text_value
	node.position = position
	node.font_size = size
	node.pixel_size = 0.012
	node.modulate = color
	node.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	node.no_depth_test = false
	node.outline_size = 6
	parent.add_child(node)
	return node

# Merge immutable scenery into material/shape batches. Collision bodies remain separate.
static func batch_world(parent: Node3D, excluded: Array) -> void:
	var groups: Dictionary = {}
	var stack: Array = parent.get_children()
	while not stack.is_empty():
		var node = stack.pop_back()
		if node in excluded:
			continue
		stack.append_array(node.get_children())
		if not node is MeshInstance3D or not node.visible:
			continue
		var common: Mesh
		var size_value: Vector3
		var type_value: String
		if node.mesh is BoxMesh:
			common = BoxMesh.new()
			common.size = Vector3.ONE
			size_value = node.mesh.size
			type_value = "box"
		elif node.mesh is CylinderMesh:
			common = CylinderMesh.new()
			common.bottom_radius = 1
			common.top_radius = 0 if node.mesh.top_radius==0 else 1
			common.height = 1
			common.radial_segments = 12
			size_value = Vector3(node.mesh.bottom_radius,node.mesh.height,node.mesh.bottom_radius)
			type_value = "cone" if node.mesh.top_radius==0 else "cylinder"
		elif node.mesh is ArrayMesh:
			common = node.mesh
			size_value = Vector3.ONE
			type_value = "custom"+str(node.mesh.get_instance_id())
		elif node.mesh is SphereMesh:
			common = node.mesh
			size_value = Vector3.ONE
			type_value = "sphere"
		else:
			continue
		var key: String = type_value + str(node.material_override.get_instance_id())
		if not groups.has(key):
			groups[key] = {"mesh":common,"material":node.material_override,"transforms":[]}
		var transform: Transform3D = parent.global_transform.affine_inverse() * node.global_transform
		transform.basis = transform.basis.scaled_local(size_value)
		groups[key].transforms.append(transform)
		node.get_parent().remove_child(node)
		node.queue_free()
	for group in groups.values():
		var multimesh = MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.mesh = group.mesh
		multimesh.instance_count = group.transforms.size()
		for i in group.transforms.size():
			multimesh.set_instance_transform(i,group.transforms[i])
		var instance = MultiMeshInstance3D.new()
		instance.multimesh = multimesh
		instance.material_override = group.material
		parent.add_child(instance)

static func concrete(color: Color = Color.WHITE, texture_scale: float = .14) -> StandardMaterial3D:
	var key = "concrete"+str(color)+str(texture_scale)
	if materials.has(key):
		return materials[key]
	var m = StandardMaterial3D.new()
	m.albedo_texture = load("res://assets/concrete-v05.png")
	m.albedo_color = color
	m.roughness = .84
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE*texture_scale
	materials[key] = m
	return m

static func wreck_van(parent: Node3D, p: Vector3) -> Node3D:
	var root = Node3D.new()
	parent.add_child(root)
	root.position = p
	bevel_box(root,Vector3(0,.9,0),Vector3(1.8,1.25,3.5),Color("59686b"))
	bevel_box(root,Vector3(0,1.68,.15),Vector3(1.7,.55,2.4),Color("4b5b60"))
	bevel_box(root,Vector3(0,1.62,-1.22),Vector3(1.45,.45,.07),Color("24373d"))
	bevel_box(root,Vector3(0,.48,-1.8),Vector3(1.9,.21,.18),Color("2e3b3e"))
	for x in [-.94,.94]:
		for z in [-1.08,1.13]:
			var wheel = cylinder(root,Vector3(x,.4,z),.4,.2,Color("252d30"))
			wheel.rotation.z = PI/2
			var hub = cylinder(root,Vector3(x*1.12,.4,z),.17,.025,Color("70746d"))
			hub.rotation.z = PI/2
		bevel_box(root,Vector3(x*.97,1.58,.18),Vector3(.035,.41,1.9),Color("24373d"))
		bevel_box(root,Vector3(x*.98,1.04,-.24),Vector3(.035,.04,2.1),Color("b4a078"))
		bevel_box(root,Vector3(x*.64,.86,-1.77),Vector3(.26,.19,.04),Color("c2b899"))
	for x in [-.22,.22]:
		bevel_box(root,Vector3(x,.76,-1.8),Vector3(.1,.3,.04),Color("394347"))
	bevel_box(root,Vector3(-.55,1.17,-1.38),Vector3(.65,.04,.3),Color("77624d"))
	return root
