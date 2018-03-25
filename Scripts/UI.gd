extends CanvasLayer

var just_opened = false

func _ready():
	for button in $StatusPanel/AddStat.get_children():
		button.connect("pressed", self, "_on_add_stat", [button.name])

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

func _on_add_stat(stat):
	PlayerStats[stat.to_lower()] += 1
	SkillBase.inc_stat(stat)
	PlayerStats.stat_points -= 1
	
	PlayerStats.recalc_stats()
	refresh()