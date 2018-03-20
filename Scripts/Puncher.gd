extends "res://Scripts/BaseEnemy.gd"

const SPEED = 100
const FOLLOW_RANGE = 400
const TIME_OF_LIYUGN_CORPS = 3
const PERSONAL_SPACE = 42

var player
var dead_time = 0
var dead = false
var follow_player = false

onready var sprites = $Sprites.get_children()

func _ready():
	._ready()

func _physics_process(delta):
	if dead :
		dead_time += delta
		if dead_time > TIME_OF_LIYUGN_CORPS: queue_free()
		return
	
	if follow_player :
		var move = Vector2(sign(player.position.x - position.x), sign(player.position.y - position.y)).normalized() * SPEED * delta
		
		move_and_slide(move * SPEED)
		
		var axix_X = abs(position.x - player.position.x) >= PERSONAL_SPACE
		var axix_Y = abs(position.y - player.position.y) >= PERSONAL_SPACE
	
		if axix_X:
			sprites[0].flip_h = move.x > 0
		
			if move.x != 0: play_animation_if_not_playing("Left")
#				elif move.x > 0: play_animation_if_not_playing("Right") na później
		elif axix_Y:
			if move.y < 0: play_animation_if_not_playing("Down")
			elif move.y > 0: play_animation_if_not_playing("Up")
		else:
			play_animation_if_not_playing("Down")

		if abs(position.x - player.position.x) > FOLLOW_RANGE and abs(position.y - player.position.y) > FOLLOW_RANGE:
			follow_player = false

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
	dead = true
	follow_player = false
	$"AnimationPlayer".play("Dead")

func _on_damage():
	print("oof")