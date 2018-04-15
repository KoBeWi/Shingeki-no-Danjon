extends KinematicBody2D

onready var health_bar = $HealthBar

var max_health = 5
var health = 5
var experience = 5
var damage = 10
var knockback = 0

var drops = []

var bar_timeout = 0
var _dead = false

func _ready():
	health = max_health
	health_bar.max_value = max_health
	health_bar.value = health
	$"/root/Game".perma_state(self, "queue_free")

func _physics_process(delta):
	bar_timeout -= 1
	if bar_timeout == 0: health_bar.visible = false

func damage(amount):
	if _dead: return
	Res.create_instance("DamageNumber").damage(self, amount)
	health -= amount
	
	health_bar.visible = true
	health_bar.value = health
	bar_timeout = 180
	
	if health <= 0:
		$"/root/Game".save_state(self)
		_dead = true
		health_bar.visible = false
		PlayerStats.add_experience(experience)
		_on_dead()
		
		var drop = get_drop_id()
		
		if drop > -1:
			var item = Res.create_instance("Item")
			item.position = position
			item.id = drop
			get_parent().add_child(item)
		elif randi() % 1000 < 100:
			var item = Res.create_instance("Money")
			item.position = position
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