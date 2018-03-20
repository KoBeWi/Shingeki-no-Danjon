extends KinematicBody2D

var max_health = 50
var health = 50
var damage = 10

var bar_timeout = 0
var _dead = false

func _ready():
	health = max_health
	$HealthBar.max_value = max_health
	$HealthBar.value = health

func _physics_process(delta):
	bar_timeout -= 1
	if bar_timeout == 0: $HealthBar.visible = false

func damage(amount):
	if _dead: return
	health -= amount
	
	$HealthBar.visible = true
	$HealthBar.value = health
	bar_timeout = 180
	
	if health <= 0:
		_dead = true
		$HealthBar.visible = false
		_on_dead()
	else:
		_on_damage()

func _on_attack_hit(collider):
	if collider.get_parent().is_in_group("players"):
		collider.get_parent().damage(damage)