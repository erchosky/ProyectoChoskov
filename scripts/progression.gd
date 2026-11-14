class_name Progression
extends RefCounted
var profile: Dictionary
var store: SaveStore

func _init(save: SaveStore) -> void:
	store = save
	profile = store.load_profile()

func commit(before: Dictionary) -> bool:
	if persist():
		return true
	profile = before
	return false

func editable() -> bool:
	return profile.active.is_empty()

func capacity() -> int:
	return 36 + 18 * int(profile.storage_level)

func persist() -> bool:
	return store.write(profile)

func emergency() -> bool:
	var before = profile.duplicate(true)
	if not profile.active.is_empty() or profile.equipment.has("weapon"):
		return false
	# Available only without a ready weapon or a stored one.
	if profile.stash.has("pistol") or profile.stash.has("rifle") or profile.stash.has("shotgun"):
		return false
	profile.equipment.weapon = "pistol"
	var cap = 16 if profile.equipment.has("pack") else 12
	Inventory.add(profile.prepared, "ammo9", 24, cap)
	Inventory.add(profile.prepared, "bandage", 1, cap)
	return commit(before)

func equip(id: String) -> bool:
	if not Catalog.items.has(id):
		return false
	if not editable():
		return false
	var before = profile.duplicate(true)
	var category: String = Catalog.items[id].category
	if not category in ["arma", "equipo"]:
		return false
	var slot = "weapon" if category == "arma" else id
	var source: Dictionary = profile.stash
	if source.get(id, 0) < 1:
		return false
	var previous: String = profile.equipment.get(slot, "")
	var trial: Dictionary = source.duplicate(true)
	Inventory.remove(trial, id, 1)
	if not previous.is_empty() and Inventory.add(trial, previous, 1, capacity()) != 1:
		return false
	if slot == "weapon" and not previous.is_empty():
		var rounds: int = profile.equipment.get("loaded",0)
		var ammo: String = Catalog.weapons[previous].ammo
		if Inventory.add(trial,ammo,rounds,capacity()) != rounds:
			return false
		profile.equipment.erase("loaded")
	profile.stash = trial
	profile.equipment[slot] = id
	return commit(before)

func prepare() -> void:
	if not editable():
		return
	var before = profile.duplicate(true)
	if not profile.equipment.has("weapon"):
		if profile.stash.has("pistol"):
			equip("pistol")
		elif profile.stash.has("rifle"):
			equip("rifle")
		elif profile.stash.has("shotgun"):
			equip("shotgun")
		else:
			emergency()
	var cap = 16 if profile.equipment.has("pack") else 12
	var weapon: String = profile.equipment.get("weapon", "pistol")
	var ammo: String = Catalog.weapons[weapon].ammo
	Inventory.transfer(profile.stash, profile.prepared, ammo, maxi(0, 36 - int(profile.prepared.get(ammo, 0))), cap)
	Inventory.transfer(profile.stash, profile.prepared, "bandage", maxi(0, 2 - int(profile.prepared.get("bandage", 0))), cap)
	if profile.prepared.get(ammo, 0) == 0 and profile.equipment.get("loaded",0) == 0 and profile.credits < int(Catalog.items[ammo].price)*12:
		Inventory.add(profile.prepared, ammo, 12, cap)
	commit(before)

func purchase(id: String, quantity: int) -> bool:
	if not editable():
		return false
	var before = profile.duplicate(true)
	if quantity <= 0 or quantity > 10000 or not Catalog.items.has(id):
		return false
	var cost = int(Catalog.items[id].price) * quantity
	if profile.credits < cost or Inventory.room(profile.stash, id, quantity, capacity()) < quantity:
		return false
	profile.credits -= cost
	Inventory.add(profile.stash, id, quantity, capacity())
	return commit(before)

func mission_ready(mission: Dictionary) -> bool:
	if mission.has("crafted") and int(profile.get("crafted",0))<int(mission.crafted):
		return false
	if profile.missions.get(mission.id, false):
		return false
	if mission.has("kills") and int(profile.kills) < int(mission.kills):
		return false
	for id in mission.get("needs", {}):
		if profile.stash.get(id, 0) < mission.needs[id]:
			return false
	return true

func claim(mission: Dictionary) -> bool:
	if not editable():
		return false
	var before = profile.duplicate(true)
	if not mission_ready(mission):
		return false
	for id in mission.get("needs", {}):
		Inventory.remove(profile.stash, id, mission.needs[id])
	profile.missions[mission.id] = true
	profile.credits += int(mission.reward)
	return commit(before)

func upgrade(kind: String) -> bool:
	if kind not in ["storage", "workshop"]:
		return false
	if not editable():
		return false
	var before = profile.duplicate(true)
	if kind == "storage":
		if profile.storage_level >= 2 or profile.credits < 100 or profile.stash.get("scrap", 0) < 6:
			return false
		Inventory.remove(profile.stash, "scrap", 6)
		profile.credits -= 100
		profile.storage_level += 1
	else:
		if profile.workshop or profile.credits < 150 or profile.stash.get("circuit", 0) < 2:
			return false
		Inventory.remove(profile.stash, "circuit", 2)
		profile.credits -= 150
		profile.workshop = true
	return commit(before)

