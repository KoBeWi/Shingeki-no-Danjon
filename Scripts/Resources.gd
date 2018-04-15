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
		segments[segment.name] = segment.data
		segments[segment.name].name = segment.name
		segment_nodes[segment.name] = load("res://Nodes/Segments/" + segment.name + ".tscn")
	
	for tileset in get_resource_list("Tilesets"):
		tilesets[tileset.name] = tileset.data
	
	var resources = get_resource_list("Items")
	items.resize(resources.size())
	for item in resources:
		var item_id = int(item.name)
		items[item_id] = item.data
		items[item_id].id = item_id
	
	for skill in get_resource_list("Skills"):
		skills[skill.name] = skill.data
	
	for dungeon in get_resource_list("Dungeons"):
		dungeons[dungeon.name] = dungeon.data
	
	crafting = read_json("res://Resources/CraftingList.json")

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

func play_sample(source, sample, pausable = true):
	var player = AudioStreamPlayer2D.new()
	player.pause_mode = (PAUSE_MODE_INHERIT if pausable else PAUSE_MODE_PROCESS)
	get_parent().get_node("Game").add_child(player)
	player.connect("finished", player, "queue_free")
	
	player.stream = get_resource("res://Samples/" + sample + ".ogg")
	player.position = source.position
	player.play()

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
	for value in chances.values(): sum += value
	if sum == 0: return
	
	for i in range(chances.size()-1):
		chances[chances.keys()[i+1]] = chances[chances.keys()[i]] + chances[chances.keys()[i+1]]
	
	var value = randi() % sum
	for chance in chances.keys():
		if chances[chance] >= value:
			return chance