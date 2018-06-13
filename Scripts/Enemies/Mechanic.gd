extends "res://Scripts/BaseEnemy.gd"

var dead = false
var time_of_being_dead  = 0.0
var time_of_using_skill = 0.0
var in_special_state = false
var status = ""
var stacks_of_skill_block = 0
const TIME_OF_BLOCK = 5.0

var points_of_tiredness = 150

const PAYBACK_DMG       = 75
const PAYBACK_KNOCKBACK = 250

var in_action          = false
var BLOCK_PAYBACK      = false
var SUMMON             = true
var FIRE_BOMB          = true

var block_payback_prob = 100
var summon_prob        = 1000
var fire_bomb_prob     = 250

var max_hp = 500

var follow = false

var ar = 0.999
var RShieldON = true
var LShieldON = true

var MAT = load("res://Resources/Materials/ColorShader.tres")
#var MAT_RED  = load("res://Resources/Materials/ColorShader.tres")
# class member variables go here, for example:
# var a = 2
# var b = "textvar"

#var summoned_monsters = 0


func _ready():
	._ready()
	#$"AnimationPlayer".play("Down")
	.set_statistics(max_hp, 10000, 0.99)
	#MAT.set_shader_param("ucolor", Color(0.1, 0.4, 1))
	#MAT_RED .set_shader_param("ucolor", Color(0.8, 0.1, 0))
	# Called every time the node is added to the scene.
	# Initialization here
	$"AttackCollider/Shape".disabled = true
	
	damage = 0
	knockback = 0
	
	$Sprites.material = null
	$"LeftShield/Sprite".material = null
	$"RightShield/Sprite".material = null
	pass

func check_probs():
	if !BLOCK_PAYBACK:
		if randi()%block_payback_prob == 0: BLOCK_PAYBACK = true
	if !SUMMON :
		if randi()%summon_prob        == 0: SUMMON        = true
	if !FIRE_BOMB:
		if randi()%fire_bomb_prob     == 0: FIRE_BOMB     = true

func _process(delta):
	#position += Vector2(0.0, 0.5)
	
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
			
			
	if points_of_tiredness > 100:
		in_action = true
		play_animation_if_not_playing("Tired")
		turn_shields(false)
		return
	
	if !in_action and follow:
		check_probs()
		
		if SUMMON :
			in_action = true
			status  = "Summoning"
			play_animation_if_not_playing("Idle")
			in_special_state = true
			SUMMON = false
			
			Res.play_sample(self, "SummonStart")
			$EfectsAnimator/EfectPlayer.play("Summon")
			return 
		
		if FIRE_BOMB :
			in_action = true
			status  = "Fire"
			play_animation_if_not_playing("Idle")
			in_special_state = true
			FIRE_BOMB = false
			
			
			Res.play_sample(self, "MechanicExplosionInitiate")
			$EfectsAnimator/EfectPlayer.play("FireProof")
			return 
		
		if BLOCK_PAYBACK :
			Res.play_sample(self, "MechanicPaybackInitiate")
			in_action = true
			status = "Payback"
			play_animation_if_not_playing("ShieldBlockON")
			
			in_special_state = true
			BLOCK_PAYBACK = false
			turn_shields(false)
			$EfectsAnimator/Payback.visible = true
			$EfectsAnimator/Payback.frame = 0
			return 
			

	elif in_special_state :
		check_status(delta)
		pass
	
	pass
	
func endAction():
	in_action        = false
	points_of_tiredness += 25
	status = ""
	in_special_state = false
	

func bombing():
	var how_many = randi()%2 + 1
	
	var directionList = [ Vector2(100,100), Vector2(100, -100), Vector2(-90, 90 ), Vector2(-90, -90 ) ] 	
	
	for i in range(how_many):
		var ug_inst = Res.get_node("Projectiles/FireBomb").instance()
		Res.play_sample(ug_inst, "MechanicExplosionMark")
		#ug_inst.position = position + Vector2( 1 * (randi()%50+100), 1 * (randi()%50+100))
		get_parent().add_child(ug_inst)
	
