extends Node
onready var dungeon = $"../Segments"

const SEG_W = 800
const SEG_H = 800
const DIRECTIONS = [Vector2(0, -1), Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0)]
const DOFFSET = [Vector2(1, 0), Vector2(0, 1)]
const OPPOSITE = [2, 3, 0, 1]

const MIN_MAP_SIZE = 25

var disabled = []#["Puncher"] ##DEBUG

var width = 100
var height = 100
var dungeon_type

var empty_spots = []
var segments = []
var map = []
var floor_space = []
var wall_space = []

func generate(w, h):
	width = w
	height = h
	map.resize(width * height)
	dungeon_type = get_parent().dungeon
	var end = false
	
	var start = Vector2(randi() % width, randi() % height)
	empty_spots.append({"pos": start})
	
	while !end:
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
		
		if segments.size() >= MIN_MAP_SIZE:
			end = true
#		elif !segments.empty():
#			remove_segment(segments[randi() % segments.size()])
		else:
			segments.clear()
			map.clear()
			map.resize(width * height)
			start = Vector2(randi() % width, randi() % height)
			empty_spots = [{"pos": start}]
	
	for x in range(width):
		for y in range(height):
			var segment = map[x + y * width]
			if segment and segment.piece_x + segment.piece_y == 0:
				create_segment(segment.segment.name, Vector2(x, y))
	
	var tileset = Res.tilesets[dungeon_type.tileset]
	for segment in dungeon.get_children():
		var bottom = segment.get_node("BottomTiles")
		
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
	
	var wall = wall_space[randi() % wall_space.size()]
	while !wall_space.has(wall + Vector2(-80, 0)): wall = wall_space[randi() % wall_space.size()]
	var stairs = Res.create_instance("Objects/Stairs")
	stairs.position = wall + Vector2(0, 80)
	stairs.set_stairs("up" if dungeon_type.progress != get_parent().from else "down", tileset)
	dungeon.add_child(stairs)
	wall_space.erase(wall)
	wall_space.erase(wall + Vector2(80, 0))
	
	$"../Player".position = wall + Vector2(0, 160)
	
	var wall2 = wall_space[randi() % wall_space.size()]
	while wall.distance_to(wall2) < 800 or !wall_space.has(wall2 + Vector2(-80, 0)): wall2 = wall_space[randi() % wall_space.size()]
	stairs = Res.create_instance("Objects/Stairs")
	stairs.position = wall2 + Vector2(0, 80)
	stairs.set_stairs("up" if dungeon_type.progress == get_parent().from else "down", tileset)
	dungeon.add_child(stairs)
	wall_space.erase(wall2)
	wall_space.erase(wall2 + Vector2(80, 0))
	
	place_containers()
	place_breakables()
	place_enemies()
	for i in range(100): place_on_floor("NPC")

func place_breakables():
	var breakables = dungeon_type.breakables
	
	var nil = 0
	
	var chances = {}
	for item in dungeon_type.breakable_contents:
		chances[item[0]] = item[1]
		nil += 1000 - item[1]
	
	chances[-1] = nil
	
	for i in range(dungeon_type.breakable_count):
		var type = breakables[randi() % breakables.size()]
		var instance = place_on_floor("Objects/" + type)
		if instance: instance.item = int(Res.weighted_random(chances))

func place_containers():
	var containers = dungeon_type.containers
	
	for i in range(dungeon_type.container_count):
		var type = containers[randi() % containers.size()]
		var instance = place_on_floor("Objects/" + type)
		if instance: instance.item = int(Res.weighted_random(dungeon_type.container_contents))

func place_enemies():
	var enemies = dungeon_type.enemies
	
	for i in range(dungeon_type.enemy_count):
		var type = enemies[randi() % enemies.size()]
		var instance = place_on_floor("Enemies/" + type)

func place_on_floor(object):
	for dis in disabled: if object.find(dis) > -1: return ##DEBUG
	if floor_space.empty(): return null
	
	var instance = Res.get_node(object).instance()
	var i = randi() % floor_space.size()
	
	instance.position = floor_space[i] + Vector2(40,40)
	floor_space.remove(i)
	dungeon.get_parent().add_child(instance)
	
	return instance

