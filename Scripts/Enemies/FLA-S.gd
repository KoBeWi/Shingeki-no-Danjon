extends "res://Scripts/BaseEnemy.gd"

const HP  = 100
const XP  = 200
const ARM = 0.4

var   BASIC_DAMAGE         = 10
const SPECIAL_DAMAGE       = 0

const MAGIC_PROBABILITY  = 500
var ATACK_SPEED          = 200

var   SPEED                = 100

const KNOCKBACK_ATACK      = 0

const FOLLOW_RANGE         = 400
const PERSONAL_SPACE       = 80
const TIME_OF_LIYUGN_CORPS = 3

var player
var direction       = "Down"
var dead_time       = 0

var can_use_special = true

############################################################################################

var dead            = false
var follow_player   = false
var in_action       = false
var magic_ready     = false
var atack_ready     = true

var last_animation = ""
var in_special_state = false
var special_countown = 0.0

onready var sprites = $Sprites.get_children()

func _ready():
	._ready()
	drops.append([18, 800])
	drops.append([23, 100 ])
	drops.append([21, 400])
	if !DEBBUG_RUN : .set_statistics(HP, XP, ARM)
	$"AnimationPlayer".play("Idle")
	
	
func preparation(delta):
	if preparing :
		flash_time += delta
		
		kolejna_przypadkowa_zmienna_do_jakiegos_pomyslu += 0.6
		if int(kolejna_przypadkowa_zmienna_do_jakiegos_pomyslu)%4 == 0:
			for i in range(sprites.size()):
				sprites[i].modulate = Color(1,10,1,10)
		else:
			for i in range(sprites.size()):
				sprites[i].modulate = Color(1,1,1,1)
		
		if flash_time > 1:
			for i in range(sprites.size()):
				sprites[i].modulate = Color(1,1,1,1)
			flash_time = 0
			preparing = false
		#	if special_ready and can_use_special:
		#		call_special_atack()
		#	else:
			call_normal_atack()
	
func calculate_dead(delta):
	dead_time += delta
	if dead_time > TIME_OF_LIYUGN_CORPS: queue_free()

func check_atacks_prepeare():
	if( !magic_ready and !in_special_state )   : magic_ready   = (randi()%MAGIC_PROBABILITY == 0)
	if( !  atack_ready  )                      : atack_ready   = (randi()%ATACK_SPEED         == 0)

func calculate_move(delta):
		var move = Vector2(sign(player.position.x - position.x), sign(player.position.y - position.y)).normalized() * SPEED * delta
		
		var x_distance = abs(position.x - player.position.x)
		var y_distance = abs(position.y - player.position.y) 

		var axix_X = x_distance >= PERSONAL_SPACE
		var axix_Y = y_distance >= PERSONAL_SPACE
		
		if( x_distance < move.x*SPEED ): move.x = x_distance/SPEED
		if( y_distance < move.y*SPEED ): move.y = y_distance/SPEED
		
		if (axix_X or axix_Y):
			move_and_slide(move * SPEED)
		
		if( x_distance > y_distance and axix_X ):
			if abs(move.x) != 0: 
				sprites[0].flip_h = move.x > 0
				play_animation_if_not_playing("Left")
				last_animation = "Left"
				direction = "Right" if move.x > 0 else "Left"
		elif(x_distance < y_distance and axix_Y):
			if move.y < 0: 
				play_animation_if_not_playing("Down")
				last_animation = "Down"				
				direction = "Up"
			elif move.y > 0: 
				play_animation_if_not_playing("Up")
				last_animation = "Up"			
				direction = "Down"
		else:
			play_animation_if_not_playing(last_animation)
			pass


func _physics_process(delta):
	._physics_process(delta)
	
	if dead :
		calculate_dead(delta)
		return
		
	preparation(delta)
		
	if in_special_state:
		special_countown -=delta
		if special_countown < 0:
			turn_down_special()
			
	if follow_player and !in_action :
		check_atacks_prepeare()
		test_calculate_move(delta)
	
		var player_monster_distance_x = abs(position.x - player.position.x) 
		var player_monster_distance_y = abs(position.y - player.position.y) 

		if player_monster_distance_x > FOLLOW_RANGE and player_monster_distance_y > FOLLOW_RANGE:
			follow_player = false
			play_animation_if_not_playing("Idle")
		
		if magic_ready and can_use_special and !in_special_state:
			call_special_atack()
			return
		
		if player_monster_distance_x < 79 and player_monster_distance_y < 79:
			if atack_ready: 
				preparing = true
	
	elif !in_action:
		play_animation_if_not_playing("Idle")


func in_special_state(delta):
	 pass
	

func turn_down_special():
	Res.play_sample(self, "FLABuffCancel")
	.scale_stats_to(HP, ARM)
	ATACK_SPEED += 50
	BASIC_DAMAGE -= 30
	
	special_countown = 0.0
	SPEED -= 50
	
	in_special_state = false
	in_action = true
	play_animation_if_not_playing("Special", true)


func call_special_atack():
	Res.play_sample(self, "FLABuff")
	in_action = true
	play_animation_if_not_playing("Special")
	damage = SPECIAL_DAMAGE
	knockback = KNOCKBACK_ATACK
	in_special_state = true
	
	.scale_stats_to(120, ARM-0.1)
	ATACK_SPEED -= 50
	BASIC_DAMAGE += 30
	SPEED += 50
	special_countown = 15.0
	
func call_normal_atack():
	Res.play_sample(self, "Sword2")
	in_action = true
	atack_ready = false
	
	damage = BASIC_DAMAGE
	knockback = 0
	
	punch_in_direction()

