extends KinematicBody2D


const SPEED = 100
const FOLLOW_RANGE = 400
const TIME_OF_LIYUGN_CORPS = 3
const PERSONAL_SPACE = 42

var dead_time = 0

var player
var start_position; # miejsce w którym pusher stał jak zobaczył bohatera (updatuje się jeśli gracz wolno ucieka )

var dead = false
var follow_player = false;


func _ready():
	pass

func _physics_process(delta):
	if dead :
		dead_time += delta
		if( dead_time > TIME_OF_LIYUGN_CORPS ):
			queue_free()
		return
	if follow_player :
		var move = Vector2(sign(player.position.x - position.x), sign(player.position.y - position.y)).normalized() * SPEED * delta
		
		var axix_X = abs(self.position.x - player.position.x) >= PERSONAL_SPACE
		var axix_Y = abs(self.position.y - player.position.y) >= PERSONAL_SPACE
		
		
		if( axix_X or axix_Y ):
			
			move_and_slide(move * 100)
		
			if( axix_X ):
				$"Sprite".flip_h = move.x > 0
			
				if( move.x < 0 ):
					if( !$"AnimationPlayer".current_animation == "Left" ) :
						$"AnimationPlayer".play("Left")
					
				elif( move.x > 0 ):
					if( !$"AnimationPlayer".current_animation == "Left" ) :
						$"AnimationPlayer".play("Left")

			else:
				if( axix_Y ):
					if( move.y < 0 ):
						if( !$"AnimationPlayer".current_animation == "Down" ) :
							$"AnimationPlayer".play("Down")
					elif( move.y > 0 ):
						if( !$"AnimationPlayer".current_animation == "Up" ) :
							$"AnimationPlayer".play("Up")
				else:
						if( !$"AnimationPlayer".current_animation == "Down" ) :
							$"AnimationPlayer".play("Down")
		else:
			# Pusher popelnia samobojstwo kiedy zblizy sie do gracza na odleglosc mniejsza niz 10 pixeli w lini prostej
			dead = true;
			follow_player = false;
			$"AnimationPlayer".play("Dead")

		if( abs(self.position.x - player.position.x) > FOLLOW_RANGE and abs(self.position.y - player.position.y) > FOLLOW_RANGE ) :
			follow_player = false

func _on_Area2D_body_entered(body):
	if(body.name == "Player"):
		follow_player = true;
		player = body
		start_position = self.position
