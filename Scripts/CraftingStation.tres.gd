extends StaticBody2D

export(String) var type

onready var player_menu = Res.game.player.UI.get_node("PlayerMenu")

func interact():
	Res.game.open_menu()
	player_menu.current_tab = 3

func interact_enter():
	player_menu.crafting_station = type

func interact_exit():
	player_menu.crafting_station = null