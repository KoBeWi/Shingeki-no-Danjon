extends Node

const INVENTORY_SIZE = 5
const EQUIPMENT_SLOTS = ["helmet", "armor", "boots", "weapon", "shield", "ring", "ring", "boots", "gloves", "amulet"]

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

var money = 0
var inventory = []
var equipment = [-1, -1, -1, -1, -1, -1, -1, -1, -1, -1]
var skill_slots = ["Fireball", null, null]

signal level_up

func _ready():
	inventory.resize(INVENTORY_SIZE)

func get_damage():
	var damage = strength
	var eq = equipment[3]##bez stałej
	
	if eq > -1:
		eq = Res.items[eq]
		
		damage = eq.attack
		for stat in eq.scalling.keys():
			damage += int(PlayerStats[stat] * eq.scalling[stat])
	
	return damage

func get_skill(slot):
	if skill_slots[slot]:
		return Res.skills[skill_slots[slot]]

func recalc_stats():
	max_health = 90 + vitality * 10
	max_mana = 98 + intelligence * 2
	
	health = min(health, max_health)
	mana = min(health, max_mana)

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