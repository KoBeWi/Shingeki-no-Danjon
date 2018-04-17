extends KinematicBody2D

onready var UI = $"/root/Game/Player/Camera/UI/DialogueBox"

var id = 0 ##meh

func interact():
	if id == 0: ##całkiem meh
		UI.initiate_dialogue("TestDialogue")
	else:
		UI.get_node("../Shop").open_shop("Santa Shop lol", [0, 2])