extends Node

func _ready():
#	VisualServer.set_default_clear_color(Color(0.05, 0.05, 0.07))
	randomize()
	$"Generator".generate()