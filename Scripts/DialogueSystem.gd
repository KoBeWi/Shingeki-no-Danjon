extends Node

onready var ui = get_parent()

var choice = -1

func _ready():
	get_parent().connect("choice_selected", self, "set_choice")

func dialogue(script):
	var dialogue = Node.new()
	dialogue.set_script(load("res://Resources/Dialogues/" + script + ".vs"))
	add_child(dialogue)
	dialogue.main()
	dialogue.queue_free()

func show_message(_speaker, _message):
	ui.set_dialogue({speaker = _speaker, message = _message})
	yield(ui, "message_closed")

func show_choice(_speaker, question, choice1, choice2, choice3):
	ui.set_dialogue({speaker = _speaker, message = question})
	yield(ui, "choice_selected")
	return choice

func set_choice(i):
	choice = i