extends Panel

var just_opened = false

func _ready():
	for button in $AddStat.get_children():
		button.connect("pressed", self, "_on_add_stat", [button.name])

func _process(delta):
	if !get_tree().paused: return
	
	if Input.is_action_just_pressed("ui_cancel") and !just_opened:
		visible = false
		get_tree().paused = false
	just_opened = false

func enable():
	visible = true
	just_opened = true
	refresh()

func refresh():
	$Stats/Level.text = str(PlayerStats.level)
	$Stats/Skillpoints.text =  str(PlayerStats.stat_points)
	$Stats/Experience.text =  str(PlayerStats.experience)
	var to_next = PlayerStats.total_exp(PlayerStats.level-1) + PlayerStats.exp_to_level(PlayerStats.level)
	$Stats/ToNext.text =  str(to_next- PlayerStats.experience)
	$Stats/Strength.text =  str(PlayerStats.strength)
	$Stats/Dexterity.text =  str(PlayerStats.dexterity)
	$Stats/Intelligence.text =  str(PlayerStats.intelligence)
	$Stats/Vitality.text =  str(PlayerStats.vitality)
	
	for button in $AddStat.get_children():
		button.disabled = (PlayerStats.stat_points == 0)

func _on_add_stat(stat):
	PlayerStats[stat.to_lower()] += 1
	SkillBase.inc_stat(stat)
	PlayerStats.stat_points -= 1
	
	refresh()