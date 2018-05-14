extends "res://Scripts/BaseEnemy.gd"

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	._ready()
	$"AnimationPlayer".play("Dead")
	# Called every time the node is added to the scene.
	# Initialization here
	pass

func _process(delta):
	#position += Vector2(0, 0.5)
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
	pass


func _on_animation_finished(anim_name):
	pass # replace with function body


func _on_animation_started(anim_name):
	pass # replace with function body


func _on_Radar_body_entered(body):
	pass # replace with function body


func _on_dead():
	$"AnimationPlayer".play("Dead")
	$"Shape".disabled = true
	$"DamageCollider/Shape".disabled = true
	$"AttackCollider/Shape".disabled = true

func _on_damage():
	pass

