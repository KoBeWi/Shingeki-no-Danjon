extends StaticBody2D

export(String) var type

onready var player_menu = $"/root/Game/Player/Camera/UI/PlayerMenu"

func interact():
	$"/root/Game".open_menu()
	player_menu.current_tab = 3

func interact_enter():
	player_menu.crafting_station = type

func interact_exit():
	player_menu.crafting_station = null