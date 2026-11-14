class_name SaveStore
extends RefCounted
const VERSION := 3
var path = "user://choskov.json"
var recovered = false
var write_error = false

func read_file(file: String) -> Dictionary:
	if not FileAccess.file_exists(file):
		return {}
	var parser = JSON.new()
	if parser.parse(FileAccess.get_file_as_string(file)) != OK:
		return {}
	var envelope = parser.data
	if not envelope is Dictionary or not envelope.get("payload") is String:
		return {}
	if envelope.get("checksum", "") != envelope.payload.sha256_text():
		return {}
	if parser.parse(envelope.payload) != OK:
		return {}
	var result = parser.data
	if not result is Dictionary or not whole(result.get("version"), 1, VERSION):
		return {}
	# Validate essential shape before trusting a damaged or foreign save.
	for key in ["stash", "equipment", "prepared", "missions", "settings"]:
		if not result.get(key) is Dictionary:
			return {}
	if not result.get("processed") is Array or not result.get("active") is Dictionary:
		return {}
	# Additive migration preserves equipment, pending results and suspended raids.
	result.version = VERSION
	if not result.get("journal") is Dictionary:
		result.journal = {}
	if not result.has("tracked_mission"):
		result.tracked_mission = "repair"
	if not result.has("crafted"):
		result.crafted = 0
	return result if valid_profile(result) else {}

# A checksum detects damaged bytes, not invalid game data. Validate nested state
# before UI, inventory and scene restoration index catalog IDs or arrays.
static func number(value: Variant, minimum: float, maximum: float = 1000000000.0) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) >= minimum and float(value) <= maximum

static func whole(value: Variant, minimum: int = 0, maximum: int = 1000000000) -> bool:
	return number(value, minimum, maximum) and float(value) == floor(float(value))

static func pair(value: Variant) -> bool:
	return value is Array and value.size() == 2 and number(value[0], -100, 100) and number(value[1], -100, 100)

