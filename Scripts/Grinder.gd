extends "res://Scripts/BaseEnemy.gd"

func _ready():
	._ready()

func _on_dead():
	queue_free()

func _on_damage():
	print("oof")