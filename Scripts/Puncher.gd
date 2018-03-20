extends Area2D

# Bugged Seed =  3352953944

var player

var dead = false
var follow_player = false;
var start_position; # miejsce w którym pusher stał jak zobaczył bohatera (updatuje się jeśli gracz wolno ucieka )

const SPEED = 100
const FOLLOW_RANGE = 400


func _ready():
	pass

func _process(delta):
	if dead :
		return
	var move = Vector2(0,0)
	if follow_player :
		
		if( $"..".position.x >  player.position.x ):
			move.x = -1
		if( $"..".position.x <  player.position.x ):
			move.x = 1
		if( $"..".position.y >  player.position.y ):
			move.y = -1
		if( $"..".position.y <  player.position.y ):
			move.y = 1
		
		move = move.normalized() * SPEED * delta
		
		var axix_X = abs($"..".position.x - player.position.x) >= 10
		var axix_Y = abs($"..".position.y - player.position.y) >= 10
		
		
		if( axix_X or axix_Y ):
			$"..".position += move
			#trzeba zabezpieczyć przed scianą
		
			if( axix_X ):
				$"../Sprite".flip_h = move.x > 0
			
				if( move.x < 0 ):
					if( !$"../AnimationPlayer".current_animation == "Left" ) :
						$"../AnimationPlayer".play("Left")
					
				elif( move.x > 0 ):
					if( !$"../AnimationPlayer".current_animation == "Left" ) :
						$"../AnimationPlayer".play("Left")

			else:
				if( axix_Y ):
					if( move.y < 0 ):
						if( !$"../AnimationPlayer".current_animation == "Down" ) :
							$"../AnimationPlayer".play("Down")
					elif( move.y > 0 ):
						if( !$"../AnimationPlayer".current_animation == "Up" ) :
							$"../AnimationPlayer".play("Up")
				else:
						if( !$"../AnimationPlayer".current_animation == "Down" ) :
							$"../AnimationPlayer".play("Down")
		else:
			# Pusher popelnia samobojstwo kiedy zblizy sie do gracza na odleglosc mniejsza niz 10 pixeli w lini prostej
			dead = true;
			follow_player = false;
			$"../AnimationPlayer".play("Dead")

		if( abs($"..".position.x - player.position.x) > FOLLOW_RANGE and abs($"..".position.y - player.position.y) > FOLLOW_RANGE ) :
			follow_player = false;
	pass


func _on_Area2D_body_entered(body):
	if(body.name == "Player"):
		player = body
		follow_player = true;
		start_position = $"..".position
		print("GetSignal")
	if( body.name == "Wall"):
		follow_player = false;
		#Trzeba go zabezpieczyć przed wchodzeniem w sciane.
		
	pass # replace with function body