func summoned():
	Res.play_sample(self, "Summon")
	var how_many = randi()%5 + 2
	
	var dis = 120
	
	var directionList = [ Vector2(dis+20, 0 ), Vector2(-dis-20,0), Vector2(0,dis+20), Vector2(0,-dis-20), Vector2(dis,dis), Vector2(dis, -dis), Vector2(-dis, dis ), Vector2(-dis, -dis ) ] 	
	var freeDirerction = [ true,true,true,true,true, true, true, true ]
	
	
	for i in range(how_many):
		var ug_inst = preload("res://Nodes/Projectiles/Summon_Mob.tscn").instance()

		var u = randi()%len(freeDirerction)
		while( !freeDirerction[u] ):
			u = randi()%len(freeDirerction)

		ug_inst.position = position + directionList[u]
		freeDirerction[u] = false
		
		get_parent().add_child(ug_inst)
	
	
func check_status(delta):
	if "ayba" in status :
		time_of_using_skill += delta
		if stacks_of_skill_block >= 3 :
			stacks_of_skill_block = 0
			if damage != PAYBACK_DMG: Res.play_sample(self, "MechanicPayback")
			play_animation_if_not_playing("ShieldBlockPayback")
			damage = PAYBACK_DMG
			knockback = PAYBACK_KNOCKBACK
			
			if RShieldON: $RightShield.visible = false
			if LShieldON: $LeftShield.visible = false
			
			return
		if time_of_using_skill > TIME_OF_BLOCK:
			play_animation_if_not_playing("ShieldBlockOFF")
			return
		pass

func play_animation_if_not_playing(anim, fb = false):
	if $AnimationPlayer.current_animation != anim:
		$"AnimationPlayer".play(anim)
		
	if fb:
		$"AnimationPlayer".play_backwards(anim)

func _on_animation_finished(anim_name):
	#print(anim_name)
	if "ShieldBlockOFF" in anim_name :
		
		time_of_using_skill   = 0.0
		
		in_action        = false
		points_of_tiredness += 30
		status = ""
		in_special_state = false
		
		turn_shields(true)
		
		$EfectsAnimator/Payback.visible = false
		$EfectsAnimator/Payback.frame = 0
		
		damage = 0
		knockback = 0
		
		$"AnimationPlayer".play("Idle")
	if "Payback" in anim_name:
		play_animation_if_not_playing("ShieldBlockOFF")
		status = ""
		in_special_state = false
		turn_shields(true)
		
		$EfectsAnimator/Payback.visible = false
		$EfectsAnimator/Payback.frame = 0
		
		damage = PAYBACK_DMG
		knockback = PAYBACK_KNOCKBACK
		
		if RShieldON:
			$RightShield.visible = true
			
		if LShieldON:
			$LeftShield.visible = true
		
		#play_animation_if_not_playing("ShieldBlockOff")
	if "ShieldBlockON" in anim_name:
		play_animation_if_not_playing("ShieldBlockHOLD")
	if "Tired" in anim_name:
		$"AnimationPlayer".play("Idle")
		points_of_tiredness = 0
		in_action = false
		
		turn_shields(true)
		
	if "Dead" in anim_name:
		$AnimationPlayer.stop()
	pass # replace with function body


func _on_animation_started(anim_name):
	pass # replace with function body


func _on_Radar_body_entered(body):
	if body.name == "Player":
		follow = true;
	pass # replace with function body

func turn_shields( play ):
	
	if play:
		if RShieldON:
			$RightShield/AnimationPlayer.play("Idle")	
		if LShieldON:
			$LeftShield/AnimationPlayer.play("Idle")
	else:
		if RShieldON:
			$RightShield/AnimationPlayer.stop()	
		if LShieldON:
			$LeftShield/AnimationPlayer.stop()
		


func _on_dead():
	dead = true
	play_animation_if_not_playing("Dead")
	$"Shape".disabled = true
	$"DamageCollider/Shape".disabled = true
	$"AttackCollider/Shape".disabled = true
	$"EfectsAnimator".visible = false
	if RShieldON:
		$"RightShield".kill_shield() 
	if LShieldON:
		$"LeftShield".kill_shield() 
	

func _on_damage():
	if "ayback" in status:
		Res.play_sample(self, "MechanicPaybackTrigger")
		stacks_of_skill_block += 1
		if stacks_of_skill_block < 4:
			$EfectsAnimator/Payback.frame = stacks_of_skill_block
	else:
		var fx = Res.create_instance("Effects/MetalHitFX")
		fx.position = (position + Res.game.player.position)/2
		get_parent().add_child(fx)
