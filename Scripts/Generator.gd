extends Node
onready var Res = $"/root/Resources"
onready var dungeon = $".."

const SEG_W = 800
const SEG_H = 800
const DIRECTIONS = [Vector2(0, -1), Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0)]

var map = []
var width = 5
var height = 5

func _ready():
	map.resize(width * height)
#	$"../Player/Camera".limit_right = width * SEG_W
#	$"../Player/Camera".limit_bottom = height * SEG_H

func generate():
	var start = Vector2(randi() % width, randi() % height)
	var empty_spots = [start]
	
	while !empty_spots.empty():
		var spot = empty_spots[randi() % empty_spots.size()]
		empty_spots.erase(spot)
		
		var ways = get_possible_ways(spot)
		var segments = get_matching_segments(ways)
		
		if !segments.empty():
			var segment = segments[randi() % segments.size()]
			set_segment(spot, segment)
			
			for i in range(4):
				if segment.ways[i] and !get_segment(spot + DIRECTIONS[i]): empty_spots.append(spot + DIRECTIONS[i])
	
	for x in range(width):
		for y in range(height):
			if map[x + y * width]:
				create_segment(map[x + y * width]["name"], Vector2(x, y))
	$"../Player".position = Vector2(start.x * SEG_W, start.y * SEG_H) + Vector2(SEG_W/2, SEG_H/2)

func get_possible_ways(pos):
	var up = (pos.y == 0)
	if !up: up = get_segment(pos + DIRECTIONS[0])
	var right = (pos.x == width-1)
	if !right: right = get_segment(pos + DIRECTIONS[1])
	var down = (pos.y == height-1)
	if !down: down = get_segment(pos + DIRECTIONS[2])
	var left = (pos.x == 0)
	if !left: left = get_segment(pos + DIRECTIONS[3])
	
	var ways = [false, false, false, false]
	if !up:
		ways[0] = "ok"
	elif typeof(up) != TYPE_BOOL and up.ways[2]:
		ways[0] = "force"
		
	if !right:
		ways[1] = "ok"
	elif typeof(right) != TYPE_BOOL and right.ways[3]:
		ways[1] = "force"
		
	if !down:
		ways[2] = "ok"
	elif typeof(down) != TYPE_BOOL and down.ways[0]:
		ways[2] = "force"
		
	if !left:
		ways[3] = "ok"
	elif typeof(left) != TYPE_BOOL and left.ways[1]:
		ways[3] = "force"
	
	return ways

func get_matching_segments(ways):
	var segments = []
	
	for segment in Res.segments.values():
		var can_be = true
		for i in range(4):
			if (segment["ways"][i] and !ways[i]) or (ways[i] and ways[i] == "force" and !segment["ways"][i]): can_be = false
		
		if (can_be): segments.append(segment)
	
	return segments

func get_segment(pos):
	if not (pos.x >= 0 and pos.y >= 0 and pos.x < width and pos.y < height): return
	return map[pos.x + pos.y * width]

func set_segment(pos, segment):
	map[pos.x + pos.y  * width] = segment

func create_segment(segment, pos):
	var seg = Res.segment_nodes[segment].instance()
	seg.position = Vector2(pos.x * SEG_W, pos.y * SEG_H)
	dungeon.add_child(seg)
	return seg