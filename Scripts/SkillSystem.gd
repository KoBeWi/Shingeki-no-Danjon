extends Node

signal new_skill

var SKILLS = {}

var current_stats = {}
var acquired_skills = []
var acquired_active_skills = {last_size = 0, skills = []}
var acquired_passive_skills = {last_size = 0, skills = []}

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

func get_active_skills():
	if acquired_active_skills.last_size < acquired_skills.size():
		acquired_active_skills.skills.clear()
		acquired_active_skills.last_size = acquired_skills.size()
		
		for skill in acquired_skills:
			if Res.skills[skill].type == "active": acquired_active_skills.skills.append(skill)
	
	return acquired_active_skills.skills

func get_passive_skills():
	if acquired_passive_skills.last_size < acquired_skills.size():
		acquired_passive_skills.skills.clear()
		acquired_passive_skills.last_size = acquired_skills.size()
		
		for skill in acquired_skills:
			if Res.skills[skill].type == "passive": acquired_passive_skills.skills.append(skill)
	
	return acquired_passive_skills.skills

func check_combo(combo):
	if current_combo.size() < combo.size(): return false
	
	for i in range(combo.size()):
		var action = combo[i]
		var long = false
		var hold = false
		
		if action.ends_with("__"):
			long = true
			hold = true
			action = action.left(action.length()-2)
		elif action.ends_with("_"):
			long = true
			action = action.left(action.length()-1)
		
		var prev_action
		if i > 0: prev_action = current_combo[current_combo.size() - combo.size() + i-1]
		var action2 = current_combo[current_combo.size() - combo.size() + i]
		if not ((action2.action == action or action == "Dir" and ["Up", "Right", "Down", "Left"].has(action2.action) or action == "Same" and prev_action and action2.action == prev_action.action) and
			(long or !action2.has("long")) and
			(!hold or action2.hold)): return false
	
	return true

func _process(delta):
	for action in ["Attack", "Magic", "Special", "Up", "Right", "Down", "Left"]:
		if Input.is_action_just_pressed(action):
			current_combo.append({"action": action, "time": OS.get_ticks_msec(), "hold": true})
	
	if !current_combo.empty():
		var action = current_combo.back()
		if Input.is_action_pressed(action.action) and OS.get_ticks_msec() - action.time > LONG_ACTION: action.long = true
		
		if current_combo.size() > MAX_COMBO: current_combo.pop_front()
		if !current_combo.front().hold and OS.get_ticks_msec() - current_combo.front().time > COMBO_TIMEOUT: current_combo.clear()
		for action in current_combo: if Input.is_action_just_released(action.action): action.hold = false