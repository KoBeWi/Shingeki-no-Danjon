extends Node

signal new_skill

var SKILLS = {}

var current_stats = {}
var acquired_skills = []

const MAX_COMBO = 5
const COMBO_TIMEOUT = 2000
const LONG_ACTION = 150
var current_combo = []

func _init():
	var file = File.new()
	file.open("res://Resources/Skill List.json", file.READ)
	var text = file.get_as_text()
	file.close()
	
	SKILLS = parse_json(text)

func inc_stat(stat, amount = 1):
	if current_stats.has(stat):
		current_stats[stat] += amount
	else:
		current_stats[stat] = amount
	
	for skill in SKILLS.keys():
		if acquired_skills.has(skill): continue
		
		var can_has = true
		for cond in SKILLS[skill]:
			var val = get_stat_value(cond["stat"])
			
			if val < cond["value"]:
				can_has = false
				break
		
		if can_has:
			acquired_skills.append(skill)
			emit_signal("new_skill", skill)

func get_stat_value(stat):
	if current_stats.has(stat):
		return current_stats[stat]
	else:
		return 0

func has_skill(skill):
	return acquired_skills.has(skill)

func check_combo(combo):
	if current_combo.size() < combo.size(): return false
	
	for i in range(combo.size()):
		var action = combo[i]
		var long = false
		if action.ends_with("_"):
			long = true
			action = action.left(action.length()-1)
		
		var action2 = current_combo[current_combo.size() - combo.size() + i]
		if not (action2.action == action and action2.has("long") == long): return false
	
	return true

func _process(delta):
	for action in ["Attack", "Magic", "Special", "Up", "Right", "Down", "Left"]:
		if Input.is_action_just_pressed(action):
			current_combo.append({"action": action, "time": OS.get_ticks_msec()})
	
	if !current_combo.empty():
		var action = current_combo.back()
		if Input.is_action_pressed(action.action) and OS.get_ticks_msec() - action.time > LONG_ACTION: action.long = true
		
		if current_combo.size() > MAX_COMBO or OS.get_ticks_msec() - current_combo.front().time > COMBO_TIMEOUT: current_combo.pop_front()