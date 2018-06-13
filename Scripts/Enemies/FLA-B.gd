extends "res://Scripts/BaseEnemy.gd"

const HP  = 90
const XP  = 100
const ARM = 0.3

const BASIC_DAMAGE         = 10
const SPECIAL_DAMAGE       = 20

const SPECIAL_PROBABILITY  = 200
const ATACK_SPEED          = 200

const SPEED                = 80

const KNOCKBACK_ATACK      = 0

const FOLLOW_RANGE         = 400
const PERSONAL_SPACE       = 50
const TIME_OF_LIYUGN_CORPS = 3

var player
var direction       = "Down"
var dead_time       = 0

var can_use_special = true

############################################################################################

var wertical        = -1
var distance_from_player = 300

var dead            = false
var follow_player   = false
var in_action       = false
var special_ready   = false
var atack_ready     = true

var in_special_state = false
var special_nav_poit = Vector2(0,0)

onready var sprites = $Sprites.get_children()

func preparation(delta):
	if preparing :
		flash_time += delta
		
		kolejna_przypadkowa_zmienna_do_jakiegos_pomyslu += 0.5
		if int(kolejna_przypadkowa_zmienna_do_jakiegos_pomyslu)%2 == 0:
			for i in range(sprites.size()):
				sprites[i].modulate = Color(10,10,10,1) if !special_ready else Color(10,1,1,1)
		else:
			for i in range(sprites.size()):
				sprites[i].modulate = Color(1,1,1,1)
		
		if flash_time > 0.3:
			for i in range(sprites.size()):
				sprites[i].modulate = Color(1,1,1,1)
			flash_time = 0
			preparing = false
			if special_ready and can_use_special:
				call_special_atack()
			else:
				call_normal_atack()

func _ready():
	._ready()
	drops.append([18, 400])
	drops.append([20, 500])
	drops.append([25, 500])
	if !DEBBUG_RUN : .set_statistics(HP, XP, ARM)
	$"AnimationPlayer".play("Idle")
	
	
func calculate_dead(delta):
	dead_time += delta
	if dead_time > TIME_OF_LIYUGN_CORPS: queue_free()

func check_atacks_prepeare():
	if( !special_ready ) : special_ready = (randi()%SPECIAL_PROBABILITY == 0)
	if( !  atack_ready ) : atack_ready   = (randi()%ATACK_SPEED         == 0)

func calculate_move(delta):
	
		var x_distance = abs(position.x - player.position.x)
		var y_distance = abs(position.y - player.position.y) 
	
		var move = Vector2(0,0)
	
		var second_vertical = 0
		var first_vertical = 0
	
		if x_distance <= y_distance : 
			second_vertical = y_distance - distance_from_player
			if( player.position.y - position.y < 0 ):
				second_vertical *= -1
			if( abs(second_vertical) < 2 ): second_vertical = 0
			move = Vector2(sign(player.position.x - position.x),sign(second_vertical)).normalized() * SPEED * delta
			
			if( x_distance < move.x*SPEED ): move.x = x_distance/SPEED
			if( y_distance < move.y*SPEED ): move.y = y_distance/SPEED
			
			first_vertical = move.x
		else :
			second_vertical = x_distance - distance_from_player
			if( player.position.x - position.x < 0 ):
				second_vertical *= -1
			if( abs(second_vertical) < 2 ): second_vertical = 0
			move = Vector2(sign(second_vertical), sign(player.position.y - position.y)).normalized() * SPEED * delta
			
			if( x_distance < move.x*SPEED ): move.x = x_distance/SPEED
			if( y_distance < move.y*SPEED ): move.y = y_distance/SPEED
			
			first_vertical = move.y
			
		var axix_X = x_distance >= PERSONAL_SPACE
		var axix_Y = y_distance >= PERSONAL_SPACE
		
		
		if (axix_X or axix_Y):
			move_and_slide(move * SPEED)
		
		if( x_distance > y_distance and axix_X ):
			if abs(move.x) != 0: 
				sprites[0].flip_h = move.x > 0
				play_animation_if_not_playing("Left")
		elif(x_distance < y_distance and axix_Y):
			if move.y < 0: 
				play_animation_if_not_playing("Down")
			elif move.y > 0: 
				play_animation_if_not_playing("Up")
		else:
			play_animation_if_not_playing("Down")
			direction = "Down"
		
		#print( second_vertical, " ", first_vertical)
		
		if( second_vertical == 0 and abs(first_vertical) < 0.5 ) : play_animation_if_not_playing("Idle")
		
		if( player.position.x > position.x and x_distance > y_distance ): direction = "Right"
		if( player.position.x < position.x and x_distance > y_distance ): direction = "Left"
		if( player.position.y > position.y and x_distance < y_distance ): direction = "Up"
		if( player.position.y < position.y and x_distance < y_distance ): direction = "Down"
		
	

