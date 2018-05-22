extends "res://Scripts/BaseEnemy.gd"

var dead = false
var time_of_being_dead  = 0.0
var time_of_using_skill = 0.0
var in_special_state = false
var status = ""
var stacks_of_skill_block = 0
const TIME_OF_BLOCK = 7.0

var points_of_tiredness = 0


var max_hp = 300

var ar = 0.999
var RShieldON = true
var LShieldON = true

var MAT = load("res://Resources/Materials/ColorShader.tres")
#var MAT_RED  = load("res://Resources/Materials/ColorShader.tres")
# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	._ready()
	$"AnimationPlayer".play("Down")
	.set_statistics(max_hp, 1000, 0.99)
	#MAT.set_shader_param("ucolor", Color(0.1, 0.4, 1))
	#MAT_RED .set_shader_param("ucolor", Color(0.8, 0.1, 0))
	# Called every time the node is added to the scene.
	# Initialization here
	$Sprites.material = null
	$"LeftShield/Sprite".material = null
	$"RightShield/Sprite".material = null#MAT
	pass

func _process(delta):
	position += Vector2(0.0, 0.5)
	
	if dead:
		time_of_being_dead += delta
		if time_of_being_dead > 10.0:
			queue_free()
		return
	
	if RShieldON:
		if $"RightShield".destroyed :
			ar -= 0.125
			.scale_stats_to( max_hp, ar )
			RShieldON = false
	if LShieldON :
		if $"LeftShield".destroyed :
			ar -= 0.125
			.scale_stats_to( max_hp , ar )
			LShieldON = false
			
			
			
	
	#if in_special_state :
	#	check_status(delta)
	
	#if len(status) == 0:
	#	status = "Payback"
	#	play_animation_if_not_playing("ShieldBlockON")
	#	points_of_tiredness += 10
	#	in_special_state = true

#	
	#if points_of_tiredness > 100:
	#	play_animation_if_not_playing("Tired")

# Called every frame. Delta is time since last frame.
#	# Update game logic here.
	pass

func check_status(delta):
	if "ayba" in status :
		#print("check")
		time_of_using_skill += delta
		if stacks_of_skill_block > 3 :
			play_animation_if_not_playing("ShieldBlockPayback")
		if time_of_using_skill > TIME_OF_BLOCK:
			play_animation_if_not_playing("ShieldBlockOFF")
		pass

func play_animation_if_not_playing(anim, fb = false):
	if $AnimationPlayer.current_animation != anim:
		$"AnimationPlayer".play(anim)
		
	if fb:
		$"AnimationPlayer".play_backwards(anim)

func _on_animation_finished(anim_name):
	print(anim_name)
	if "ShieldBlockOFF" in anim_name:
		status = ""
		time_of_using_skill = 0.0
		in_special_state = false
		print("END")
	if "ShieldPayback" in anim_name:
		play_animation_if_not_playing("ShieldBlockOff")
	if "ShieldBlockON" in anim_name:
		play_animation_if_not_playing("ShieldBlockHOLD")
	if "Tired" in anim_name:
		points_of_tiredness = 0
	if "Dead" in anim_name:
		$AnimationPlayer.stop()
	pass # replace with function body


func _on_animation_started(anim_name):
	pass # replace with function body


func _on_Radar_body_entered(body):
	pass # replace with function body


func _on_dead():
	dead = true
	play_animation_if_not_playing("Dead")
	$"Shape".disabled = true
	$"DamageCollider/Shape".disabled = true
	$"AttackCollider/Shape".disabled = true
	if RShieldON:
		$"RightShield".kill_shield() 
	if LShieldON:
		$"LeftShield".kill_shield() 
	

func _on_damage():
	if "ayback" in status:
		stacks_of_skill_block += 1
	pass

