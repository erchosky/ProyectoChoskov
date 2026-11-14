class_name Inventory
extends RefCounted

static func slots(bag: Dictionary) -> int:
	var total = 0
	for id in bag:
		total += ceili(float(bag[id]) / float(Catalog.items[id].stack))
	return total

static func room(bag: Dictionary, id: String, amount: int, capacity: int) -> int:
	if amount <= 0 or capacity < 0 or not Catalog.items.has(id):
		return 0
	var old: int = bag.get(id, 0)
	var stack: int = Catalog.items[id].stack
	var partial = (stack - old % stack) % stack
	return mini(amount, maxi(0, capacity - slots(bag)) * stack + partial)

static func add(bag: Dictionary, id: String, amount: int, capacity: int) -> int:
	var accepted = room(bag, id, amount, capacity)
	if accepted > 0:
		bag[id] = int(bag.get(id, 0)) + accepted
	return accepted

static func remove(bag: Dictionary, id: String, amount: int) -> bool:
	if amount == 0:
		return true
	if amount < 0:
		return false
	if int(bag.get(id, 0)) < amount:
		return false
	bag[id] -= amount
	if bag[id] <= 0:
		bag.erase(id)
	return true

static func transfer(source: Dictionary, target: Dictionary, id: String, amount: int, capacity: int) -> int:
	var accepted = add(target, id, mini(amount, source.get(id, 0)), capacity)
	remove(source, id, accepted)
	return accepted
