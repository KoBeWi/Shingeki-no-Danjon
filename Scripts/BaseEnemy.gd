extends KinematicBody2D

var max_health = 50
var health = 50
var damage = 10

var _dead = false

func _ready():
	health = max_health

func damage(amount):
	if _dead: return
	health -= amount
	
	if health <= 0:
		_dead = true
		_on_dead()
	else:
		_on_damage()

func _on_attack_hit(collider):
	if collider.get_parent().is_in_group("players"):
		collider.get_parent().damage(damage)