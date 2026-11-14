class_name GameUI
extends CanvasLayer
var game: Node3D
var root: Control
var hud: Control
var hud_text: Label
var interact_button: Button
var reload_button: Button
var heal_button: Button
var toast: Label
var toast_timer = 0.0
var extraction_label: Label
var panel: PanelContainer
var footer: HBoxContainer
var content: VBoxContainer
var shelter_tab = "Equipo"
var selected = ""
var map: Minimap
var safe_margin: MarginContainer
var tutorial_background: PanelContainer
var extraction_background: PanelContainer
var tutorial: Label
var damage_flash: ColorRect
var health_bar: ProgressBar
var objective_label: Label
var stealth_button: Button
var details: VBoxContainer
var refuge_identity: Control
var decoy_button: Button
var event_panel: PanelContainer
var event_text: Label
var boss_panel: PanelContainer
var boss_text: Label
var boss_bar: ProgressBar
var stamina_text: Label
var stamina_bar: ProgressBar
var sprint_button: Button
var dodge_button: Button
var calibration: TouchCalibration

static func style(color: Color, border: Color = Color("45525b"), radius: int = 3) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = color
	s.border_color = border
	s.set_border_width_all(1)
	s.set_corner_radius_all(radius)
	s.content_margin_left = 16
	s.content_margin_right = 16
	s.content_margin_top = 12
	s.content_margin_bottom = 12
	return s

