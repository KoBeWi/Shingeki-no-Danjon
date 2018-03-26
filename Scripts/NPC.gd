extends KinematicBody2D

onready var UI = $"/root/Game/Player/Camera/UI"

func interact():
	UI.add_dialogue({name = "Test NPC", text = "Hello there. Remembuh me?", choices = ["ofc", "lol wut?"]})
	UI.add_dialogue({name = "Test NPC", text = "Uh, ok :/"})
