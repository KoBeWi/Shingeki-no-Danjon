extends Node

onready var ui = get_parent()

var dialogue
var message_count = 0
var choice = -1

func _ready():
	get_parent().connect("choice_selected", self, "set_choice")

func dialogue(script):
	message_count = 0
	dialogue = Node.new()
	dialogue.name = "Line0"
	dialogue.set_script(load("res://Resources/Dialogues/" + script + ".vs"))
	add_child(dialogue)
	
	dialogue.main()
	yield(dialogue, "end_dialogue")
	
	dialogue.queue_free()
	dialogue = null
	get_parent().dialogue_finished()

func show_message(_speaker, _message):
	ui.set_dialogue({speaker = _speaker, message = _message})
	yield(ui, "message_closed")
	increment_message()

func show_choice(_speaker, question, choice1, choice2, choice3):
	var _choices = []
	if choice1 != "Null": _choices.append(choice1)
	if choice2 != "Null": _choices.append(choice2)
	if choice3 != "Null": _choices.append(choice3)
#	if choice4 != "Null": _choices.append(choice4)
	ui.set_dialogue({speaker = _speaker, message = question, choices = _choices})
	
	yield(ui, "choice_selected")
	apply_choice()

func increment_message():
	message_count += 1
	dialogue.name = "Line" + str(message_count)

func apply_choice():
	message_count += 1
	dialogue.name = "Line" + char(32 + message_count % 94) + str(choice)

func set_choice(i):
	choice = i