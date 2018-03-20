extends Node
onready var Res = $"/root/Resources"
onready var dungeon = $"../Segments"
onready	var uganda = load("res://Nodes/Uganda.tscn")
onready var pusher = load("res://Nodes/Puncher.tscn")

const SEG_W = 800
const SEG_H = 800
const DIRECTIONS = [Vector2(0, -1), Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0)]
const DOFFSET = [Vector2(1, 0), Vector2(0, 1)]
const OPPOSITE = [2, 3, 0, 1]

var map = []
var width = 100
var height = 100

var map_Uganda = [] # Table for positions of floor Segments

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
					if segment["ways" + str(dir)][i]: empty_spots.append({"pos": spot.pos + offset + ds, "dir": dir})
	
	for x in range(width):
		for y in range(height):
			var segment = map[x + y * width]
			if segment and segment.piece_x + segment.piece_y == 0:
				create_segment(segment.segment.name, Vector2(x, y))
	
	$"../Player".position = Vector2(start.x * SEG_W, start.y * SEG_H) + Vector2(SEG_W/2, SEG_H/2)
	
	for segment in dungeon.get_children():
		var bottom = segment.get_node("BottomTiles")
		
		var tileset = Res.tilesets["Dungeon"]
		
		var floor_id = tileset.floor[0]
		var floor_size = tileset.floor.size()
		
		var wall_id = tileset.wall[0]
		var wall_size = tileset.wall.size()
		
		for cell in bottom.get_used_cells():
			if bottom.get_cellv(cell) == floor_id:
				var new_tile = randi() % floor_size
				if new_tile > 0:
					var tile = tileset.floor[new_tile]
					var id = floor_id
					if tile.has("id"): id = tile.id
					else: id = tile.ids[randi() % tile.ids.size()]
					
					var space = true
					for t in range(tile.pattern.size()):
						if bottom.get_cellv(cell + Vector2(t % int(tile.cols), t / int(tile.cols))) != floor_id:
							space = false
							break
					
					if !space: continue
					for t in range(tile.pattern.size()):
						var flip = [false, false, false]
						if tile.has("can_flip"): flip = [randi()%2 == 0, randi()%2 == 0, randi()%2 == 0]
						bottom.set_cellv(cell + Vector2(t % int(tile.cols), t / int(tile.cols)), id + tile.pattern[t], flip[0], flip[1], flip[2])
				
			if bottom.get_cellv(cell) == wall_id:
				var new_tile = randi() % wall_size
				if new_tile > 0:
					var tile = tileset.wall[new_tile]
					
					var space = true
					for t in range(tile.pattern.size()):
						var celll = bottom.get_cellv(cell + Vector2(t % int(tile.cols), t / int(tile.cols)))
						if celll != wall_id and celll != wall_id + 3:
							space = false
							break
					
					if !space: continue
					for t in range(tile.pattern.size()):
						bottom.set_cellv(cell + Vector2(t % int(tile.cols), t / int(tile.cols)), tile.id + tile.pattern[t])

						
	place_Uganda_into_maze(start, 100)
	place_Pusher_into_maze(start, 40)

func place_Pusher_into_maze(start, how_many):
	$"../Puncher".position = Vector2(start.x * SEG_W, start.y * SEG_H) + Vector2(SEG_W/2, SEG_H/2)
	$"../Puncher/AnimationPlayer".play()
	
	for nmb in range(how_many):
		var ug_inst = pusher.instance()
		ug_inst.position = map_Uganda[randi()%map_Uganda.size()]+ Vector2(40,40)# + Vector2(randi()% (SEG_W-460), randi()% (SEG_H-500) )#Vector2( randi()%width * SEG_W + randi()% SEG_W, randi()%height * SEG_H  + randi()% SEG_H)
		ug_inst.z_index = 1
		dungeon.add_child(ug_inst)

func place_Uganda_into_maze(start, how_many):
	$"../Uganda".position = Vector2(start.x * SEG_W + 70, start.y * SEG_H) + Vector2(SEG_W/2, SEG_H/2)

	for nmb in range(how_many):
		var ug_inst = uganda.instance()
		ug_inst.position = map_Uganda[randi()%map_Uganda.size()]+ Vector2(40,40)# + Vector2(randi()% (SEG_W-460), randi()% (SEG_H-500) )#Vector2( randi()%width * SEG_W + randi()% SEG_W, randi()%height * SEG_H  + randi()% SEG_H)
		ug_inst.z_index = 1
		dungeon.add_child(ug_inst)

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

func create_segment(segment, pos):
	var seg = Res.segment_nodes[segment].instance()
	seg.position = Vector2(pos.x * SEG_W, pos.y * SEG_H)
	
	for cell in seg.get_node("BottomTiles").get_used_cells():
		if seg.get_node("BottomTiles").get_cellv(cell) == 19:
			map_Uganda.append(Vector2(pos.x*SEG_W, pos.y*SEG_H) + cell * 80)
	
	dungeon.add_child(seg)
	return seg