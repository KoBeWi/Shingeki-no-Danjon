extends CanvasLayer

onready var player = $"../.."

var just_opened = false

func _ready():
	PlayerStats.connect("level_up", $LevelUpLabel, "level_up")
	PlayerStats.connect("got_item",$ItemGetPanel, "got_item")
	SkillBase.connect("new_skill", $SkillAcquiredPanel, "new_skill")
	DungeonState.connect("floor_changed", $FloorLabel, "new_floor")

func _physics_process(delta):
	if !get_tree().paused: return
	
	if !$DialogueBox.process():
		if Input.is_action_just_pressed("Menu") and !just_opened:
			$"/root/Game".leave_menu = true
			$PlayerMenu.visible = false
			$Shop.visible = false
			$HUD.visible = true
			get_tree().paused = false
	
	just_opened = false

func enable():
	$PlayerMenu.visible = true
	$HUD.visible = false
	just_opened = true
	refresh()

func soft_refresh():
	$HUD/HealthIndicator.max_value = PlayerStats.max_health
	$HUD/HealthIndicator.value = PlayerStats.health
	$HUD/ManaIndicator.max_value = PlayerStats.max_mana
	$HUD/ManaIndicator.value = PlayerStats.mana

func refresh():
	soft_refresh()
	
#	status_panel.get_node("Stats/Level").text = str(PlayerStats.level)
#	status_panel.get_node("Stats/Skillpoints").text =  str(PlayerStats.stat_points)
#	status_panel.get_node("Stats/Experience").text =  str(PlayerStats.experience)
#	var to_next = PlayerStats.total_exp(PlayerStats.level-1) + PlayerStats.exp_to_level(PlayerStats.level)
#	status_panel.get_node("Stats/ToNext").text =  str(to_next- PlayerStats.experience)
#	status_panel.get_node("Stats/Strength").text =  str(PlayerStats.strength)
#	status_panel.get_node("Stats/Dexterity").text =  str(PlayerStats.dexterity)
#	status_panel.get_node("Stats/Intelligence").text =  str(PlayerStats.intelligence)
#	status_panel.get_node("Stats/Vitality").text =  str(PlayerStats.vitality)
#	status_panel.get_node("Money/Amount").text =  str(PlayerStats.money)
#
#	for button in status_panel.get_node("AddStat").get_children():
#		button.disabled = (PlayerStats.stat_points == 0)
#
#	for i in range(PlayerStats.INVENTORY_SIZE):
#		var slot = status_panel.get_node("Inventory").get_child(i)
#		if PlayerStats.inventory[i] != null:
#			slot.disabled = false
#			slot.visible = true
#			slot.texture_normal = Res.get_item_texture(PlayerStats.inventory[i].id)
#			slot.get_node("Amount").text = str(PlayerStats.inventory[i].stack)
#		else:
#			slot.disabled = true
#			slot.visible = false
#
#	for i in range(PlayerStats.equipment.size()):
#		var slot = status_panel.get_node("Equipment").get_child(i)
#		if PlayerStats.equipment[i] > -1:
#			slot.visible = true
#			slot.texture = Res.get_item_texture(PlayerStats.equipment[i])
#		else:
#			slot.visible = false
#
#	for i in range(skill_panel.get_node("Icons").get_child_count()):
#		var icon = skill_panel.get_node("Icons").get_child(i)
#
#		if i < SkillBase.acquired_skills.size():
#			icon.visible = true
#			icon.texture = Res.get_skill_texture(SkillBase.acquired_skills[i])
#		else:
#			icon.visible = false

func on_add_stat(stat):
	PlayerStats[stat.to_lower()] += 1
	SkillBase.inc_stat(stat)
	PlayerStats.stat_points -= 1
	
	PlayerStats.recalc_stats()
	refresh()

func on_inventory_click(i):
	var item = Res.items[PlayerStats.inventory[i].id]
	
	if item.type == "consumable":
		Res.play_sample(player, "Consume", false)
		PlayerStats.inventory[i] = null
		PlayerStats.health += item.health
		refresh()
	else:
		var slot = PlayerStats.EQUIPMENT_SLOTS.find(item.type)
		
		if slot > -1:
			var old = null
			if PlayerStats.equipment[slot] > -1: old = PlayerStats.equipment[slot]
			PlayerStats.equipment[slot] = item.id
			
			if old != null: PlayerStats.inventory[i] = {"id": old, "stack": 1}
			else: PlayerStats.inventory[i] = null
			
			if slot == 3:
				player.update_weapon()
		refresh()