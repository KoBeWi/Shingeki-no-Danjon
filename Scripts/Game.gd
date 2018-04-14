extends YSort

var leave_menu = false
var dungeon
var from = "UP"

var my_seed

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
#	no_generation = true
#	set_owner_recursive(self, self)
#	var packed_scene = PackedScene.new()
#	packed_scene.pack(self)
	DungeonState.visited_floors[DungeonState.current_floor] = my_seed#packed_scene
	
	DungeonState.current_floor += change
	
	var game = load("res://Scenes/Game.tscn").instance()
	if DungeonState.visited_floors.has(DungeonState.current_floor):
		game.my_seed = DungeonState.visited_floors[DungeonState.current_floor]
	game.from = ("UP" if change > 0 else "DOWN")
	
	$"/root".add_child(game)
	get_tree().current_scene = game
#	get_tree().change_scene_to(DungeonState.visited_floors[DungeonState.current_floor])
	
	queue_free()

func set_owner_recursive(who, node):
	for nd in node.get_children():
		nd.owner = who
		set_owner_recursive(who, nd)

#ta funkcja to hack i ma być usunięta razem z update, gdy set_default_clear_color() będzie naprawiony
func _draw():
	var camera = $"Player/Camera"
	draw_rect(Rect2(camera.get_camera_position() - OS.get_window_size()/2, OS.get_window_size()), Color(0.05, 0.05, 0.07))