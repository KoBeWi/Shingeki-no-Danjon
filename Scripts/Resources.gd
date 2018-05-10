extends Node

var resources = {}
var segments = {}
var segment_nodes = {}
var tilesets = {}
var items = []
var skills = {}
var dungeons = {}
var crafting = []

func _ready():
	for segment in get_resource_list("Segments"):
		assert(segment.data != null)
		segments[segment.name] = segment.data
		segments[segment.name].name = segment.name
		segment_nodes[segment.name] = load("res://Nodes/Segments/" + segment.name + ".tscn")
	
	for tileset in get_resource_list("Tilesets"):
		assert(tileset.data != null)
		tilesets[tileset.name] = tileset.data
		
		var tile_to_floor = {}
		var floor_ids_with_weights = {}
		for flooor in tileset.data.floor:
			if flooor.has("id"):
				floor_ids_with_weights[flooor.id] = flooor.weight
			else: for i in range(flooor.ids.size()):
				floor_ids_with_weights[flooor.ids[i]] = flooor.weights[i]
				tile_to_floor[flooor.ids[i]] = flooor
		
		tileset.data.tile_to_floor = tile_to_floor
		tileset.data.floor_ids_with_weights = floor_ids_with_weights
		tileset.data.floor_id = tileset.data.floor[0].id
		
		var tile_to_wall = {}
		var wall_ids_with_weights = {}
		for wall in tileset.data.wall:
			if wall.has("id"):
				wall_ids_with_weights[wall.id] = wall.weight
			else: for i in range(wall.ids.size()):
				wall_ids_with_weights[wall.ids[i]] = wall.weights[i]
				tile_to_wall[wall.ids[i]] = wall
		
		tileset.data.tile_to_wall = tile_to_wall
		tileset.data.wall_ids_with_weights = wall_ids_with_weights
		tileset.data.wall_id = tileset.data.wall[0].id
	
	var resources = get_resource_list("Items")
	items.resize(resources.size())
	for item in resources:
		assert(item.data != null)
		var item_id = int(item.name)
		items[item_id] = item.data
		items[item_id].id = item_id
	
	for skill in get_resource_list("Skills"):
		assert(skill.data != null)
		skills[skill.name] = skill.data
	
	for dungeon in get_resource_list("Dungeons"):
		assert(dungeon.data != null)
		dungeons[dungeon.name] = dungeon.data
	
	crafting = read_json("res://Resources/CraftingList.json")
	assert(crafting != null)

func get_resource_list(resource):
	var resources = []
	
	var dir = Directory.new()
	if dir.open("res://Resources/" + resource +"/") == OK:
		dir.list_dir_begin()
		
		var name = dir.get_next()
		while name != "":
			if !name.ends_with(".json"):
				name = dir.get_next()
				continue
			
			resources.append({"name": name.left(name.length() - 5), "data": read_json("res://Resources/" + resource + "/" + name)})
			
			name = dir.get_next()
	
	return resources

func read_json(f):
	var file = File.new()
	file.open(f, file.READ)
	var text = file.get_as_text()
	file.close()
	return parse_json(text)

func get_resource(path):
	if !resources.has(path): resources[path] = load(path)
	
	return resources[path]

func play_sample(source, sample, pausable = true, follow_source = true):
	var player = create_instance("SampleInstance")
	player.init(source, sample, pausable, follow_source)
	get_parent().get_node("Game").add_child(player)

func create_instance(node):
	return get_node(node).instance()

func get_node(node):
	return get_resource("res://Nodes/" + node + ".tscn")
	
func get_item_texture(id):
	return get_resource("res://Sprites/Items/" + str(id) + ".png")
	
func get_skill_texture(skill):
	if get_resource("res://Sprites/UI/Skills/" + skill + ".png"):
		return get_resource("res://Sprites/UI/Skills/" + skill + ".png")
	else:
		return get_resource("res://Sprites/UI/Skills/NoSkill.png")

func weighted_random(chances):
	var sum = 0
	for value in chances.values(): sum += int(value)
	if sum == 0: return
	
	var chances2 = {}
	chances2[chances.keys()[0]] = chances.values()[0]
	
	for i in range(chances.size()-1):
		chances2[chances.keys()[i+1]] = int(chances2[chances.keys()[i]] + chances[chances.keys()[i+1]])
	
	var value = randi() % sum
	for chance in chances2.keys():
		if chances2[chance] >= value:
			return chance