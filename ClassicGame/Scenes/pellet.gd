extends Area2D


class_name Pellet

# Pellet Node is connected.
signal pellet_eaten(should_allow_eating_ghosts: bool)

@export var should_allow_eating_ghosts = false

func _on_body_entered(body):
	# Determines which pellets have been eaten
	if body is Player:
		pellet_eaten.emit()
		# queue_free() queues a node for deletion at the end of the current frame.
		queue_free() # Pellet node and its children are "freed" / destroyed