func setup(host: Node3D) -> void:
	game = host
	game.controls.pointer_on_button = Callable(self,"pointer_on_button")
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var theme = Theme.new()
	theme.default_font_size = 22 if OS.has_feature("mobile") else 18
	theme.set_color("font_color", "Label", Color("e0e3df"))
	theme.set_color("font_color", "Button", Color("e3e5df"))
	theme.set_stylebox("normal", "Button", style(Color("25333b")))
	theme.set_stylebox("hover", "Button", style(Color("394a52"),Color("b4a17d")))
	theme.set_stylebox("pressed", "Button", style(Color("675a43"),Color("d2b68c")))
	theme.set_stylebox("disabled", "Button", style(Color("1c2930"), Color("35434b")))
	theme.set_color("font_disabled_color", "Button", Color("7b8688"))
	root.theme = theme
	safe_margin = MarginContainer.new()
	safe_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		safe_margin.add_theme_constant_override("margin_" + side, 24)
	safe_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(safe_margin)
	hud = Control.new()
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	safe_margin.add_child(hud)
	var status = PanelContainer.new()
	status.position = Vector2(0,0)
	status.add_theme_stylebox_override("panel",style(Color("17232cdd")))
	hud.add_child(status)
	status.custom_minimum_size = Vector2(360,120)
	var vitals = VBoxContainer.new()
	status.add_child(vitals)
	hud_text = label("",18)
	vitals.add_child(hud_text)
	health_bar = ProgressBar.new()
	health_bar.show_percentage = false
	health_bar.custom_minimum_size.y = 7
	health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	health_bar.add_theme_stylebox_override("background",style(Color("33424a")))
	health_bar.add_theme_stylebox_override("fill",style(Color("98afa0"),Color("98afa0")))
	for part in ["fill","background"]:
		var bar_style = health_bar.get_theme_stylebox(part).duplicate()
		bar_style.content_margin_top = 0
		bar_style.content_margin_bottom = 0
		health_bar.add_theme_stylebox_override(part,bar_style)
	vitals.add_child(health_bar)
	stamina_text = label("RESISTENCIA",12)
	vitals.add_child(stamina_text)
	stamina_bar = ProgressBar.new()
	stamina_bar.show_percentage = false
	stamina_bar.custom_minimum_size.y = 5
	stamina_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for part in ["fill","background"]:
		var energy_style = StyleBoxFlat.new()
		energy_style.bg_color = Color("bb9a66") if part=="fill" else Color("33424a")
		stamina_bar.add_theme_stylebox_override(part,energy_style)
	vitals.add_child(stamina_bar)
	var objective_panel = PanelContainer.new()
	objective_panel.position = Vector2(0,165)
	objective_panel.size = Vector2(365,90)
	objective_panel.add_theme_stylebox_override("panel",style(Color("17232ccc")))
	objective_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(objective_panel)
	objective_label = label("",15)
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_label.custom_minimum_size.x = 330
	objective_panel.add_child(objective_label)
	var top_right = HBoxContainer.new()
	top_right.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	top_right.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	top_right.position = Vector2(-390,0)
	top_right.size = Vector2(390,50)
	hud.add_child(top_right)
	button(top_right,"MOCHILA  [Tab]",func(): game.open_bag())
	button(top_right,"MAPA [M]",func(): game.open_map())
	button(top_right,"II",func(): game.pause_menu())
	map = Minimap.new()
	map.game = game
	map.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	map.position = Vector2(-156,68)
	map.size = Vector2(156,156)
	hud.add_child(map)
	var actions = HBoxContainer.new()
	actions.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	actions.position = Vector2(-456,-280)
	actions.size = Vector2(456,56)
	hud.add_child(actions)
	reload_button = button(actions,"RECARGAR",func(): game.player.reload_weapon())
	heal_button = button(actions,"+  CURAR",func(): game.player.heal())
	interact_button = button(actions,"BUSCAR",func(): game.interact())
	stealth_button = button(hud,"SIGILO [C]",func(): game.player.toggle_crouch())
	stealth_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	stealth_button.position = Vector2(240,-140)
	stealth_button.size = Vector2(185,56)
	decoy_button = button(hud,"SEÑUELO [G]",func(): game.expedition.throw_decoy())
	decoy_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	decoy_button.position = Vector2(240,-224)
	decoy_button.size = Vector2(185,56)
	sprint_button = button(hud,"CORRER [Shift]",func(): game.player.toggle_sprint())
	sprint_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	sprint_button.position = Vector2(445,-140)
	sprint_button.size = Vector2(185,56)
	dodge_button = button(hud,"ESQUIVAR [Espacio]",func(): game.player.dodge())
	dodge_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	dodge_button.position = Vector2(650,-140)
	dodge_button.size = Vector2(190,56)
	dodge_button.add_theme_font_size_override("font_size",20 if OS.has_feature("mobile") else 15)
	event_panel = PanelContainer.new()
	event_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	event_panel.position = Vector2(-150,190)
	event_panel.size = Vector2(340,72)
	event_panel.add_theme_stylebox_override("panel",style(Color("1d373bdc")))
	hud.add_child(event_panel)
	event_text = label("",17)
	event_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	event_panel.add_child(event_text)
	boss_panel = PanelContainer.new()
	boss_panel.position = Vector2(0,270)
	boss_panel.size = Vector2(365,75)
	boss_panel.add_theme_stylebox_override("panel",style(Color("432d28dd"),Color("ad8d71")))
	hud.add_child(boss_panel)
	var boss_info = VBoxContainer.new()
	boss_panel.add_child(boss_info)
	boss_text = label("",17)
	boss_info.add_child(boss_text)
	boss_bar = ProgressBar.new()
	boss_bar.show_percentage = false
	boss_bar.custom_minimum_size.y = 8
	boss_bar.add_theme_stylebox_override("background",style(Color("543f35")))
	boss_bar.add_theme_stylebox_override("fill",style(Color("d29978"),Color("d29978")))
	boss_info.add_child(boss_bar)
	extraction_background = PanelContainer.new()
	extraction_background.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	extraction_background.position = Vector2(-210,104)
	extraction_background.size = Vector2(420,52)
	extraction_background.add_theme_stylebox_override("panel",style(Color("17232ce5")))
	hud.add_child(extraction_background)
	extraction_label = label("",24)
	extraction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	extraction_background.add_child(extraction_label)
	tutorial_background = PanelContainer.new()
	tutorial_background.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	tutorial_background.position = Vector2(-150,20)
	tutorial_background.size = Vector2(340,76)
	tutorial_background.add_theme_stylebox_override("panel",style(Color("17232ce5")))
	hud.add_child(tutorial_background)
	tutorial = label("",17)
	tutorial.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tutorial.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tutorial_background.add_child(tutorial)
	toast = label("",20)
	toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	toast.position = Vector2(-350,-60)
	toast.size = Vector2(700,40)
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(toast)
	damage_flash = ColorRect.new()
	damage_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	damage_flash.color = Color(0.9,0.2,0.1,0)
	damage_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(damage_flash)
	root.resized.connect(adapt_safe_area)
	adapt_safe_area()

func adapt_safe_area() -> void:
	game.controls.clear()
	clear_touch_buttons()
	if OS.has_feature("mobile"):
		var rect = DisplayServer.get_display_safe_area()
		var screen = DisplayServer.screen_get_size()
		var scale = root.size / Vector2(screen)
		safe_margin.add_theme_constant_override("margin_left", maxi(24, int(rect.position.x * scale.x)))
		safe_margin.add_theme_constant_override("margin_right", maxi(24, int((screen.x - rect.end.x) * scale.x)))
		safe_margin.add_theme_constant_override("margin_top", maxi(24, int(rect.position.y * scale.y)))
		safe_margin.add_theme_constant_override("margin_bottom", maxi(24, int((screen.y - rect.end.y) * scale.y)))
		# Joystick input uses the same safe rectangle as the HUD.
		game.controls.position = Vector2(safe_margin.get_theme_constant("margin_left"),safe_margin.get_theme_constant("margin_top"))
		game.controls.size = root.size - game.controls.position - Vector2(safe_margin.get_theme_constant("margin_right"),safe_margin.get_theme_constant("margin_bottom"))