static func valid_inventory(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	for id in value:
		if not Catalog.items.has(id) or not whole(value[id], 1):
			return false
	return true

static func valid_equipment(value: Variant, require_weapon: bool = false) -> bool:
	if not value is Dictionary or (require_weapon and not value.has("weapon")):
		return false
	for slot in value:
		match slot:
			"weapon":
				if not value[slot] is String or not Catalog.weapons.has(value[slot]):
					return false
			"armor", "pack":
				if value[slot] != slot:
					return false
			"loaded":
				if not value.get("weapon") is String or not Catalog.weapons.has(value.weapon) or not whole(value.loaded, 0, int(Catalog.weapons[value.weapon].capacity)):
					return false
			_:
				return false
	return true

static func valid_profile(profile: Dictionary) -> bool:
	if not valid_inventory(profile.stash) or not valid_inventory(profile.prepared) or not valid_equipment(profile.equipment):
		return false
	for key in ["credits", "kills", "raids", "extractions", "crafted"]:
		if not whole(profile.get(key)):
			return false
	if not whole(profile.get("storage_level"), 0, 2) or not profile.get("workshop") is bool or not profile.get("tutorial") is bool:
		return false
	if not profile.tracked_mission is String or not Catalog.missions.any(func(m): return m.id == profile.tracked_mission):
		return false
	for id in profile.missions:
		if not profile.missions[id] is bool or not Catalog.missions.any(func(m): return m.id == id):
			return false
	for id in profile.journal:
		if not profile.journal[id] is bool or not Catalog.notes.any(func(note): return note.id == id):
			return false
	for id in profile.processed:
		if not id is String or id.is_empty():
			return false
	var defaults: Dictionary = fresh().settings
	profile.settings.merge(defaults, false)
	for key in ["assist", "sound", "shake", "adaptive_stick"]:
		if not profile.settings[key] is bool:
			return false
	if not whole(profile.settings.fps, 30, 60) or int(profile.settings.fps) not in [30, 60] or not whole(profile.settings.quality, 0, 1):
		return false
	if not number(profile.settings.sensitivity, .5, 1.8) or not number(profile.settings.control_size, .75, 1.3):
		return false
	return valid_raid(profile.active)

static func valid_raid(raid: Dictionary) -> bool:
	if raid.is_empty():
		return true
	if not raid.get("id") is String or raid.id.is_empty() or not whole(raid.get("seed"), 0, 2147483647):
		return false
	if not valid_inventory(raid.get("bag")) or not valid_equipment(raid.get("equipment"), true):
		return false
	if not pair(raid.get("position")) or not pair(raid.get("aim")):
		return false
	if not number(raid.get("health"), 0, 100) or not number(raid.get("time"), 0) or not whole(raid.get("kills")) or not whole(raid.get("loaded"), 0, int(Catalog.weapons[raid.equipment.weapon].capacity)):
		return false
	if raid.get("result", "") not in ["", "success", "death"] or raid.get("heal_item", "") not in ["", "bandage", "medkit"]:
		return false
	for key in ["reload", "heal", "exposed", "recovery_delay", "dodge_timer", "dodge_cooldown", "decoy_cd"]:
		if not number(raid.get(key, 0), 0):
			return false
	if not number(raid.get("stamina", 100), 0, 100) or not pair(raid.get("dodge_direction", [0, -1])):
		return false
	for key in ["initialized", "radio_powered", "crouched", "exhausted", "warden_spawned"]:
		if not raid.get(key, false) is bool:
			return false
	if raid.get("delivery", "waiting") not in ["waiting", "incoming", "landed"] or not pair(raid.get("delivery_point", [0, 0])) or not whole(raid.get("decoy_serial", 0)):
		return false
	for key in ["enemies", "containers", "decoys"]:
		if not raid.get(key, []) is Array:
			return false
	if raid.get("initialized", false) and (not raid.has("enemies") or not raid.has("containers")):
		return false
	for enemy in raid.get("enemies", []):
		if not enemy is Dictionary or not enemy.get("kind") is String or not Catalog.enemies.has(enemy.kind) or not pair(enemy.get("p")) or not number(enemy.get("health"), 0, float(Catalog.enemies[enemy.kind].health)):
			return false
		for key in ["home", "last", "target", "attack_target"]:
			if not pair(enemy.get(key, enemy.p)):
				return false
		# Older builds saved a small negative search timer on the return transition.
		if not number(enemy.get("search_timer", 0), -.35):
			return false
		enemy.search_timer = maxf(0, float(enemy.get("search_timer", 0)))
		for key in ["seen_timer", "cooldown", "windup"]:
			if not number(enemy.get(key, 0), 0):
				return false
		if enemy.get("mode", "patrol") not in ["patrol", "chase", "search", "investigate", "return"] or not whole(enemy.get("patrol_index", 0), 0, 3):
			return false
	for container in raid.get("containers", []):
		if not container is Dictionary or not pair(container.get("p")) or not valid_inventory(container.get("items")) or not container.get("name") is String:
			return false
		if container.get("locked_key", "") not in ["", "outpost_key"] or container.get("kind", "supplies") not in ["supplies", "locked", "airdrop", "boss"]:
			return false
	for decoy in raid.get("decoys", []):
		if not decoy is Dictionary or not decoy.get("id") is String or not pair(decoy.get("p")) or not number(decoy.get("remaining"), 0, 8):
			return false
	return true

func load_profile() -> Dictionary:
	recovered = false
	var profile = read_file(path)
	if profile.is_empty():
		profile = read_file(path + ".bak")
		recovered = not profile.is_empty()
	if profile.is_empty():
		profile = fresh()
	return profile

func write(profile: Dictionary) -> bool:
	var payload = JSON.stringify(profile)
	var envelope = JSON.stringify({"payload": payload, "checksum": payload.sha256_text()})
	var f = FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if f == null:
		write_error = true
		return false
	f.store_string(envelope)
	f.flush()
	f.close()
	if read_file(path + ".tmp").is_empty():
		write_error = true
		return false
	if not read_file(path).is_empty():
		var old = FileAccess.get_file_as_bytes(path)
		var backup = FileAccess.open(path + ".bak", FileAccess.WRITE)
		if backup == null:
			write_error = true
			return false
		backup.store_buffer(old)
		backup.flush()
		backup.close()
	var error = DirAccess.rename_absolute(path + ".tmp", path)
	write_error = error != OK
	return not write_error

static func fresh() -> Dictionary:
	return {"version": VERSION, "crafted": 0, "journal": {}, "tracked_mission": "repair", "credits": 160, "stash": {"pistol": 1, "ammo9": 60, "bandage": 4, "rifle": 1, "ammo556": 48}, "equipment": {}, "prepared": {}, "missions": {}, "kills": 0, "storage_level": 0, "workshop": false, "tutorial": false, "raids": 0, "extractions": 0, "processed": [], "active": {}, "settings": {"assist": true, "sensitivity": 1.0, "control_size": 1.0, "fps": 60, "quality": 1, "sound": true, "shake": true, "adaptive_stick": true}}
