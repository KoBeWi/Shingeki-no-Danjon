extends Node

var level = 1
var experience = 0
var stat_points = 0

var health = 100
var max_health = 100
var mana = 100
var max_mana = 100

var strength = 1
var dexterity = 1
var intelligence = 1
var vitality = 1

var inventory = []
var equipment = [-1, -1, -1, -1, -1, -1, -1, -1, -1, -1]
var skill_slots = ["Fireball", null, null]

signal level_up

func get_damage():
	var damage = strength
	if equipment[0] > -1:
		damage = Res.items[equipment[0]].attack
	
	return damage

func get_skill(slot):
	if skill_slots[slot]:
		return Res.skills[skill_slots[slot]]

func recalc_stats():
	max_health = 90 + vitality * 10
	max_mana = 90 + intelligence * 2

func exp_to_level(level):
	return level * 10 + 10
	
func total_exp(level):
	return level * (level+1) * 5 + 10 * level

func add_experience(amount):
	experience += amount
	
	while experience >= total_exp(level-1) + exp_to_level(level):
		level += 1
		stat_points += 1
		emit_signal("level_up")