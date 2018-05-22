extends YSort

var leave_menu = false
var dungeon
var from = "UP"

var my_seed
var object_id = 0
var obj_properties = []
var object_ids = {}

func _ready():
	Res.call_deferred("play_music", "LowerWorkshop")
	VisualServer.set_default_clear_color(Color(0.05, 0.05, 0.07))
	ProjectSettings.set_setting("rendering/environment/default_clear_color", "1a1918") ##usunąć, gdy naprawią powyższe :/
	
	if !my_seed:
		randomize()
		my_seed = randi()
		print("Seed: ", my_seed)
		seed(my_seed)
	else:
		seed(my_seed)
	
#	seed(4044205418) ##DEBUG
	
	dungeon = Res.dungeons["Workshop"]
	if has_node("Generator"): $Generator.generate(10, 10) ##warunek to debug
	DungeonState.emit_signal("floor_changed", DungeonState.current_floor)

func _process(delta):
	if Input.is_action_just_pressed("Menu") and !leave_menu:
		open_menu()
	elif Input.is_action_just_released("Menu"):
		leave_menu = false

func open_menu():
	$Player/Camera/UI.enable()
	get_tree().paused = true

func change_floor(change):
	name = "OldGame"
	DungeonState.visited_floors[DungeonState.current_floor] = {"seed": my_seed, "obj_properties": obj_properties}
	
	DungeonState.current_floor += change
	
	var game = load("res://Scenes/Game.tscn").instance()
	if DungeonState.visited_floors.has(DungeonState.current_floor):
		var state = DungeonState.visited_floors[DungeonState.current_floor]
		game.my_seed = state.seed
		game.obj_properties = state.obj_properties
	game.from = ("UP" if change > 0 else "DOWN")
	
	$"/root".add_child(game)
	get_tree().current_scene = game
	
	queue_free()

func perma_state(object, method):
	var already_saved = false
	
	for obj in obj_properties:
		if obj.id == object_id and obj.saved:
			object.call(method)
			already_saved = true
	
	if !already_saved: object_ids[object] = object_id
	object_id += 1

func save_state(object):
	obj_properties.append({"id": object_ids[object], "saved": true})