func label(text_value: String, font_size: int = 18) -> Label:
	var node = Label.new()
	node.text = text_value
	node.add_theme_font_size_override("font_size",int(font_size * 1.15) if OS.has_feature("mobile") else font_size)
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return node

func button(parent: Node, text_value: String, action: Callable, disabled_value: bool = false) -> Button:
	var node = TouchActionButton.new()
	node.text = text_value
	node.custom_minimum_size.y = 76 if OS.has_feature("mobile") else 48
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.disabled = disabled_value
	node.pressed.connect(action)
	parent.add_child(node)
	return node

func heading(text_value: String, detail: String = "") -> void:
	content.add_child(label(text_value,30))
	if not detail.is_empty():
		content.add_child(label(detail,16))

func clear_panel() -> void:
	if is_instance_valid(calibration):
		calibration.shutdown()
		calibration.queue_free()
		calibration = null
	if is_instance_valid(panel):
		panel.hide()
		panel.queue_free()
	panel = null
	selected = ""
	details = null
	if is_instance_valid(refuge_identity):
		refuge_identity.hide()
		refuge_identity.queue_free()
		refuge_identity = null

func make_panel(width: float = 680, side: bool = false) -> void:
	clear_panel()
	panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel",style(Color("18252ff5"),Color("687b82"),4))
	if side:
		panel.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
		panel.offset_left = -width - 24
		panel.offset_right = -24
		panel.offset_top = 24
		panel.offset_bottom = -24
	else:
		panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		panel.offset_left = -width / 2
		panel.offset_right = width / 2
		panel.offset_top = -300
		panel.offset_bottom = 300
	root.add_child(panel)
	var inner = VBoxContainer.new()
	panel.add_child(inner)
	var scroll = TouchScroll.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	inner.add_child(scroll)
	footer = HBoxContainer.new()
	inner.add_child(footer)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation",12)
	scroll.add_child(content)

