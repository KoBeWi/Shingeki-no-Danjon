extends "res://Scripts/BaseEnemy.gd"

const HP  = 50
const XP  = 60
const ARM = 0.1

const BASIC_DAMAGE         = 12
const SPECIAL_DAMAGE       = 50

const SPECIAL_PROBABILITY  = 200
const ATACK_SPEED          = 125

const SPEED                = 120

const KNOCKBACK_ATACK      = 3 

const FOLLOW_RANGE         = 400
const PERSONAL_SPACE       = 60
const TIME_OF_LIYUGN_CORPS = 3

var player
var direction       = "Down"
var dead_time       = 0

var can_use_special = true
var dead            = false

var follow_player   = false
var in_action       = false
var special_ready   = false
var atack_ready     = true
var suesided        = false
var last_animation = ""


onready var sprites = $Sprites.get_children()

func _ready():
	._ready()
	drops.append([3, 200])
	drops.append([4,  50])
	drops.append([21, 50])
	if !DEBBUG_RUN : .set_statistics(HP, XP, ARM)

func _physics_process(delta):
	._physics_process(delta)
	
	if dead :
		dead_time += delta
		if dead_time > TIME_OF_LIYUGN_CORPS: queue_free()
		return
	#follow_player  = false
	
	if suesided:
		health = 0
		_on_dead()
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
	
		var player_monster_distance_x = abs(position.x - player.position.x) 
		var player_monster_distance_y = abs(position.y - player.position.y) 

		if player_monster_distance_x > FOLLOW_RANGE and player_monster_distance_y > FOLLOW_RANGE:
			follow_player = false
			play_animation_if_not_playing("Idle")
		
		if player_monster_distance_x < 79 and player_monster_distance_y < 79:
			if special_ready and can_use_special and health <= 0.25 * HP:
				Res.play_sample(self, "Explosion")
				in_action = true
				play_animation_if_not_playing("Special")
				damage = SPECIAL_DAMAGE
				knockback = KNOCKBACK_ATACK
				armour += 0.3
			elif atack_ready:
				in_action = true
				atack_ready = false
				Res.play_sample(self, "Flamethrower")
				punch_in_direction()
				damage = BASIC_DAMAGE
				knockback = 0


func punch_in_direction():
	play_animation_if_not_playing("Punch" + direction)

func play_animation_if_not_playing(anim):
	if $AnimationPlayer.current_animation != anim:
		$"AnimationPlayer".play(anim)

func _on_Area2D_body_entered(body):
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
	$"AnimationPlayer".play("Dead2")
	if suesided : $"AnimationPlayer".play("Dead")
	$"Shape".disabled = true
	$"DamageCollider/Shape".disabled = true
	$"AttackCollider/Shape".disabled = true

func _on_damage():
	follow_player = true
	player = Res.game.player

func _on_animation_finished(anim_name):
	if anim_name == "Special":
		special_ready = false
		in_action     = false
		suesided = true
	if "Punch" in anim_name:
		in_action     = false