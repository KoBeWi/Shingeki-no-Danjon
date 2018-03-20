extends KinematicBody2D

const SPEED = 100
const FOLLOW_RANGE = 400
const TIME_OF_LIYUGN_CORPS = 3
const PERSONAL_SPACE = 42

var player
var dead_time = 0
var dead = false
var follow_player = false

func _physics_process(delta):
	if dead :
		dead_time += delta
		if dead_time > TIME_OF_LIYUGN_CORPS: queue_free()
		return
	
	if follow_player :
		var move = Vector2(sign(player.position.x - position.x), sign(player.position.y - position.y)).normalized() * SPEED * delta
		
		var axix_X = abs(position.x - player.position.x) >= PERSONAL_SPACE
		var axix_Y = abs(position.y - player.position.y) >= PERSONAL_SPACE
		
		if axix_X or axix_Y:
			
			move_and_slide(move * 100)
		
			if axix_X:
				$"Sprite".flip_h = move.x > 0
			
				if move.x != 0: play_animation_if_not_playing("Left")
#				elif move.x > 0: play_animation_if_not_playing("Right") na później
			elif axix_Y:
				if move.y < 0: play_animation_if_not_playing("Down")
				elif move.y > 0: play_animation_if_not_playing("Up")
			else:
				play_animation_if_not_playing("Down")
		else:
			dead = true
			follow_player = false
			$"AnimationPlayer".play("Dead")

		if abs(position.x - player.position.x) > FOLLOW_RANGE and abs(position.y - player.position.y) > FOLLOW_RANGE:
			follow_player = false

func play_animation_if_not_playing(anim):
	if $AnimationPlayer.current_animation != anim:
		$"AnimationPlayer".play(anim)

func _on_Area2D_body_entered(body):
	if body.name == "Player":
		follow_player = true;
		player = body