func place_treasure_into_maze(what, how_many):
	for nmb in range(how_many):
		if floor_space.empty(): break
		
		var ug_inst = what.instance()
		var i = randi()%floor_space.size()
		var temp = floor_space[i]+ Vector2(40,40)
		floor_space.remove(i)
			
		ug_inst.position = temp
		
		dungeon.get_parent().add_child(ug_inst)
		if (what == Res.get_node("Objects/Barrel") and randi()%6 == 0) or what == Res.get_node("Objects/Chest"): ##hack ;_;
			ug_inst.item = randi()%2

	

func place_enemy_into_maze(what, how_many):
	for nmb in range(how_many):
		if floor_space.empty(): break
		
		var ug_inst = what.instance()
		var i = randi()%floor_space.size()
		ug_inst.position = floor_space[i]+ Vector2(40,40)
		floor_space.remove(i)
		dungeon.get_parent().add_child(ug_inst)
		if (what == Res.get_resource("res://Nodes/Objects/Barrel.tscn") and randi()%3 == 0) or what == Res.get_resource("res://Nodes/Objects/Chest.tscn"): ##hack ;_;
			ug_inst.item = randi()%2
		elif what == Res.get_node("NPC") and randi()%3 == 0:
			ug_inst.id = 1
			ug_inst.get_node("Sprite").texture = load("res://Sprites/NPC/Male1Basic.png")


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
				offset = [Vector2(-i, -segment.height + 1), Vector2(0, -i), Vector2(-i, 0), Vector2(-segment.width + 1, -i)][dir]
				
				if can_fit(segment, pos + offset):
					segments.append({"offset": offset, "segment": segment})
		else:
			if can_fit(segment, pos):
				segments.append({"offset": offset, "segment": segment})
	
	return segments

func can_fit(segment, pos):
	var can_be = true
	
	for i in range(4):
		var dim = ["width", "height"][i%2]
		var dim2 = ["width", "height"][1-i%2]
		var piece = ["piece_x", "piece_y"][i%2]
		
		for k in range(segment[dim]):
			var way = segment["ways" + str(i)][k]
			var p = pos + DIRECTIONS[i] * [1, segment[dim2], segment[dim2], 1][i] + DOFFSET[i%2] * k
			var seg = get_segment_data(p)
			
			if way and (p.x < 0 or p.y < 0 or p.x >= width or p.y >= width): can_be = false
			if seg and seg.segment["ways" + str(OPPOSITE[i])][seg[piece]] != way: can_be = false
			
			if !can_be: break
		if !can_be: break
	if !can_be: return false
	
	for x in range(segment.width):
		for y in range(segment.height):
			var p = pos + Vector2(x, y)
			if p.x < 0 or p.y < 0 or p.x >= width or p.y >= width or get_segment(p):
				can_be = false
	
	return can_be

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
			map[pos.x + x + (pos.y + y)  * width] = {"segment": segment, "piece_x": x, "piece_y": y, "pos_x": pos.x, "pos_y": pos.y}
	
	segments.append({"segment": segment, "pos_x": pos.x, "pos_y": pos.y})

func remove_segment(segment):
	for x in range(segment.segment.width):
		for y in range(segment.segment.height):
			map[segment.pos_x + x + (segment.pos_y + y)  * width] = null
	
	empty_spots.append({"pos": Vector2(segment.pos_x, segment.pos_y)})
	segments.erase(segment)

func create_segment(segment, pos):
	var seg = Res.segment_nodes[segment].instance()
	seg.get_node("BottomTiles").tile_set = Res.get_resource("res://Resources/Tilesets/" + dungeon_type.tileset + ".tres")
	seg.get_node("TopTiles").tile_set = Res.get_resource("res://Resources/Tilesets/" + dungeon_type.tileset + ".tres")
	seg.position = Vector2(pos.x * SEG_W, pos.y * SEG_H)
	
	for cell in seg.get_node("BottomTiles").get_used_cells():
		match seg.get_node("BottomTiles").get_cellv(cell):
			19: floor_space.append(Vector2(pos.x*SEG_W, pos.y*SEG_H) + cell * 80)
			10: wall_space.append(Vector2(pos.x*SEG_W, pos.y*SEG_H) + cell * 80)
	
	dungeon.add_child(seg)
	return seg

func reset():
	empty_spots.clear()
	segments.clear()
	map.clear()
	floor_space.clear()
	wall_space.clear()