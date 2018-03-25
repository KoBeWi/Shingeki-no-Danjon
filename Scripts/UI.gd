extends CanvasLayer

var just_opened = false

func _ready():
	for button in $StatusPanel/AddStat.get_children():
		button.connect("pressed", self, "_on_add_stat", [button.name])
	for button in $StatusPanel/Inventory.get_children():
		button.connect("pressed", self, "_on_inventory_click", [button.get_index()])

func _process(delta):
	if !get_tree().paused: return
	
	if Input.is_action_just_pressed("ui_cancel") and !just_opened:
		$StatusPanel.visible = false
		get_tree().paused = false
	just_opened = false

func enable():
	$StatusPanel.visible = true
	just_opened = true
	refresh()

func refresh():
	$HUD/HealthIndicator.max_value = PlayerStats.max_health
	$HUD/HealthIndicator.value = PlayerStats.health
	$HUD/ManaIndicator.max_value = PlayerStats.max_mana
	$HUD/ManaIndicator.value = PlayerStats.mana
	
	$StatusPanel/Stats/Level.text = str(PlayerStats.level)
	$StatusPanel/Stats/Skillpoints.text =  str(PlayerStats.stat_points)
	$StatusPanel/Stats/Experience.text =  str(PlayerStats.experience)
	var to_next = PlayerStats.total_exp(PlayerStats.level-1) + PlayerStats.exp_to_level(PlayerStats.level)
	$StatusPanel/Stats/ToNext.text =  str(to_next- PlayerStats.experience)
	$StatusPanel/Stats/Strength.text =  str(PlayerStats.strength)
	$StatusPanel/Stats/Dexterity.text =  str(PlayerStats.dexterity)
	$StatusPanel/Stats/Intelligence.text =  str(PlayerStats.intelligence)
	$StatusPanel/Stats/Vitality.text =  str(PlayerStats.vitality)
	
	for button in $StatusPanel/AddStat.get_children():
		button.disabled = (PlayerStats.stat_points == 0)
	
	for i in range(PlayerStats.INVENTORY_SIZE):
		var slot = $StatusPanel/Inventory.get_child(i)
		if PlayerStats.inventory[i] != null:
			slot.disabled = false
			slot.visible = true
			slot.texture_normal = Res.get_item_texture(PlayerStats.inventory[i])
		else:
			slot.disabled = true
			slot.visible = false
			
	for i in range(PlayerStats.equipment.size()):
		var slot = $StatusPanel/Equipment.get_child(i)
		if PlayerStats.equipment[i] > -1:
			slot.visible = true
			slot.texture = Res.get_item_texture(PlayerStats.equipment[i])
		else:
			slot.visible = false

func _on_add_stat(stat):
	PlayerStats[stat.to_lower()] += 1
	SkillBase.inc_stat(stat)
	PlayerStats.stat_points -= 1
	
	PlayerStats.recalc_stats()
	refresh()

func _on_inventory_click(i):
	var item = Res.items[PlayerStats.inventory[i]]
	var slot = PlayerStats.EQUIPMENT_SLOTS.find(item.type)
	
	if slot > -1:
		var old = null
		if PlayerStats.equipment[slot] > -1: old = PlayerStats.equipment[slot]
		PlayerStats.equipment[slot] = item.id
		PlayerStats.inventory[i] = old
		refresh()