func begin(seed_value: int) -> Dictionary:
	if not profile.active.is_empty():
		return profile.active
	prepare()
	if not profile.equipment.has("weapon"):
		return {}
	var before = profile.duplicate(true)
	var equipment: Dictionary = profile.equipment.duplicate(true)
	var bag: Dictionary = profile.prepared.duplicate(true)
	var weapon: Dictionary = Catalog.weapons[equipment.weapon]
	var magazine: int = equipment.get("loaded", 0)
	equipment.erase("loaded")
	var supplied = mini(int(weapon.capacity) - magazine, int(bag.get(weapon.ammo, 0)))
	Inventory.remove(bag, weapon.ammo, supplied)
	var loaded = magazine + supplied
	var raid = {"id": str(Time.get_unix_time_from_system()) + "-" + str(seed_value), "seed": seed_value, "equipment": equipment, "bag": bag, "loaded": loaded, "health": 100.0, "position": [-24.0, 22.0], "aim": [0.0, -1.0], "time": 0.0, "kills": 0, "enemies": [], "containers": [], "reload": 0.0, "heal": 0.0, "heal_item": "", "result": "", "radio_powered": false, "crouched": false}
	profile.equipment = {}
	profile.prepared = {}
	profile.active = raid
	profile.raids += 1
	return raid if commit(before) else {}

func finish(success: bool) -> bool:
	var before = profile.duplicate(true)
	var raid: Dictionary = profile.active
	if raid.is_empty() or raid.id in profile.processed:
		return false
	# One transaction: rewards, lost equipment and processed ID in a single file.
	profile.kills += int(raid.kills)
	if success:
		profile.prepared = raid.bag.duplicate(true)
		profile.equipment = raid.equipment.duplicate(true)
		profile.equipment.loaded = raid.loaded
		profile.extractions += 1
		profile.credits += 35
	profile.processed.append(raid.id)
	profile.active = {}
	return commit(before)

func move_supply(id: String, to_stash: bool, amount: int) -> int:
	if not editable() or not Catalog.items.has(id) or amount <= 0:
		return 0
	var before = profile.duplicate(true)
	var source: Dictionary = profile.prepared if to_stash else profile.stash
	var target: Dictionary = profile.stash if to_stash else profile.prepared
	var cap = capacity() if to_stash else (16 if profile.equipment.has("pack") else 12)
	var moved = Inventory.transfer(source, target, id, amount, cap)
	return moved if commit(before) else 0

func store_bag() -> bool:
	if not editable():
		return false
	var before = profile.duplicate(true)
	for id in profile.prepared.keys():
		Inventory.transfer(profile.prepared,profile.stash,id,profile.prepared[id],capacity())
	return commit(before)

func sell(id: String) -> bool:
	if not editable() or not Catalog.items.has(id):
		return false
	var before = profile.duplicate(true)
	if not Inventory.remove(profile.stash,id,1):
		return false
	profile.credits += maxi(1,int(Catalog.items[id].price)/2)
	return commit(before)

func discover(id: String) -> bool:
	if profile.journal.has(id) or not Catalog.notes.any(func(note): return note.id == id):
		return false
	var before = profile.duplicate(true)
	profile.journal[id] = true
	return commit(before)

func track(id: String) -> bool:
	if not Catalog.missions.any(func(mission): return mission.id == id):
		return false
	var before = profile.duplicate(true)
	profile.tracked_mission = id
	return commit(before)

func tracked() -> Dictionary:
	for mission in Catalog.missions:
		if mission.id == profile.tracked_mission and not profile.missions.get(mission.id,false):
			return mission
	for mission in Catalog.missions:
		if not profile.missions.get(mission.id,false):
			return mission
	return {}

func objective(raid_state: Dictionary = {}) -> String:
	var mission = tracked()
	if mission.is_empty():
		return "Contratos completados · explora y vuelve a casa"
	var status: Array[String] = []
	if mission.has("crafted"):
		status.append("Lotes fabricados %d/%d" % [mini(int(profile.get("crafted",0)),int(mission.crafted)),mission.crafted])
	if mission.has("kills"):
		status.append("Vigías %d/%d" % [mini(int(mission.kills),int(profile.kills)+int(raid_state.get("kills",0))),mission.kills])
	for id in mission.get("needs",{}):
		var safe = int(profile.stash.get(id,0))
		var carried = int(raid_state.get("bag",profile.prepared).get(id,0))
		status.append("%s %d/%d%s" % [Catalog.items[id].name,mini(safe+carried,int(mission.needs[id])),mission.needs[id]," en riesgo" if carried>0 else ""])
	return mission.name + "\n" + " · ".join(status)

func needed(id: String) -> bool:
	return Catalog.missions.any(func(mission): return not profile.missions.get(mission.id,false) and mission.get("needs",{}).has(id))

func craft(id: String) -> bool:
	if not editable():
		return false
	var recipe: Dictionary = {}
	for entry in Catalog.recipes:
		if entry.id == id:
			recipe = entry
	if recipe.is_empty():
		return false
	var trial = profile.stash.duplicate(true)
	for material in recipe.needs:
		if not Inventory.remove(trial,material,int(recipe.needs[material])):
			return false
	for item in recipe.output:
		if Inventory.add(trial,item,int(recipe.output[item]),capacity()) != int(recipe.output[item]):
			return false
	var before = profile.duplicate(true)
	profile.stash = trial
	profile.crafted = int(profile.get("crafted",0))+1
	return commit(before)
