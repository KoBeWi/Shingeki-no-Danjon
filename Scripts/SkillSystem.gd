extends Node

signal new_skill

var SKILLS = {}

var current_stats = {}
var acquired_skills = []

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