func shelter() -> void:
	hud.visible = false
	make_panel(690,true)
	var p: Dictionary = game.progression.profile
	refuge_identity = PanelContainer.new()
	refuge_identity.position = Vector2(64,110)
	refuge_identity.size = Vector2(430,360)
	refuge_identity.add_theme_stylebox_override("panel",style(Color("16232cee"),Color("697b81"),4))
	refuge_identity.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(refuge_identity)
	var identity = VBoxContainer.new()
	identity.add_theme_constant_override("separation",18)
	refuge_identity.add_child(identity)
	identity.add_child(label("LA LINDE / DÍA 8",16))
	identity.add_child(label("Aquí nadie\nvuelve limpio.",40))
	identity.add_child(label("Nilo firmó las rutas de evacuación. Taro encontró a quienes quedaron fuera. Vera sabe cuánto cuesta mantener con vida a los demás.",19))
	identity.add_child(label("%d regresos · %d/%d páginas encontradas" % [p.extractions,p.journal.size(),Catalog.notes.size()],17))
	var locked = not game.progression.editable()
	heading("PROYECTO CHOSKOV", "EL REFUGIO  /  Linde de Bruma    •    " + str(p.credits) + " fichas")
	content.add_child(label("INCURSIÓN SUSPENDIDA · el equipo y el botín siguen en el bosque. Reanuda para resolverla." if locked else "Vera: «No te pago por ser bueno. Te pago por volver con lo que necesitamos.»",16))
	var tabs = GridContainer.new()
	tabs.columns = 3
	content.add_child(tabs)
	for tab in ["Equipo","Almacén","Misiones","Mejoras","Fabricar","Diario"]:
		button(tabs,tab,func(): shelter_tab = tab; shelter(),tab == shelter_tab)
	match shelter_tab:
		"Equipo":
			var weapon_id: String = p.equipment.get("weapon", "")
			content.add_child(label("EQUIPO LLEVADO",15))
			content.add_child(label(Catalog.items[weapon_id].name if not weapon_id.is_empty() else "Sin arma preparada",24))
			content.add_child(label("Chaleco: " + ("Musgo" if p.equipment.has("armor") else "sin protección") + "   ·   Mochila: " + str(16 if p.equipment.has("pack") else 12) + " ranuras",16))
			button(content,"Preparar suministros del almacén",func(): game.progression.prepare(); shelter(),locked)
			for id in ["pistol","rifle","shotgun","armor","pack"]:
				if p.stash.has(id):
					button(content,"Equipar " + Catalog.items[id].name,func(): game.progression.equip(id); shelter(),locked)
			content.add_child(label("MOCHILA PREPARADA · " + str(Inventory.slots(p.prepared)) + " ranuras",16))
			item_grid(p.prepared,func(id): shelter_item(id,true))
			if not p.equipment.has("weapon") and not p.stash.has("pistol") and not p.stash.has("rifle") and not p.stash.has("shotgun"):
				button(content,"Recibir equipo básico de emergencia · gratis",func(): game.progression.emergency(); shelter(),locked)
			content.add_child(label("Suministros · coste en fichas",16))
			var shop = GridContainer.new()
			shop.columns = 2
			content.add_child(shop)
			for offer in [{"id":"ammo9","n":24},{"id":"bandage","n":2},{"id":"ammo556","n":24},{"id":"ammo20","n":12}]:
				button(shop,str(offer.n) + " " + Catalog.items[offer.id].name + " · " + str(int(Catalog.items[offer.id].price)*offer.n),func(): game.notify("Comprado" if game.progression.purchase(offer.id,offer.n) else "Faltan fichas o espacio"); shelter(),locked)
		"Almacén":
			content.add_child(label("ALMACÉN · " + str(Inventory.slots(p.stash)) + " / " + str(game.progression.capacity()) + " ranuras",20))
			button(content,"Guardar todo en el almacén",func(): game.progression.store_bag(); shelter(),locked or p.prepared.is_empty())
			item_grid(p.stash,func(id): shelter_item(id,false))
		"Misiones":
			for mission in Catalog.missions:
				content.add_child(label(mission.name,23))
				content.add_child(label(mission.description,16))
				var claimed: bool = p.missions.get(mission.id,false)
				if claimed:
					content.add_child(label(mission.get("aftermath",""),17))
				var status: String = "Entregada" if claimed else "Entregar · +" + str(int(mission.reward)) + " fichas"
				if mission.has("crafted"):
					content.add_child(label("Lotes fabricados: %d / %d" % [p.get("crafted",0),mission.crafted],16))
				if mission.has("kills"):
					content.add_child(label("Vigías derrotados: " + str(int(p.kills)) + " / 3",16))
				button(content,status,func(): game.progression.claim(mission); shelter(),locked or claimed or not game.progression.mission_ready(mission))
				if not claimed:
					button(content,"OBJETIVO ACTIVO" if game.progression.tracked().get("id")==mission.id else "Seguir en el mapa",func(): game.progression.track(mission.id); shelter(),game.progression.tracked().get("id")==mission.id)
		"Mejoras":
			content.add_child(label("Almacén nivel " + str(int(p.storage_level)+1),24))
			content.add_child(label("+18 ranuras · 6 chatarras + 100 fichas",16))
			button(content,"Ampliar almacén",func(): game.notify("Almacén ampliado" if game.progression.upgrade("storage") else "Faltan materiales o fichas"); shelter(),locked or p.storage_level >= 2)
			content.add_child(label("Banco de ajuste",24))
			content.add_child(label("Reduce la dispersión un 30 % · 2 circuitos + 150 fichas",16))
			button(content,"Taller desbloqueado" if p.workshop else "Construir taller",func(): game.notify("Taller construido" if game.progression.upgrade("workshop") else "Faltan materiales o fichas"); shelter(),locked or p.workshop)
		"Fabricar":
			content.add_child(label("EL BANCO DE VERA",24))
			content.add_child(label("Transforma materiales del almacén en suministros. Cada lote cuenta para el contrato Nada se desperdicia.",17))
			content.add_child(label("Lotes fabricados: " + str(int(p.get("crafted",0))),16))
			for recipe in Catalog.recipes:
				content.add_child(label(recipe.name,22))
				var ingredients: Array[String] = []
				var result: Array[String] = []
				var enough = true
				for id in recipe.needs:
					ingredients.append("%s %d/%d" % [Catalog.items[id].name,p.stash.get(id,0),recipe.needs[id]])
					enough = enough and p.stash.get(id,0)>=recipe.needs[id]
				for id in recipe.output:
					result.append("%s ×%d" % [Catalog.items[id].name,recipe.output[id]])
				content.add_child(label(" · ".join(ingredients),16))
				button(content,"Fabricar: " + " + ".join(result),func():
					var made = game.progression.craft(recipe.id)
					shelter()
					game.notify("Lote fabricado y guardado" if made else "Faltan materiales, espacio o no se pudo guardar"),locked or not enough)
		"Diario":
			content.add_child(label("ARCHIVO DE LA DESCARGA",24))
			content.add_child(label("El conocimiento permanece aunque caigas. Busca las páginas azules en el mapa.",17))
			for note in Catalog.notes:
				var found = p.journal.has(note.id)
				button(content,note.title if found else "Página sin descubrir · " + note.location,func(): story(note.id),not found)
				if found:
					content.add_child(label(note.author,15))
	var bottom = footer
	button(bottom,"Ajustes",func(): settings_panel())
	button(bottom,"REANUDAR INCURSIÓN" if not p.active.is_empty() else "ENTRAR EN INCURSIÓN  >",func(): game.start_raid())
	content.add_child(label("WASD mover · ratón disparar · E interactuar · R recargar\nH curar · C sigilo · G señuelo · M mapa · Tab mochila",14))

