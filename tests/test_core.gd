extends SceneTree
var checks := 0
var failures := 0
func check(condition: bool, name: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + name)
	else:
		print("PASS: " + name)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var bag: Dictionary = {}
	check(Inventory.add(bag,"ammo9",70,1)==60,"capacity rejects extra stack")
	check(Inventory.slots(bag)==1,"stack slot accounting")
	Inventory.remove(bag,"ammo9",5)
	check(Inventory.add(bag,"ammo9",10,1)==5,"partial stack accepts correct amount")
	check(Inventory.add(bag,"bandage",1,1)==0,"full backpack rejects other item")
	var target: Dictionary = {}
	check(Inventory.transfer(bag,target,"ammo9",70,1)==60 and bag.is_empty(),"transfer conserves count")
	var store := SaveStore.new()
	store.path = "user://core-test.json"
	for suffix in ["",".bak",".tmp"]:
		DirAccess.remove_absolute(store.path+suffix)
	var prog := Progression.new(store)
	prog.prepare()
	check(prog.profile.equipment.weapon=="pistol","prepare equips stored weapon")
	var initial_ammo: int = prog.profile.stash.ammo9 + prog.profile.prepared.ammo9
	var raid := prog.begin(42)
	check(raid.loaded==12,"initial magazine loaded")
	check(prog.profile.stash.ammo9+raid.bag.ammo9+raid.loaded==initial_ammo,"deployment conserves ammunition")
	check(prog.profile.equipment.is_empty() and prog.profile.prepared.is_empty(),"deployment removes safe equipment")
	check(prog.begin(99).id==raid.id,"duplicate begin resumes same raid")
	raid.bag.scrap = 6
	raid.bag.wire = 3
	raid.kills = 3
	var credits: int = prog.profile.credits
	check(prog.finish(true),"extraction commits")
	check(not prog.finish(true) and prog.profile.credits==credits+35,"result applied only once")
	check(prog.profile.equipment.loaded==12 and prog.profile.prepared.ammo9==24,"loaded ammunition survives extraction")
	Inventory.transfer(prog.profile.prepared,prog.profile.stash,"scrap",6,prog.capacity())
	Inventory.transfer(prog.profile.prepared,prog.profile.stash,"wire",3,prog.capacity())
	check(prog.claim(Catalog.missions[0]),"material mission claims")
	check(not prog.profile.stash.has("scrap") and not prog.profile.stash.has("wire"),"mission consumes requested materials")
	credits = prog.profile.credits
	check(not prog.claim(Catalog.missions[0]) and credits==prog.profile.credits,"mission reward unique")
	check(prog.claim(Catalog.missions[2]),"enemy mission claims")
	var stash_before = prog.profile.stash.duplicate(true)
	raid = prog.begin(43)
	check(raid.loaded==12,"loaded magazine survives next deployment")
	stash_before = prog.profile.stash.duplicate(true)
	raid.bag.recorder = 1
	check(prog.finish(false),"death commits")
	check(prog.profile.prepared.is_empty() and prog.profile.equipment.is_empty(),"death loses all carried gear and loot")
	check(prog.profile.stash==stash_before,"death keeps stash")
	prog.profile.stash = {}
	prog.profile.credits = 0
	check(prog.emergency(),"emergency kit without resources")
	raid = prog.begin(44)
	check(raid.loaded>0 and raid.equipment.weapon=="pistol","emergency kit is playable")
	raid.bag.recorder = 1
	prog.persist()
	var reload_prog := Progression.new(store)
	check(reload_prog.profile.active.id==raid.id and reload_prog.profile.active.bag.recorder==1,"interrupted raid survives reload without extraction")
	check(reload_prog.profile.stash.is_empty(),"interrupted raid keeps loot at risk")
	prog.persist()
	var bad := FileAccess.open(store.path,FileAccess.WRITE)
	bad.store_string("broken"); bad.close()
	var backup := SaveStore.new()
	backup.path = store.path
	var recovered := backup.load_profile()
	check(backup.recovered and recovered.active.id==raid.id,"corrupt primary recovers validated backup")
	check(backup.write(recovered),"recovered profile writes safely")
	check(not backup.read_file(store.path+".bak").is_empty(),"corrupt primary cannot overwrite valid backup")
	# Simulate saved transition intent and reopening before final commit.
	reload_prog.profile = recovered
	reload_prog.profile.active.result = "success"
	reload_prog.persist()
	var pending := Progression.new(backup)
	check(pending.profile.active.result=="success" and pending.finish(true),"pending extraction completes on relaunch")
	check(not pending.finish(true),"pending result cannot repeat")
	for suffix in ["",".bak",".tmp"]:
		DirAccess.remove_absolute(store.path+suffix)
	print("CORE_RESULT ",checks," checks, ",failures," failures")
	quit(1 if failures>0 else 0)
