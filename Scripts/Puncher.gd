extends Area2D

# Bugged Seed =  3352953944

signal i_see_you

var player

var dead = false
var follow_player = false;
var start_position; # miejsce w którym pusher stał jak zobaczył bohatera (updatuje się jeśli gracz wolno ucieka )

const SPEED = 100
const FOLLOW_RANGE = 400


func _ready():
	pass

func _process(delta):			
	pass


func _on_Area2D_body_entered(body):
	if(body.name == "Player"):
		emit_signal("i_see_you", body)
		print("GetSignal")
		#Trzeba go zabezpieczyć przed wchodzeniem w sciane.
		
	pass # replace with function body