func item_grid(bag: Dictionary, callback: Callable) -> void:
	var grid = GridContainer.new()
	grid.columns = 2 if OS.has_feature("mobile") else 3
	grid.add_theme_constant_override("h_separation",8)
	grid.add_theme_constant_override("v_separation",8)
	content.add_child(grid)
	var ids = bag.keys()
	ids.sort_custom(func(a,b): return str(Catalog.items[a].category)+str(Catalog.items[a].name) < str(Catalog.items[b].category)+str(Catalog.items[b].name))
	for id in ids:
		var quantity: int = bag[id]
		var stack: int = Catalog.items[id].stack
		while quantity > 0:
			var n = mini(quantity,stack)
			var node = button(grid,("* " if game.progression.needed(id) else "") + Catalog.items[id].name + "\n×" + str(n),func(): callback.call(id))
			node.custom_minimum_size = Vector2(175,80 if OS.has_feature("mobile") else 64)
			node.add_theme_font_size_override("font_size",20 if OS.has_feature("mobile") else 15)
			node.add_theme_color_override("font_color",Color(Catalog.items[id].color))
			quantity -= n

func shelter_item(id: String, prepared: bool) -> void:
	var p: Dictionary = game.progression.profile
	var locked = not game.progression.editable()
	show_details(id)
	var row = HBoxContainer.new()
	details.add_child(row)
	if prepared:
		button(row,"Guardar pila",func(): game.progression.move_supply(id,true,mini(p.prepared.get(id,0),Catalog.items[id].stack)); shelter(),locked)
	else:
		button(row,"Llevar pila",func(): game.progression.move_supply(id,false,mini(p.stash.get(id,0),Catalog.items[id].stack)); shelter(),locked)
		if Catalog.items[id].category in ["arma","equipo"]:
			button(row,"Equipar",func(): game.progression.equip(id); shelter(),locked)
		button(row,"Vender uno · " + str(maxi(1,int(Catalog.items[id].price)/2)),func(): game.progression.sell(id); shelter(),locked)

func raid_hud() -> void:
	clear_panel()
	hud.visible = true

