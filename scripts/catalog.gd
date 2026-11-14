class_name Catalog
extends RefCounted
static var items: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/items.json"))
static var weapons: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/weapons.json"))
static var enemies: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/enemies.json"))
static var notes: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/notes.json"))
static var missions: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/missions.json"))

static var recipes: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/recipes.json"))
static var expedition: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/expedition.json"))
