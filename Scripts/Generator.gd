extends Node
onready var Res = $"/root/Resources"
onready var dungeon = $".."

const SEG_W = 800
const SEG_H = 800
const DIRECTIONS = [Vector2(0, -1), Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0)]
const DOFFSET = [Vector2(1, 0), Vector2(0, 1)]
const OPPOSITE = [2, 3, 0, 1]

var map = []
var width = 100
var height = 100

func _ready():
	pass

func generate(w, h):
	width = w
	height = h
	map.resize(width * height)
	
	var start = Vector2(randi() % width, randi() % height)
	var empty_spots = [{"pos": start}]
	
	while !empty_spots.empty():
		var spot = empty_spots[randi() % empty_spots.size()]
		empty_spots.erase(spot)
		
		var segments = get_possible_segments(spot)
		
		if !segments.empty():
			var segment = segments[randi() % segments.size()]
			var offset = segment.offset
			segment = segment.segment
			
			set_segment(spot.pos + offset, segment)
			
			for dir in range(4):
				var dim = ["width", "height"][dir%2]
				for i in range(segment[dim]):
					var ds = DIRECTIONS[dir] + DOFFSET[dir%2] * i
					if segment["ways" + str(dir)][i]: empty_spots.append({"pos": spot.pos + ds, "dir": dir})
	
	for x in range(width):
		for y in range(height):
			var segment = map[x + y * width]
			if segment and segment.piece_x + segment.piece_y == 0:
				create_segment(segment.segment.name, Vector2(x, y))
	
	$"../Player".position = Vector2(start.x * SEG_W, start.y * SEG_H) + Vector2(SEG_W/2, SEG_H/2)

func get_possible_segments(spot):
	var pos = spot.pos
	var dir = -1
	if spot.has("dir"): dir = spot.dir
	
	var segments = []
	
	for segment in Res.segments.values():
		var offset = Vector2()
		if dir > -1:
			var ways = segment["ways" + str(OPPOSITE[dir])]
			
			for i in range(ways.size()):
				if !ways[i]: continue
				var can_be = true
				
				offset = [Vector2(-i, -segment.height + 1), Vector2(0, -i), Vector2(-i, 0), Vector2(-segment.width + 1, -i)][dir]
				for j in range(4):
					var dim = ["width", "height"][j%2]
					var piece = ["piece_x", "piece_y"][j%2]
					for k in range(segment[dim]):
						if !can_be: break
						
						var way = segment["ways" + str(j)][k]
						var p = pos + offset + DIRECTIONS[j] + DOFFSET[j%2] * k
						var seg = get_segment_data(p)
						
						if way and (p.x < 0 or p.y < 0 or p.x >= width or p.y >= width): can_be = false
						if seg and seg.segment["ways" + str(OPPOSITE[j])][seg[piece]] != way: can_be = false
				
				if !can_be: continue
				for x in range(segment.width):
					for y in range(segment.height):
						var p = pos + offset + Vector2(x, y)
						if p.x < 0 or p.y < 0 or p.x >= width or p.y >= width or get_segment(p):
							can_be = false
				
				if !can_be: continue
				segments.append({"offset": offset, "segment": segment})
		else:
			var can_be = true
			for j in range(4):
				var dim = ["width", "height"][j%2]
				var piece = ["piece_x", "piece_y"][j%2]
				for k in range(segment[dim]):
					if !can_be: break
					
					var way = segment["ways" + str(j)][k]
					var p = pos + offset + DIRECTIONS[j] + DOFFSET[j%2] * k
					var seg = get_segment_data(p)
					
					if way and (p.x < 0 or p.y < 0 or p.x >= width or p.y >= width): can_be = false
					if seg and seg.segment["ways" + str(OPPOSITE[j])][seg[piece]] != way: can_be = false
			
			if can_be and pos.x + segment.width <= width and pos.y + segment.height <= height:
				segments.append({"offset": offset, "segment": segment})
	
	return segments

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
	elif typeof(up) != TYPE_BOOL and get_way(up, 2, get_segment_data(pos + DIRECTIONS[0]).piece_x):
		ways[0] = "force"
	
	if !right:
		ways[1] = "ok"
	elif typeof(right) != TYPE_BOOL and get_way(right, 3, get_segment_data(pos + DIRECTIONS[1]).piece_y):
		ways[1] = "force"
	
	if !down:
		ways[2] = "ok"
	elif typeof(down) != TYPE_BOOL and get_way(down, 0, get_segment_data(pos + DIRECTIONS[2]).piece_x):
		ways[2] = "force"
	
	if !left:
		ways[3] = "ok"
	elif typeof(left) != TYPE_BOOL and get_way(left, 1, get_segment_data(pos + DIRECTIONS[3]).piece_y):
		ways[3] = "force"
	
	return ways

func get_matching_segments(ways):
	var segments = []
	
	for segment in Res.segments.values():
		var can_be = true
		for i in range(segment.ways.size()):
			var j = way_dir(segment, i)
			if (segment.ways[i] and !ways[j]) or (ways[j] and ways[j] == "force" and !segment.ways[i]): can_be = false
		
		if can_be: segments.append(segment)
	
	return segments

func filter_segments(pos, segments):
	var result = []
	
	for segment in segments:
		var can_be = true
		for x in range(segment.width):
			for y in range(segment.height):
				var p = pos + Vector2(x, y)
				if p.x < 0 or p.y < 0 or p.x >= width or p.y >= width or get_segment(p):
					can_be = false
		
		if can_be: result.append(segment)
	
	return result

func get_segment(pos):
	if pos.x < 0 or pos.y < 0 or pos.x >= width or pos.y >= height: return
	if !map[pos.x + pos.y * width]: return null
	
	return map[pos.x + pos.y * width].segment

func get_segment_data(pos):
	if pos.x < 0 or pos.y < 0 or pos.x >= width or pos.y >= height: return
	if !map[pos.x + pos.y * width]: return null
	
	return map[pos.x + pos.y * width]

func set_segment(pos, segment):
	for x in range(segment.width):
		for y in range(segment.height):
			map[pos.x + x + (pos.y + y)  * width] = {"segment": segment, "piece_x": x, "piece_y": y}

func get_way(segment, dir, pos):
	return segment["ways" + str(dir)][pos]

func way_offset(segment, i):
	if way_dir(segment, i) == 0: return Vector2(i, -1)
	if way_dir(segment, i) == 1: return Vector2(segment.width, i - segment.width)
	if way_dir(segment, i) == 2: return Vector2(segment.width - (i - segment.width - segment.height) - 1, segment.height)
	if way_dir(segment, i) == 3: return Vector2(-1, segment.height - (i - segment.width*2 - segment.height) - 1)

func way_dir(segment, i):
	if i >= segment.width*2 + segment.height: return 3
	if i >= segment.width*2: return 2
	if i >= segment.width: return 1
	return 0

func create_segment(segment, pos):
	var seg = Res.segment_nodes[segment].instance()
	seg.position = Vector2(pos.x * SEG_W, pos.y * SEG_H)
	dungeon.add_child(seg)
	return seg