func update(delta: float) -> void:
	toast_timer -= delta
	toast.visible = toast_timer > 0
	damage_flash.color.a = move_toward(damage_flash.color.a,0,delta*1.3)
	if game.mode != "raid" or game.player == null:
		return
	var raid: Dictionary = game.raid
	var player: Explorer = game.player
	var w: Dictionary = player.weapon()
	var time_left = maxi(0,600-int(raid.time))
	hud_text.text = "SECTOR 07    ·    %02d:%02d\nSALUD %03d   |   %s  %02d / %02d\nMOCHILA %d/%d    ·    %d fichas de botín" % [time_left / 60,time_left % 60,raid.health,Catalog.items[raid.equipment.weapon].name.get_slice(" ",1).to_upper(),raid.loaded,raid.bag.get(w.ammo,0),Inventory.slots(raid.bag),player.capacity(),game.loot_value()]
	var nearby: Dictionary = game.nearest_interaction()
	interact_button.text = "LEER" if nearby.get("type")=="note" else ("EXTRAER" if nearby.get("type")=="exit" else "BUSCAR")
	if nearby.get("type")=="exit" and nearby.zone.radio and not raid.get("radio_powered",false):
		interact_button.text = "RADIO · 1 BAT."
	reload_button.disabled = player.reload_timer>0 or player.heal_timer>0 or raid.loaded>=w.capacity or raid.bag.get(w.ammo,0)<=0
	heal_button.disabled = player.reload_timer>0 or player.heal_timer>0 or raid.health>=100 or (not raid.bag.has("bandage") and not raid.bag.has("medkit"))
	health_bar.value = raid.health
	stamina_bar.value = player.stamina
	stamina_text.text = "RESISTENCIA %03d%s" % [roundi(player.stamina)," · RECUPERANDO" if player.exhausted else ""]
	sprint_button.text = "CORRER ON" if player.sprint_requested else ("CORRER" if OS.has_feature("mobile") else "CORRER [Shift]")
	sprint_button.modulate = Color("d7b382") if player.sprinting else Color.WHITE
	dodge_button.disabled = player.stamina<25 or player.dodge_cooldown>0 or player.heal_timer>0 or player.reload_timer>0
	dodge_button.text = "ESQUIVA %.1f s" % player.dodge_cooldown if player.dodge_cooldown>0 else ("ESQUIVAR" if OS.has_feature("mobile") else "ESQUIVAR [Espacio]")
	objective_label.text = "OBJETIVO · " + game.progression.objective(raid)
	stealth_button.text = "SIGILO ON [C]" if player.crouched else "SIGILO [C]"
	stealth_button.modulate = Color("c8e4ad") if player.crouched else Color.WHITE
	if nearby.get("type")=="loot" and not nearby.container.get("locked_key","").is_empty():
		interact_button.text = "ABRIR · LLAVE"
	decoy_button.disabled = not raid.bag.has("decoy") or raid.get("decoy_cd",0)>0
	decoy_button.text = "SEÑUELO %d [G]" % raid.bag.get("decoy",0)
	event_text.text = game.expedition.status() if game.expedition!=null else ""
	event_panel.visible = not event_text.text.is_empty()
	boss_panel.visible = false
	for enemy in game.enemies:
		if enemy.kind=="warden" and enemy.alive and enemy.position.distance_to(player.position)<20:
			boss_panel.visible = true
			boss_text.text = "CAPATAZ · ARMADURA · %d / 210" % roundi(enemy.health)
			boss_bar.max_value = 210
			boss_bar.value = enemy.health
	interact_button.disabled = nearby.is_empty()
	extraction_label.text = "EXTRAYENDO · %.1f s" % game.extract_timer if game.extract_timer > 0 else ("Recargando · %.1f s" % player.reload_timer if player.reload_timer>0 else ("Curando · %.1f s" % player.heal_timer if player.heal_timer>0 else ""))
	tutorial.text = "" if game.progression.profile.tutorial or raid.time>25 else ("Busca la caja dorada junto al campamento.\nToca BUSCAR o pulsa E; extrae para conservar el botín." if raid.time>6 else "Izquierda: moverse. Derecha: apuntar y disparar.\nCORRER gasta resistencia; ESQUIVAR cuesta 25.")
	tutorial_background.visible = not tutorial.text.is_empty() and extraction_label.text.is_empty() and not event_panel.visible
	extraction_background.visible = not extraction_label.text.is_empty()
	for c in game.world.containers:
		c.icon.visible = not c.items.is_empty()
	game.world.update_exits(raid.get("radio_powered",false))
	for note in game.world.notes:
		note.icon.visible = not game.progression.profile.journal.has(note.id)
	map.queue_redraw()

func bag() -> void:
	make_panel(730)
	heading("MOCHILA", "ACCIÓN PAUSADA · " + str(Inventory.slots(game.raid.bag)) + " / " + str(game.player.capacity()) + " ranuras")
	content.add_child(label("Equipo: " + Catalog.items[game.raid.equipment.weapon].name + (" · Chaleco Musgo" if game.raid.equipment.has("armor") else ""),17))
	item_grid(game.raid.bag,func(id): bag_item(id))
	button(footer,"Volver a la incursión",func(): game.resume())

func bag_item(id: String) -> void:
	show_details(id)
	if Catalog.weapons.has(id):
		var current: Dictionary = game.player.weapon()
		var other: Dictionary = Catalog.weapons[id]
		details.add_child(label("Daño %d > %d · Cargador %d > %d · Alcance %d > %d m" % [current.damage*current.get("pellets",1),other.damage*other.get("pellets",1),current.capacity,other.capacity,current.range,other.range],16))
	var row = HBoxContainer.new()
	details.add_child(row)
	if id=="decoy":
		button(row,"Lanzar y continuar",func(): game.resume(); game.expedition.throw_decoy())
	if Catalog.items[id].category == "curación":
		button(row,"Usar y volver",func(): game.player.heal(id); game.resume())
	if Catalog.items[id].category in ["arma","equipo"]:
		button(row,"Equipar",func(): game.equip_raid(id); bag())
	button(row,"Soltar uno",func():
		if Inventory.remove(game.raid.bag,id,1):
			game.world.add_container(Vector2(game.player.position.x+0.8,game.player.position.z),{id:1},"Objeto soltado")
		game.checkpoint(); bag())

