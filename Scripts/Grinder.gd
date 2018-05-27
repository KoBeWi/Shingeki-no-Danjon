extends "res://Scripts/BaseEnemy.gd"

const BASIC_DAMAGE         = 2
const SPECIAL_DAMAGE       = 20

const SPECIAL_PROBABILITY  = 200
const ATACK_SPEED          = 75

const SPEED                = 120

const KNOCKBACK_ATACK      = 0

const FOLLOW_RANGE         = 400
const PERSONAL_SPACE       = 60
const TIME_OF_LIYUGN_CORPS = 3

var player
var direction       = "Down"
var dead_time       = 0

var can_use_special = false
var dead            = false

var follow_player   = false
var in_action       = false
var special_ready   = false
var atack_ready     = false

onready var sprites = $Sprites.get_children()

func _ready():
	._ready()
	drops.append([3, 50])

func _physics_process(delta):
	._physics_process(delta)
	
	if dead :
		dead_time += delta
		if dead_time > TIME_OF_LIYUGN_CORPS: queue_free()
		return
	
	if follow_player and !in_action :
		
		if( !special_ready ) : special_ready = (randi()%SPECIAL_PROBABILITY == 0)
		if( !  atack_ready ) : atack_ready   = (randi()%ATACK_SPEED         == 0)
		
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
				direction = "Right" if move.x > 0 else "Left"
		elif(x_distance < y_distance and axix_Y):
			if move.y < 0: 
				play_animation_if_not_playing("Down")
				direction = "Up"
			elif move.y > 0: 
				play_animation_if_not_playing("Up")
				direction = "Down"
		else:
			play_animation_if_not_playing("Down")
			direction = "Down"
	
		var player_monster_distance_x = abs(position.x - player.position.x) 
		var player_monster_distance_y = abs(position.y - player.position.y) 

		if player_monster_distance_x > FOLLOW_RANGE and player_monster_distance_y > FOLLOW_RANGE:
			follow_player = false
		
		if player_monster_distance_x < 79 and player_monster_distance_y < 79:
			if special_ready and can_use_special:
				in_action = true
				play_animation_if_not_playing("Special")
				damage = SPECIAL_DAMAGE
				knockback = KNOCKBACK_ATACK
			elif atack_ready:
#				print("CHARGE!!!")
				in_action = true
				atack_ready = false
				
				punch_in_direction()
				damage = BASIC_DAMAGE
				knockback = 0
		
		
	elif !in_action:
		play_animation_if_not_playing("Idle")


func punch_in_direction():
	Res.play_sample(self, "Punch")
	if direction == "Right" : 
		sprites[1].flip_h = true
		play_animation_if_not_playing("PunchLeft")
	else:
		sprites[1].flip_h = false
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

func _on_damage():
	follow_player = true
	player = $"../Player"

func _on_animation_finished(anim_name):
	if anim_name == "Special":
		special_ready = false
		in_action     = false
	if "Punch" in anim_name:	 
		in_action     = false