func _physics_process(delta):
	._physics_process(delta)
	
	if dead :
		calculate_dead(delta)
		return
	
	preparation(delta)
	
	if follow_player and !in_action :
		check_atacks_prepeare()
		calculate_move(delta)
	
		var player_monster_distance_x = abs(position.x - player.position.x) 
		var player_monster_distance_y = abs(position.y - player.position.y) 

			
		if( abs(player.position.x - position.x) < 10 or abs(player.position.y - position.y) < 10 ):
			if special_ready and can_use_special:
				preparing = true
			elif atack_ready: 
				preparing = true
				
		if player_monster_distance_x > FOLLOW_RANGE and player_monster_distance_y > FOLLOW_RANGE:
			follow_player = false
			play_animation_if_not_playing("Idle")
				
	elif !in_action:
		play_animation_if_not_playing("Idle")

			
		

func in_special_state(delta):
	 play_animation_if_not_playing("Special" + direction)


func shoot_arrow():
	Res.play_sample(self, "Arrow")
	var projectile = Res.create_instance("Projectiles/FireArrow")
	get_parent().add_child(projectile)
	projectile.position  = position + Vector2(0, -40)  #+ Vector2(100,100)
	
	match direction:
		"Left":
			projectile.direction = 3
		"Right":
			projectile.direction = 1
		"Up":
			projectile.direction = 2
		#	projectile.position  = position + Vector2(0, 20) 
		"Down":
			projectile.direction = 0
		#	projectile.position  = position + Vector2(0, -20) 
	
	
	projectile.intiated()
	projectile.damage = BASIC_DAMAGE

func shoot_arrows():
	Res.play_sample(self, "MultiArrow")
	var rotation = -15
	 
	var arrows = []
	for i in range(3):
		arrows.append(Res.create_instance("Projectiles/FireArrow"))
		
	for arrow in arrows:
		get_parent().add_child(arrow)
		arrow.position  = position + Vector2(0, -40)  #+ Vector2(100,100)
		
		match direction:
			"Left":
				arrow.new_dir(3)
				arrow.set_rot(-rotation)
			#	print("lefy")
			"Right":
				arrow.new_dir(1)
				arrow.set_rot(-rotation)
			"Up":
				arrow.new_dir(2)
				arrow.set_rot(-rotation)
			"Down":
				arrow.new_dir(0)
				arrow.set_rot(rotation)
				
		rotation += 15
		

	
	match direction:
		"Left":
			arrows[0].position -= Vector2(0,30) 
			arrows[0].set_mod( Vector2(0,-0.3) )
			arrows[2].position += Vector2(0,30)
			arrows[2].set_mod( Vector2(0,0.3) )
		"Right":
			arrows[2].position -= Vector2(0,30) 
			arrows[2].set_mod( Vector2(0,-0.3) )
			arrows[0].position += Vector2(0,30)
			arrows[0].set_mod( Vector2(0,0.3) )
		"Up":
			arrows[0].set_mod( Vector2(-0.3,0) )
			arrows[0].position -= Vector2(40,0) 
			arrows[2].set_mod( Vector2(0.3,0) )
			arrows[2].position += Vector2(40,0)
		"Down":
			arrows[0].set_mod( Vector2(-0.3,0) )
			arrows[0].position -= Vector2(30,0) 
			arrows[2].set_mod( Vector2(0.3,0) )
			arrows[2].position += Vector2(30,0)
				
	for arrow in arrows:
		arrow.intiated()
		arrow.damage = SPECIAL_DAMAGE
		

func call_special_atack():
	in_action = true
	play_animation_if_not_playing("Special" + direction)
	damage = SPECIAL_DAMAGE
	knockback = KNOCKBACK_ATACK
	
	
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
	Res.play_sample(self, "RobotCrash")
	dead = true
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
	if "Special" in anim_name:
	#	in_special_state = false
		special_ready = false
		in_action     = false
	if "Punch" in anim_name:
		in_action     = false