func loot(container: Dictionary) -> void:
	make_panel(690)
	heading(container.name,"ACCIÓN PAUSADA · toca una pila para recogerla")
	content.add_child(label("Mochila: " + str(Inventory.slots(game.raid.bag)) + "/" + str(game.player.capacity()) + " ranuras",18))
	item_grid(container.items,func(id):
		var amount = Inventory.transfer(container.items,game.raid.bag,id,mini(container.items.get(id,0),Catalog.items[id].stack),game.player.capacity())
		game.notify("Mochila llena" if amount==0 else "+" + str(amount) + " " + Catalog.items[id].name)
		if amount>0:
			game.sound.play("loot")
		game.checkpoint(); loot(container))
	button(content,"Recoger todo lo que quepa",func():
		for id in container.items.keys():
			Inventory.transfer(container.items,game.raid.bag,id,container.items[id],game.player.capacity())
		game.sound.play("loot"); game.checkpoint(); loot(container))
	button(footer,"Cerrar y continuar",func(): game.resume())

func pause_panel(reason: String = "") -> void:
	make_panel(600)
	heading("UN RESPIRO", "ACCIÓN PAUSADA" + (" · " + reason if not reason.is_empty() else ""))
	content.add_child(label("Tu incursión se guarda. El botín sigue en riesgo.",18))
	button(content,"Continuar",func(): game.resume())
	button(content,"Ajustes",func(): settings_panel())
	button(content,"Suspender incursión · botín todavía en riesgo",func(): game.checkpoint(); game.show_shelter())

func settings_panel() -> void:
	make_panel(650)
	heading("AJUSTES", "Controles y rendimiento")
	button(content,"Probar controles táctiles",func(): touch_calibration())
	var settings: Dictionary = game.progression.profile.settings
	button(content,"Ayuda de apuntado: " + ("activada" if settings.assist else "desactivada"),func(): settings.assist=not settings.assist; game.save_settings(); settings_panel())
	button(content,"Zona táctil de movimiento: " + ("adaptable" if settings.get("adaptive_stick",true) else "fija"),func(): settings.adaptive_stick=not settings.get("adaptive_stick",true); game.save_settings(); settings_panel())
	button(content,"Impacto de cámara: " + ("activado" if settings.get("shake",true) else "desactivado"),func(): settings.shake=not settings.get("shake",true); game.save_settings(); settings_panel())
	for cfg in [{"key":"sensitivity","name":"Sensibilidad","min":0.5,"max":1.8},{"key":"control_size","name":"Tamaño de joysticks","min":0.75,"max":1.3}]:
		content.add_child(label(cfg.name,18))
		var slider = HSlider.new()
		slider.min_value = cfg.min
		slider.max_value = cfg.max
		slider.step = 0.05
		slider.value = settings[cfg.key]
		slider.custom_minimum_size.y = 44
		slider.value_changed.connect(func(value): settings[cfg.key]=value; game.save_settings())
		content.add_child(slider)
		var adjustment = HBoxContainer.new()
		content.add_child(adjustment)
		button(adjustment,"-",func(): settings[cfg.key]=maxf(cfg.min,settings[cfg.key]-0.1); game.save_settings(); settings_panel())
		adjustment.add_child(label("%.2f" % settings[cfg.key]))
		button(adjustment,"+",func(): settings[cfg.key]=minf(cfg.max,settings[cfg.key]+0.1); game.save_settings(); settings_panel())
	var fps = HBoxContainer.new()
	content.add_child(fps)
	button(fps,"30 FPS",func(): settings.fps=30; game.save_settings())
	button(fps,"60 FPS",func(): settings.fps=60; game.save_settings())
	var quality = HBoxContainer.new()
	content.add_child(quality)
	button(quality,"Calidad baja · sin sombras",func(): settings.quality=0; game.save_settings())
	button(quality,"Calidad media",func(): settings.quality=1; game.save_settings())
	button(content,"Sonidos: " + ("activados" if settings.sound else "desactivados"),func(): settings.sound=not settings.sound; game.save_settings(); settings_panel())
	button(footer,"Volver",func():
		if game.mode=="shelter":
			shelter()
		else:
			pause_panel())

