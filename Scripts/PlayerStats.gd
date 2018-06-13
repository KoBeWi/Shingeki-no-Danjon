extends Node

const INVENTORY_SIZE = 1000
const EQUIPMENT_SLOTS = ["amulet", "helmet", "shield", "weapon", "armor", "ring", "boots"]
const SLOTS = {}

var level = 1
var experience = 0
var stat_points = 0

var health = 100
var max_health = 100
var mana = 100
var max_mana = 100

var shield_block = 0.7
var shield_amout = 12

var strength = 1
var dexterity = 1
var intelligence = 1
var vitality = 1

var money = 0
var inventory = []
var equipment = []
var events = {}

signal level_up
signal got_item
signal equipment_changed

func _ready():
	equipment.resize(EQUIPMENT_SLOTS.size())
	for i in range(EQUIPMENT_SLOTS.size()): SLOTS[EQUIPMENT_SLOTS[i]] = i

func get_damage():
	var damage = strength
	var eq = equipment[PlayerStats.SLOTS["weapon"]]
	
	if eq:
		damage_equipment("weapon") ##to nie powinno tu być, oj nie
		eq = Res.items[eq.id]
		
		damage = eq.attack
		for stat in eq.scaling.keys():
			damage += int(PlayerStats[stat] * eq.scaling[stat])
	
	if SkillBase.has_skill("SuperStrength"): damage *= 5
	
	return damage

func get_defense():
	var defense = vitality
	
	for eq in PlayerStats.equipment:
		if !eq: continue
		
		var item = Res.items[eq.id]
		if item.has("defense"): defense += item.defense
	
	return defense

func get_equipment(slot_name):
	return equipment[SLOTS[slot_name]]

func damage_equipment(slot, damage = 1):
	var eq = equipment[SLOTS[slot]]
	if eq:
		eq.durability -= damage
		
		if eq.durability <= 0:
			Res.play_sample(Res.game.player, "ItemBreak")
			equipment[SLOTS[slot]] = null
			emit_signal("equipment_changed")


func count_item(id):
	var amount = 0
	for item in inventory: if item.id == id: amount += item.stack
	return amount

func subtract_items(id, amount):
	var removed_stacks = []
	
	for item in inventory:
		if item.id == id:
			if item.stack >= amount:
				var am = amount
				amount -= am
				item.stack -= am
			else:
				amount = 0
				item.stack = 0
			
			if item.stack == 0: removed_stacks.append(item)
	
	for item in removed_stacks: inventory.erase(item)

func consume(item):
	var consumed
	
	if item.has("health") and PlayerStats.health < PlayerStats.max_health:
		consumed = true
		PlayerStats.health = min(PlayerStats.max_health, PlayerStats.health + item.health)
	if item.has("mana") and PlayerStats.mana < PlayerStats.max_mana:
		consumed = true
		PlayerStats.mana = min(PlayerStats.max_mana, PlayerStats.mana + item.mana)
	
	if consumed:
		Res.play_sample(Res.game.player, "Consume", false)
		return true
	else:
		Res.play_sample(Res.game.player, "MenuFailed", false)

func recalc_stats():
	var mx = max_health
	max_health = 90 + vitality * 10
	health += max_health - mx
	
	mx = max_mana
	max_mana = 98 + intelligence * 2
	mana += max_mana - mx
	
	health = min(health, max_health)
	mana = min(mana, max_mana)

func exp_to_level(level):
	return level * 10 + level * level * 3 + 10
	
func total_exp(level):
	return 3 * pow(level, 3) / 3 + level * (level+1) * 5 + 10 * level

func add_experience(amount):
	experience += amount
	
	while experience >= total_exp(level-1) + exp_to_level(level):
		level += 1
		stat_points += 1
		emit_signal("level_up")

func add_item(id, amount = 1, notify = true): ##dorobić obsługę amount
	
	
	var item = Res.items[id]
	
	var slot = -1
	for i in range(inventory.size()):
		if inventory[i].id == id and item.has("max_stack") and inventory[i].stack < item.max_stack:
			slot = i
			break
	
	if slot > -1:
		inventory[slot].stack += 1
		
	elif inventory.size() < PlayerStats.INVENTORY_SIZE:
		var _item = {"id": id, "stack": 1}
		if item.has("durability"):
			_item.durability = item.durability
			_item.max_durability = item.durability
		
		inventory.append(_item)
	else:
		return false
	
	Res.game.player.updateQuest("",id)
	if notify: emit_signal("got_item", id)
	return true