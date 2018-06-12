extends Area2D

var player_in

enum TYPE{PICKUP, TALK, CRAFT, CRYSTAL}
export(TYPE) var type = 0
enum MODE{BOTH, NO_GHOST, GHOST_ONLY}
export(MODE) var mode = 0
export(bool) var send_status = false

func _ready():
	connect("body_entered", self, "on_enter")
	connect("body_exited", self, "on_exit")

func _physics_process(delta):
	if player_in and icon().visible and Input.is_action_just_pressed("Interact"):
		get_parent().interact()

func on_enter(body):
	if (body.is_in_group("players") or body.is_in_group("ghosts")) and (mode == 0 or (!!body.is_ghost) == (mode == 2)):
		if send_status: get_parent().interact_enter()
		player_in = body
		icon().texture = load("res://Sprites/UI/Interact" + str(type) + ".png")
		icon().visible = true

func on_exit(body):
	if (body.is_in_group("players") or body.is_in_group("ghosts")) and player_in:
		if send_status: get_parent().interact_exit()
		icon().visible = false
		player_in = false

func icon(): if player_in: return player_in.get_node("Interact")