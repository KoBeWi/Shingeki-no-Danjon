extends Node2D

var leave_menu = false

var my_seed
var object_id = 0
var obj_properties = []
var object_ids = {}

var player
var map
var music

func _init():
	Res.game = self

func _ready():
	VisualServer.set_default_clear_color(Color(0.05, 0.05, 0.07))
	ProjectSettings.set_setting("rendering/environment/default_clear_color", "1a1918") ##usunąć, gdy naprawią powyższe :/
	player = $Player
	
	DungeonState.current_floor = 0
	DungeonState.emit_signal("floor_changed", DungeonState.current_floor)
	
	PlayerStats.health = PlayerStats.max_health
	PlayerStats.mana = PlayerStats.max_mana

func set_map(new_map):
	if map:
		map.remove_child(player)
		map.queue_free()
	else: remove_child(player)
	new_map.add_child(player)
	
	map = new_map
	add_child(new_map)
	new_map.initialize()

func _process(delta):
	if Input.is_action_just_pressed("Menu") and !leave_menu:
		Res.ui_sample("MenuEnter")
		open_menu()
	elif Input.is_action_just_released("Menu"):
		leave_menu = false

func open_menu():
	player.UI.enable()
	player.UI.get_node("FloorLabel").visible = false
	get_tree().paused = true

func change_floor(change):
	if map.get("my_seed"):
		DungeonState.visited_floors[DungeonState.current_floor] = {"seed": map.my_seed, "obj_properties": obj_properties}
	DungeonState.current_floor += change
	
	object_id = 0
	var new_map = load("res://Maps/RandomMap.tscn").instance()
	if DungeonState.current_floor == 0: #ULTRAMEGAOSTATECZNYHACK
		new_map = load("res://Maps/JigsawRoom.tscn").instance()
	elif DungeonState.current_floor == 4: #ULTRAMEGAOSTATECZNYHACK
		new_map = load("res://Maps/BossRoom.tscn").instance()
	else:
		if DungeonState.visited_floors.has(DungeonState.current_floor):
			var state = DungeonState.visited_floors[DungeonState.current_floor]
			new_map.my_seed = state.seed
			obj_properties = state.obj_properties
		else:
			obj_properties = []
		new_map.from = ("UP" if change > 0 else "DOWN")
	
	set_map(new_map)
	player.change_dir(2)
	
	DungeonState.emit_signal("floor_changed", DungeonState.current_floor)

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