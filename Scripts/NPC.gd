extends Node2D

onready var UI = Res.game.player.UI.get_node("DialogueBox")

export var id = 0 ##meh

func interact():
	if id == 0: ##całkiem meh
		UI.initiate_dialogue("TestDialogue")
	elif id == 1: ##całkiem meh meh
		UI.initiate_dialogue("Jigsaw")
	else:
		UI.get_node("../Shop").open_shop("Santa Shop lol", [0, 2])