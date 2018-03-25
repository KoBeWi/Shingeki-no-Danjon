extends KinematicBody2D

onready var health_bar = $HealthBar

var max_health = 5
var health = 5
var experience = 5
var damage = 10
var knockback = 0

var bar_timeout = 0
var _dead = false

func _ready():
	health = max_health
	health_bar.max_value = max_health
	health_bar.value = health

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
		_dead = true
		health_bar.visible = false
		PlayerStats.add_experience(experience)
		_on_dead()
	else:
		_on_damage()

func _on_attack_hit(collider):
	if collider.get_parent().is_in_group("players"):
		collider.get_parent().damage(self, damage, knockback)