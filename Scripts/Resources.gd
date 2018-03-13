extends Node

var segments = {}
var segment_nodes = {}

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