tool
extends Node2D

const SKINS = ["Female1Blue", "Female1Brown", "Jigsaw", "Male1Basic", "Male1Glasses", "Male1Old", "Male1Scar"]

var UI

export var dialogue = 0 ##meh
export var skin = 0 setget change_skin

func interact():
	if dialogue == 0: ##całkiem meh
		UI.initiate_dialogue("TestDialogue")
	elif dialogue == 1: ##całkiem meh meh
		UI.initiate_dialogue("Jigsaw")
		get_parent().get_node("Player").addQuest("Hunt")
	else:
		UI.get_node("../Shop").open_shop("Common shop", [2, 32, 33, 34, 35])

func change_skin(new_skin):
	if new_skin >= 0 and new_skin < SKINS.size():
		skin = new_skin
		if has_node("Sprite"): $Sprite.texture = load("res://Sprites/NPC/" + SKINS[skin] + ".png")