func punch_in_direction():
	play_animation_if_not_playing("Punch" + direction)

func play_animation_if_not_playing(anim, fb = false):
	if $AnimationPlayer.current_animation != anim:
		$"AnimationPlayer".play(anim)
		
	if fb:
		$"AnimationPlayer".play_backwards(anim)

func _on_Radar_body_entered(body):
	if body.name == "Player": ##MARCIN >:( OD TEGO SĄ GRUPY
		follow_player = true;
		player = body

func _on_animation_started(anim_name):
	var anim = $AnimationPlayer.get_animation(anim_name)
	
	if anim and sprites:
		var main_sprite = int(anim.track_get_path(0).get_name(1))
	
		for i in range(sprites.size()):
			sprites[i].visible = (i+1 == main_sprite)
			if in_special_state : 
				sprites[i].set_modulate(Color(1,0.4, 0.4))
			else:
				sprites[i].set_modulate(Color(1,1,1))

func _on_dead():
	Res.play_sample(self, "RobotCrash")
	dead = true
	in_special_state = false
	$"AnimationPlayer".play("Dead")
	$"Shape".disabled = true
	$"DamageCollider/Shape".disabled = true
	$"AttackCollider/Shape".disabled = true
	
	for i in range(sprites.size()):
		sprites[i].modulate = Color(1,1,1,1)

func _on_damage():
	follow_player = true
	player = Res.game.player
	
	var fx = Res.create_instance("Effects/MetalHitFX")
	fx.position = position - Vector2(0, 40)
	get_parent().add_child(fx)

func _on_animation_finished(anim_name):
	if "Special" in  anim_name :
		magic_ready = false
		in_action     = false
	if "Punch" in anim_name:
		in_action     = false
		
var is_avoiding = false
var avoid_distance = Vector2(0,0)
var avoid_stack    = 1
var acc = Vector2(0,0)
var randomDirection = randi()%2


func test_calculate_move(delta):
	var move = Vector2(sign(player.position.x - position.x + acc.x), sign(player.position.y - position.y+ acc.y)).normalized() * SPEED * delta
		
	var x_distance = abs(position.x - player.position.x)
	var y_distance = abs(position.y - player.position.y) 

	var axix_X = x_distance >= PERSONAL_SPACE
	var axix_Y = y_distance >= PERSONAL_SPACE
		
	if( x_distance < move.x*SPEED ): move.x = x_distance/SPEED
	if( y_distance < move.y*SPEED ): move.y = y_distance/SPEED
	
	if( x_distance > y_distance and axix_X ):
		if abs(move.x) != 0: 
			sprites[0].flip_h = move.x > 0
			play_animation_if_not_playing("Left")
			last_animation = "Left"
			direction = "Right" if move.x > 0 else "Left"
	elif(x_distance < y_distance and axix_Y):
		if move.y < 0: 
			play_animation_if_not_playing("Down")
			last_animation = "Down"				
			direction = "Down"
		elif move.y > 0: 
			play_animation_if_not_playing("Up")
			last_animation = "Up"			
			direction = "Up"
	else:
		play_animation_if_not_playing(last_animation)

	if test_move( get_transform(), move  ):
		
		match direction:
			"Up":
				if( ! test_move( get_transform(), Vector2( 80 , 0) ) ) and !randomDirection: #and  abs(position.x+120 + 90*acc.x/100)  - abs(player.position.x)  <= 0  :
					acc.x += 1
					
				if( ! test_move( get_transform(), Vector2( -80,  0) ) ) and randomDirection: #and  abs(position.x+120-90*acc.x/100) - abs(player.position.x)  >= 0 :
					acc.x += -1
						
			"Down":		
				
				if( ! test_move( get_transform(), Vector2(  80 , 0) ) ) and !randomDirection:# and  abs(position.x+120-90*acc.x/100)  - abs(player.position.x)  <= 0  :
					acc.x += 1
					
				if( ! test_move( get_transform(), Vector2( -80,  0) ) ) and randomDirection:# and  abs(position.x+120-90*acc.x/100) - abs(player.position.x)  >= 0 :
					acc.x += -1
				
			"Left" :
				
				if( ! test_move( get_transform(), Vector2(  0 , 80) ) )and !randomDirection:# and  abs(position.y+120 + 80*acc.y/100)  - abs(player.position.y)  <= 0  :
					acc.y += 1
					
				if( ! test_move( get_transform(), Vector2( 0,  -80) ) ) and randomDirection:# and  abs(position.y+120 - 80*acc.y/100) - abs(player.position.y)  >= 0 :
					acc.y += -1
				
					
			"Right" :
					
				if( ! test_move( get_transform(), Vector2(  0 , 80) ) ) and !randomDirection :#and  abs(position.y+120)  - abs(player.position.y)  <= 0  :
					acc.y += 1
					
				if( ! test_move( get_transform(), Vector2( 0,  -80) ) ) and randomDirection :#and  abs(position.y+120) - abs(player.position.y)  >= 0 :
					acc.y += -1
		
		var repairer = Vector2(0,0)
		
		if direction == "Left": repairer.x -=1
		if direction == "Right": repairer.x +=1
		if direction == "Up": repairer.y +=1
		if direction == "Down": repairer.y -=1
		
		move_and_slide((acc + repairer).normalized() *delta * SPEED * SPEED   )
				
	else :
		move_and_slide( (move + acc.normalized() *delta * SPEED) * SPEED )
		randomDirection = randi()%2
		acc = Vector2(0,0)

