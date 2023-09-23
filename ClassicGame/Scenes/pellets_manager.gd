extends Node

# Getting the information of all the pellets.
var total_pellets_count
var pellets_eaten = 0

@onready var ui = $"../UI" as UI

func _ready():
	var pellets = self.get_children() as Array[Pellet]
	total_pellets_count = pellets.size()
	for pellet in pellets:
		pellet.pellet_eaten.connect(on_pellet_eaten)

func on_pellet_eaten():
	pellets_eaten += 1
	
	if pellets_eaten == total_pellets_count:
		# Won the game
		ui.game_won()
