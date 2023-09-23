extends Sprite2D

@onready var animation_player = $"../AnimationPlayer"

func _ready():
	# We change the color here rather than manually, to save us some work for the rest of the ghosts.
	self.modulate = (get_parent() as Ghost).color
	animation_player.play("moving")
