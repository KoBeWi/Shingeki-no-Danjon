extends YSort

var leave_menu = false
var dungeon
var from = "UP"

var my_seed
var object_id = 0
var id_table = {}

func _ready():
	VisualServer.set_default_clear_color(Color(0.05, 0.05, 0.07))
	
	if !my_seed:
		randomize()
		my_seed = randi()
		print("Seed: ", my_seed)
		seed(my_seed)
	else:
		seed(my_seed)
	
#	seed(335011201) ##DEBUG
	SkillBase.acquired_skills.append("FastWalk") ##DEBUG
	
	dungeon = Res.dungeons["Workshop"]
	$Generator.generate(10, 10)
	DungeonState.emit_signal("floor_changed", DungeonState.current_floor)

func _process(delta):
	if Input.is_action_just_pressed("Menu") and !leave_menu:
		$Player/Camera/UI.enable()
		get_tree().paused = true
	elif Input.is_action_just_released("Menu"):
		leave_menu = false
	
	update()

func change_floor(change):
	name = "OldGame"
	DungeonState.visited_floors[DungeonState.current_floor] = {"seed": my_seed, "objects": id_table}
	
	DungeonState.current_floor += change
	
	var game = load("res://Scenes/Game.tscn").instance()
	if DungeonState.visited_floors.has(DungeonState.current_floor):
		var state = DungeonState.visited_floors[DungeonState.current_floor]
		game.my_seed = state.seed
		game.id_table = state.objects
	game.from = ("UP" if change > 0 else "DOWN")
	
	$"/root".add_child(game)
	get_tree().current_scene = game
	
	queue_free()

func set_owner_recursive(who, node):
	for nd in node.get_children():
		nd.owner = who
		set_owner_recursive(who, nd)

func perma_state(object, method):
	var already_saved = false
	for obj in id_table.values():
		if obj.id == object_id:
			object.call(method)
			already_saved = true
	
	if !already_saved: id_table[object] = {"id": object_id, "method": method, "saved": false}
	object_id += 1

func save_state(object):
	id_table[object].saved = true

#ta funkcja to hack i ma być usunięta razem z update, gdy set_default_clear_color() będzie naprawiony
func _draw():
	var camera = $"Player/Camera"
	draw_rect(Rect2(camera.get_camera_position() - OS.get_window_size()/2, OS.get_window_size()), Color(0.05, 0.05, 0.07))