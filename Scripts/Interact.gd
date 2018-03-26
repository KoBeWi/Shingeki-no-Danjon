extends Area2D

var player_in
onready var icon = $"/root/Game/Player/Interact"

func _ready():
	connect("body_entered", self, "on_enter")
	connect("body_exited", self, "on_exit")

func _physics_process(delta):
	if player_in and icon.visible and Input.is_action_just_pressed("Interact"):
		get_parent().interact()

func on_enter(body):
	if body.is_in_group("players"):
		icon.visible = true
		player_in = true

func on_exit(body):
	if body.is_in_group("players"):
		icon.visible = false
		player_in = false