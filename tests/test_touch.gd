extends SceneTree
var checks=0
var failures=0
func check(value: bool, message: String) -> void:
	checks += 1
	if value:
		print("PASS: ",message)
	else:
		failures += 1
		push_error("FAIL: "+message)
func _initialize() -> void:
	call_deferred("run")
func frames() -> void:
	for i in 3:
		await physics_frame
		await process_frame
func touch(index: int, point: Vector2, down: bool, canceled=false) -> void:
	var event=InputEventScreenTouch.new()
	event.index=index;event.position=point;event.pressed=down;event.canceled=canceled
	root.push_input(event,true)
func drag(index: int, point: Vector2) -> void:
	var event=InputEventScreenDrag.new()
	event.index=index;event.position=point
	root.push_input(event,true)
func run() -> void:
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game);await frames()
	game.ignore_focus=true
	game.store.path="user://touch-scene-test.json"
	for suffix in ["",".bak",".tmp"]:
		DirAccess.remove_absolute(game.store.path+suffix)
	game.progression=Progression.new(game.store)
	game.start_raid();game.set_process(false);game.player.set_physics_process(false)
	for enemy in game.enemies:
		enemy.set_physics_process(false)
	game.ui.touch_calibration();await frames()
	var lab=game.ui.calibration
	var control=lab.controls
	var pads=control.centers()
	var button=lab.action_button.global_position+lab.action_button.size/2
	touch(1,pads.move+Vector2(45,0),true);touch(2,pads.aim+Vector2(0,-45),true)
	touch(3,button,true);touch(3,button,false)
	check(lab.combo_count==1 and control.fingers.size()==2,"three fingers activate action while both sticks remain held")
	await frames()
	touch(1,pads.move,false)
	await frames()
	check(control.move_vector==Vector2.ZERO and control.aim_vector.length()>.1 and control.fingers.size()==1,"releasing movement preserves aim ownership")
	check(lab.released_move,"local report records independent movement release")
	touch(1,pads.move+Vector2(45,0),true);await frames()
	touch(2,pads.aim,false)
	await frames()
	check(lab.released_aim and control.move_vector.length()>.1,"local report records independent aiming release")
	touch(1,pads.move,false)
	touch(3,button,true);touch(3,button,false,true)
	check(lab.action_count==1,"OS canceled touch cannot activate an action")
	touch(3,button,true);drag(3,button+Vector2(35,0));touch(3,button,false)
	check(lab.action_count==1,"dragging a button cancels its tap")
	touch(5,pads.move+Vector2(35,0),true);touch(5,pads.aim+Vector2(0,-35),true)
	check(control.fingers.get(5)=="move" and control.aim_vector==Vector2.ZERO,"duplicate finger ID cannot steal the other stick")
	control.clear()
	var floating=Vector2(330,400)
	touch(6,floating,true);drag(6,floating+Vector2(40,0))
	check(control.floating_origin!=null and control.move_vector.x>.2,"adaptive left stick follows a comfortable starting point")
	touch(6,floating,false)
	check(control.floating_origin==null and control.move_vector==Vector2.ZERO,"floating stick resets its origin on release")
	control.settings={"adaptive_stick":false}
	touch(6,floating,true)
	check(control.fingers.is_empty(),"fixed mode does not capture outside its pad")
	control.settings={"adaptive_stick":true}
	touch(8,pads.aim+Vector2(0,-control.radius*.3),true)
	drag(8,pads.aim+Vector2(0,-control.radius*.25))
	check(control.aim_latched and control.aim_vector.length()>0,"aim hysteresis prevents stopping at the activation threshold")
	drag(8,pads.aim+Vector2(0,-control.radius*.2))
	check(not control.aim_latched and control.aim_vector==Vector2.ZERO,"returning inside the rest zone stops aim")
	touch(9,button,true);lab.layout()
	check(control.fingers.is_empty() and control.aim_vector==Vector2.ZERO,"layout change clears stick ownership")
	touch(9,button,false)
	check(lab.action_count==1,"layout change cancels pending button taps")
	var health=game.raid.health;var loaded=game.raid.loaded;var time=game.raid.time
	game.player._physics_process(2)
	check(game.paused and game.raid.health==health and game.raid.loaded==loaded and game.raid.time==time,"touch calibration leaves live raid resources frozen")
	game.ui.settings_panel();await frames()
	check(not is_instance_valid(game.ui.calibration),"leaving calibration destroys all test input owners")
	var scroll=game.ui.panel.find_children("*","ScrollContainer",true,false)[0]
	var row=game.ui.content.get_children().filter(func(c):return c is TouchActionButton)[0]
	var row_point=row.global_position+row.size/2
	touch(52,row_point,true);drag(52,row_point-Vector2(0,80))
	check(scroll.scroll_vertical>0,"drag beginning over a button still scrolls its panel")
	touch(52,row_point-Vector2(0,80),false);await frames()
	check(not is_instance_valid(game.ui.calibration),"scroll gesture does not accidentally activate the button")
	game.queue_free();await frames();await create_timer(.2).timeout
	for suffix in ["",".bak",".tmp"]:
		DirAccess.remove_absolute("user://touch-scene-test.json"+suffix)
	print("TOUCH_RESULT ",checks," checks, ",failures," failures")
	quit(1 if failures>0 else 0)
