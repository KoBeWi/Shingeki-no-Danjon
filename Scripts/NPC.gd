extends KinematicBody2D

onready var UI = $"/root/Game/Player/Camera/UI"

var id = 0 ##meh

func interact():
	if id == 0: ##całkiem meh
		UI.add_dialogue({name = "Test NPC", text = "Hello there. Remembuh me?", choices = ["ofc", "lol wut?"]})
		UI.add_dialogue({name = "Test NPC", text = "Uh, ok :/"})
	else:
		UI.open_shop("Santa Shop lol", [0, 2])
