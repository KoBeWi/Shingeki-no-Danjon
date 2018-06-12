extends KinematicBody2D

const DEBBUG_RUN = false

onready var health_bar = $HealthBar

var max_health = 5
var health = 5
var experience = 5
var damage = 10
var knockback = 0
var armour = 0

var drops = []

var bar_timeout = 0
var _dead = false

var preparing = false
var flash_time = 0.0
var kolejna_przypadkowa_zmienna_do_jakiegos_pomyslu = 0.0



func _ready():
	health = max_health
	health_bar.max_value = max_health
	health_bar.value = health
	$"/root/Game".perma_state(self, "queue_free")
	$"AnimationPlayer".play("Idle")

func scale_stats_to( max_hp, ar ):
	armour = ar
	var t = float(health)/float(max_health)
	#print("Callculating  :: ",  t , "From :: ", health, " divided by :: ", max_health  )
	health = t*max_hp
	health_bar.max_value = max_hp
	health_bar.value = health
	max_health = max_hp
	
	#print( " Coll :: ", t,"  Max_HP_New :: ",  max_hp," Current_HP ::", health, " new_armour ::", ar )
	

func set_statistics(max_hp, given_exp, ar):
	max_health = max_hp
	health = max_hp
	health_bar.max_value = max_hp
	health_bar.value = health
	experience = given_exp 
	armour = ar

func _physics_process(delta):
	bar_timeout -= 1
	if bar_timeout == 0: health_bar.visible = false
	

func damage(amount):
	if _dead: return
	
	var damage = max(1, int(amount * (1-armour)))
	Res.create_instance("DamageNumber").damage(self, damage)
	health -= damage
	
	health_bar.visible = true
	health_bar.value = health
	bar_timeout = 180
	
	if health <= 0:
		$"/root/Game".save_state(self)
		_dead = true
		health_bar.visible = false
		PlayerStats.add_experience(experience)
		
		z_index -=1
		
		_on_dead()
		
		var drop = get_drop_id()
		
		if drop > -1:
			var item = Res.create_instance("Item")
			item.position = position + Vector2(randi()%60-30,randi()%60-30)
			item.id = drop
			get_parent().add_child(item)
		elif randi() % 1000 < 100:
			var item = Res.create_instance("Money")
			item.position = position + Vector2(randi()%60-30,randi()%60-30)
			get_parent().add_child(item)
	else:
		_on_damage()

func get_drop_id():
	if drops.empty(): return -1
	var nil = 0
	
	var chances = {}
	for drop in drops:
		chances[drop[0]] = drop[1]
		nil += 1000 - drop[1]
	
	chances[-1] = nil
	return Res.weighted_random(chances)

func _on_attack_hit(collider):
	if collider.get_parent().is_in_group("players"):
		collider.get_parent().damage(self, damage, knockback)