func result(success: bool, value: int, kills: int, reason: String) -> void:
	hud.visible = false
	make_panel(620)
	heading("HAS SALIDO CON VIDA" if success else "NO HUBO RESCATE", "EXTRACCIÓN COMPLETADA" if success else reason)
	content.add_child(label("Has conservado tu mochila y equipo.\nGuarda el botín en el almacén antes de entregar misiones." if success else "Has perdido tu equipo y mochila.\nEl almacén y las mejoras del refugio siguen a salvo.",20))
	content.add_child(label("Valor transportado: " + str(value) + " fichas\nVigías derrotados: " + str(kills) + ("\nPrima de extracción: +35 fichas" if success else ""),20))
	if success:
		button(footer,"Guardar botín en almacén",func():
			if game.progression.store_bag():
				game.show_shelter()
				game.notify("Botín guardado" if game.progression.profile.prepared.is_empty() else "Almacén lleno · parte sigue en la mochila")
			else:
				game.notify("No se pudo guardar"))
	button(footer,"VOLVER AL REFUGIO  >",func(): game.show_shelter())

func clear_touch_buttons() -> void:
	for child in root.find_children("*","Button",true,false):
		if child is TouchActionButton:
			child.clear_touch()

func show_details(id: String) -> void:
	if is_instance_valid(details):
		details.hide()
		details.queue_free()
	details = VBoxContainer.new()
	details.add_theme_constant_override("separation",8)
	content.add_child(details)
	details.add_child(label(Catalog.items[id].name,22))
	details.add_child(label(Catalog.items[id].description,17))
	if game.progression.needed(id):
		details.add_child(label("* Material de un contrato pendiente · extrae y guárdalo para entregarlo.",16))
	# Reveal the replacement card without forcing the user to search below the grid.
	var scroll = content.get_parent()
	scroll.set_deferred("scroll_vertical",100000)

func story(id: String) -> void:
	var note: Dictionary = {}
	for entry in Catalog.notes:
		if entry.id == id:
			note = entry
	if note.is_empty() or not game.progression.profile.journal.has(id):
		return
	make_panel(700)
	heading(note.title,note.author + " · " + note.location)
	content.add_child(label(note.text,23))
	content.add_child(label("ANOTACIÓN DE NILO",16))
	content.add_child(label(note.hint,19))
	content.add_child(label("Página conservada en el diario del refugio.",16))
	button(footer,"Continuar",func(): game.resume() if game.mode=="raid" else shelter())

func route_map() -> void:
	make_panel(790)
	heading("RUTAS DE LA LINDE","ACCIÓN PAUSADA · elige una ruta antes de avanzar")
	var row = HBoxContainer.new()
	content.add_child(row)
	var route = Minimap.new()
	route.game = game
	route.custom_minimum_size = Vector2(370,370)
	route.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(route)
	var legend = VBoxContainer.new()
	legend.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	legend.add_theme_constant_override("separation",14)
	row.add_child(legend)
	legend.add_child(label(game.progression.objective(game.raid),20))
	legend.add_child(label("- Verde: extracción disponible\n- Ámbar: torre sin energía\n• Dorado: suministros\n- Azul: página del diario\n- Dorado: zona del objetivo\n- Rojo: puesto del capataz\n- Azul brillante: entrega",17))
	legend.add_child(label("SUR · Siempre disponible\nNORTE · 1 batería por incursión\nActivar la radio no abrevia la extracción.",17))
	legend.add_child(label("Llave: puesto forestal > reserva norte\nSeñuelos: botón G o mochila",16))
	legend.add_child(label("Quedan %02d:%02d antes de la Bruma" % [maxi(0,600-int(game.raid.time))/60,maxi(0,600-int(game.raid.time))%60],17))
	button(footer,"Continuar la incursión",func(): game.resume())

func pending_result(success: bool,reason: String) -> void:
	hud.visible = false
	make_panel(620)
	heading("RESULTADO PENDIENTE","No se pudo escribir el guardado")
	content.add_child(label("Tu incursión está pausada. Libera espacio y vuelve a guardar para resolver el resultado una sola vez.",20))
	button(footer,"Reintentar guardado",func(): game.finish_raid(success,reason))

func pointer_on_button(point: Vector2) -> bool:
	for node in root.find_children("*","Button",true,false):
		if node is TouchActionButton and node.accepts_point(point):
			return true
	return false

func visible_buttons() -> Array:
	var buttons: Array = []
	for node in root.find_children("*","Button",true,false):
		if node.is_visible_in_tree():
			var rect = node.get_global_rect()
			buttons.append({"text":node.text,"disabled":node.disabled,"rect":[rect.position.x,rect.position.y,rect.size.x,rect.size.y]})
	return buttons

func touch_calibration() -> void:
	game.set_paused(true)
	clear_panel()
	calibration = TouchCalibration.new()
	root.add_child(calibration)
	calibration.configure(game)
