extends CanvasLayer

class_name UI

@onready var center_container = $MarginContainer/CenterContainer

func game_won():
	center_container.show()
