extends Node

var resources = {}
var segments = {}
var segment_nodes = {}
var tilesets = {}

func _ready():
	var dir = Directory.new()
	if dir.open("res://Nodes/Segments/") == OK:
		dir.list_dir_begin()
		
		var name = dir.get_next()
		while name != "":
			if !name.ends_with(".json"):
				name = dir.get_next()
				continue
			
			var file = File.new()
			file.open("res://Nodes/Segments/" + name, file.READ)
			var text = file.get_as_text()
			file.close()
			
			var segname = name.left(name.length() - 5)
			segments[segname] = parse_json(text)
			segments[segname].name = segname
			segment_nodes[segname] = load("res://Nodes/Segments/" + segname + ".tscn")
			
			name = dir.get_next()

	if dir.open("res://Resources/Tilesets/") == OK:
		dir.list_dir_begin()
		
		var name = dir.get_next()
		while name != "":
			if !name.ends_with(".json"):
				name = dir.get_next()
				continue
			
			var file = File.new()
			file.open("res://Resources/Tilesets/" + name, file.READ)
			var text = file.get_as_text()
			file.close()
			
			var tileset_name = name.left(name.length() - 5)
			tilesets[tileset_name] = parse_json(text)
			
			name = dir.get_next()

func get_resource(path):
	if !resources.has(path): resources[path] = load(path)
	
	return resources[path]

func play_sample(source, sample):
	source.stream = get_resource("res://Samples/" + sample + ".ogg")
	source.play()

func create_instance(node):
	return get_resource("res://Nodes/" + node + ".tscn").instance()