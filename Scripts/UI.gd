extends CanvasLayer

const SKILL_TIMEOUT = 3

onready var player = $"../.."
onready var status_panel = $Tabs/Inventory
onready var skill_panel = $Tabs/Skills

var just_opened = false
var skill_time = 0

func _ready():
	PlayerStats.connect("level_up", self, "level_up")
	SkillBase.connect("new_skill", self, "new_skill")
	
	for button in status_panel.get_node("AddStat").get_children():
		button.connect("pressed", self, "on_add_stat", [button.name])
	for button in status_panel.get_node("Inventory").get_children():
		button.connect("pressed", self, "on_inventory_click", [button.get_index()])
	for icon in skill_panel.get_node("Icons").get_children():
		icon.connect("mouse_entered", self, "over_skill_icon", [icon.get_index()])
		icon.connect("mouse_exited", self, "out_skill_icon", [icon.get_index()])

func _process(delta):
	if skill_time > 0:
		skill_time -= delta
		$SkillAcquiredPanel.modulate.a = clamp(skill_time / (SKILL_TIMEOUT-1), 0, 1)
		
		if skill_time <= 0:
			$SkillAcquiredPanel.visible = false
			
	if !get_tree().paused: return
	
	if Input.is_action_just_pressed("ui_cancel") and !just_opened:
		$Tabs.visible = false
		get_tree().paused = false
	just_opened = false

func enable():
	$Tabs.visible = true
	just_opened = true
	refresh()

func soft_refresh():
	$HUD/HealthIndicator.max_value = PlayerStats.max_health
	$HUD/HealthIndicator.value = PlayerStats.health
	$HUD/ManaIndicator.max_value = PlayerStats.max_mana
	$HUD/ManaIndicator.value = PlayerStats.mana

func refresh():
	$HUD/HealthIndicator.max_value = PlayerStats.max_health
	$HUD/HealthIndicator.value = PlayerStats.health
	$HUD/ManaIndicator.max_value = PlayerStats.max_mana
	$HUD/ManaIndicator.value = PlayerStats.mana
	
	status_panel.get_node("Stats/Level").text = str(PlayerStats.level)
	status_panel.get_node("Stats/Skillpoints").text =  str(PlayerStats.stat_points)
	status_panel.get_node("Stats/Experience").text =  str(PlayerStats.experience)
	var to_next = PlayerStats.total_exp(PlayerStats.level-1) + PlayerStats.exp_to_level(PlayerStats.level)
	status_panel.get_node("Stats/ToNext").text =  str(to_next- PlayerStats.experience)
	status_panel.get_node("Stats/Strength").text =  str(PlayerStats.strength)
	status_panel.get_node("Stats/Dexterity").text =  str(PlayerStats.dexterity)
	status_panel.get_node("Stats/Intelligence").text =  str(PlayerStats.intelligence)
	status_panel.get_node("Stats/Vitality").text =  str(PlayerStats.vitality)
	
	for button in status_panel.get_node("AddStat").get_children():
		button.disabled = (PlayerStats.stat_points == 0)
	
	for i in range(PlayerStats.INVENTORY_SIZE):
		var slot = status_panel.get_node("Inventory").get_child(i)
		if PlayerStats.inventory[i] != null:
			slot.disabled = false
			slot.visible = true
			slot.texture_normal = Res.get_item_texture(PlayerStats.inventory[i])
		else:
			slot.disabled = true
			slot.visible = false
			
	for i in range(PlayerStats.equipment.size()):
		var slot = status_panel.get_node("Equipment").get_child(i)
		if PlayerStats.equipment[i] > -1:
			slot.visible = true
			slot.texture = Res.get_item_texture(PlayerStats.equipment[i])
		else:
			slot.visible = false
	
	for i in range(skill_panel.get_node("Icons").get_child_count()):
		var icon = skill_panel.get_node("Icons").get_child(i)
		
		if i < SkillBase.acquired_skills.size():
			icon.visible = true
			icon.texture = Res.get_skill_texture(SkillBase.acquired_skills[i])
		else:
			icon.visible = false

func on_add_stat(stat):
	PlayerStats[stat.to_lower()] += 1
	SkillBase.inc_stat(stat)
	PlayerStats.stat_points -= 1
	
	PlayerStats.recalc_stats()
	refresh()

func on_inventory_click(i):
	var item = Res.items[PlayerStats.inventory[i]]
	var slot = PlayerStats.EQUIPMENT_SLOTS.find(item.type)
	
	if slot > -1:
		var old = null
		if PlayerStats.equipment[slot] > -1: old = PlayerStats.equipment[slot]
		PlayerStats.equipment[slot] = item.id
		PlayerStats.inventory[i] = old
		refresh()

func over_skill_icon(i):
	skill_panel.get_node("SkillName").visible = true
	skill_panel.get_node("SkillName").rect_position = get_viewport().get_mouse_position() - $Tabs.rect_position
	skill_panel.get_node("SkillName/Label").text = SkillBase.acquired_skills[i]#Res.skills[SkillBase.acquired_skills[i]].name

func out_skill_icon(i):
	skill_panel.get_node("SkillName").visible = false

func new_skill(skill):
	Res.play_sample(player, "SkillAcquired")
	$"SkillAcquiredPanel".visible = true
	$"SkillAcquiredPanel/Name".text = skill
	skill_time = SKILL_TIMEOUT
	
func level_up():
	Res.play_sample(player, "LevelUp")
	$LevelUpLabel.visible = true
	yield(get_tree().create_timer(1), "timeout")
	$LevelUpLabel.visible = false

func got_item(id):
	$ItemGetPanel/Name.text = Res.items[id].name
	$ItemGetPanel.visible = true
	yield(get_tree().create_timer(1), "timeout")
	$ItemGetPanel.visible = false