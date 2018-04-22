extends "res://Scripts/BaseEnemy.gd"

const HP  = 100
const XP  = 200
const ARM = 0.5

const BASIC_DAMAGE         = 20
const SPECIAL_DAMAGE       = 40

const SPECIAL_PROBABILITY  = 200
const ATACK_SPEED          = 125

const SPEED                = 150

const KNOCKBACK_ATACK      = 3 

const FOLLOW_RANGE         = 400
const PERSONAL_SPACE       = 10
const TIME_OF_LIYUGN_CORPS = 3

var player
var direction       = "Down"
var dead_time       = 0

var can_use_special = true

############################################################################################

var dead            = false
var follow_player   = false
var in_action       = false
var special_ready   = false
var atack_ready     = true

var in_special_state = false
var special_nav_poit = Vector2(0,0)

onready var sprites = $Sprites.get_children()

func _ready():
	._ready()
	drops.append([3, 200])
	if !DEBBUG_RUN : .set_statistics(HP, XP, ARM)
	
	
func calculate_dead(delta):
	dead_time += delta
	if dead_time > TIME_OF_LIYUGN_CORPS: queue_free()

func check_atacks_prepeare():
	if( !special_ready ) : special_ready = (randi()%SPECIAL_PROBABILITY == 0)
	if( !  atack_ready ) : atack_ready   = (randi()%ATACK_SPEED         == 0)

func calculate_move(delta):
		var move = Vector2(sign(player.position.x - position.x), sign(player.position.y - position.y)).normalized() * SPEED * delta
		
		var x_distance = abs(position.x - player.position.x)
		var y_distance = abs(position.y - player.position.y) 

		var axix_X = x_distance >= PERSONAL_SPACE
		var axix_Y = y_distance >= PERSONAL_SPACE
		
		if( x_distance < move.x*SPEED ): move.x = x_distance/SPEED
		if( y_distance < move.y*SPEED ): move.y = y_distance/SPEED
		
		#if( axix_X and axix_Y):
		move_and_slide(move * SPEED)
		
		if axix_X:
			if abs(move.x) != 0: 
				
				sprites[0].flip_h = move.x > 0
				play_animation_if_not_playing("Left")
				direction = "Right" if move.x > 0 else "Left"
#				elif move.x > 0: play_animation_if_not_playing("Right") na później
		elif axix_Y:
			if move.y < 0: 
				play_animation_if_not_playing("Down")
				direction = "Up"
			elif move.y > 0: 
				play_animation_if_not_playing("Up")
				direction = "Down"
		else:
			play_animation_if_not_playing("Down")
			direction = "Down"

func _physics_process(delta):
	._physics_process(delta)
	
	if dead :
		calculate_dead(delta)
		return
		
	if in_special_state:
		in_special_state(delta)
		return
	
	if follow_player and !in_action :
		check_atacks_prepeare()
		calculate_move(delta)
	
		var player_monster_distance_x = abs(position.x - player.position.x) 
		var player_monster_distance_y = abs(position.y - player.position.y) 

		if player_monster_distance_x > FOLLOW_RANGE and player_monster_distance_y > FOLLOW_RANGE:
			follow_player = false
			play_animation_if_not_playing("Idle")
		
			
		if player_monster_distance_x < 79 and player_monster_distance_y < 79:
			if atack_ready: 
				call_normal_atack()

		if player_monster_distance_x < 300 and player_monster_distance_y < 300:
			if special_ready and can_use_special:
				call_special_atack()
		

func move_to_nav_point(delta):
		var move = Vector2(sign(special_nav_poit.x - position.x), sign(special_nav_poit.y - position.y)).normalized() * SPEED * delta
		
		var x_player_monster_distance = abs(position.x - player.position.x)
		var y_player_monster_distance = abs(position.y - player.position.y) 

		var x_distance = abs(position.x - special_nav_poit.x)
		var y_distance = abs(position.y - special_nav_poit.y) 

		if( x_distance < move.x*(SPEED+20) ): move.x = x_distance/(SPEED+20)
		if( y_distance < move.y*(SPEED+20) ): move.y = y_distance/(SPEED+20)
		
		#if( axix_X and axix_Y):
		move_and_slide(move * (SPEED+20))
		
		if move.x == 0 and move.y == 0:
			 in_special_state = false



func in_special_state(delta):
	 play_animation_if_not_playing("Special")
	
	 move_to_nav_point(delta)
	


func call_special_atack():
	in_action = true
	play_animation_if_not_playing("Special")
	damage = SPECIAL_DAMAGE
	knockback = KNOCKBACK_ATACK
	in_special_state = true
	
	if player.position.x > position.x:
		special_nav_poit.x = player.position.x + (player.position.x - position.x)
	else:
		special_nav_poit.x = player.position.x - (position.x - player.position.x)
	
	if player.position.y > position.y:
		special_nav_poit.y = player.position.y + (player.position.y - position.y)
	else:
		special_nav_poit.y = player.position.y - (position.y - player.position.y)
	
	print(special_nav_poit, position)
	
func call_normal_atack():
	in_action = true
	atack_ready = false
	punch_in_direction()
	damage = BASIC_DAMAGE
	knockback = 0

func punch_in_direction():
	play_animation_if_not_playing("Punch" + direction)

func play_animation_if_not_playing(anim):
	if $AnimationPlayer.current_animation != anim:
		$"AnimationPlayer".play(anim)

func _on_Radar_body_entered(body):
	if body.name == "Player":
		follow_player = true;
		player = body

func _on_animation_started(anim_name):
	var anim = $AnimationPlayer.get_animation(anim_name)
	
	if anim and sprites:
		var main_sprite = int(anim.track_get_path(0).get_name(1))
	
		for i in range(sprites.size()):
			sprites[i].visible = (i+1 == main_sprite)

func _on_dead():
	dead = true
	$"AnimationPlayer".play("Dead")
	$"Shape".disabled = true
	$"DamageCollider/Shape".disabled = true
	$"AttackCollider/Shape".disabled = true

func _on_damage():
	pass

func _on_animation_finished(anim_name):
	if anim_name == "Special":
		in_special_state = false
		special_ready = false
		in_action     = false
	if "Punch" in anim_name:
		in_action     = false
