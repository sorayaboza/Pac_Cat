extends CharacterBody2D

class_name Player

signal player_died(lives: int)


# Vector2 is used to represent 2D floating-point coordinates.
var movement_direction = Vector2.ZERO # Vector2(0, 0): Initialized with all components set to 0.
var next_movement_direction = Vector2.ZERO
var shape_query = PhysicsShapeQueryParameters2D.new() # Provides results for intersect_shape (used in function can_move_in_direction)

@export var speed = 300
@export var start_position: Node2D
@export var lives: int = 2

# OnReady variables
@onready var direction_pointer = $DirectionPointer
@onready var collision_shape_2d = $CollisionShape2D
@onready var animation_player = $AnimationPlayer


func _ready():
	shape_query.shape = collision_shape_2d.shape
	shape_query.collision_mask = 2 # collision_mask is which layers the body will scan for collisions.
	
	animation_player.play("default")
	reset_player()

# When the player is killed, they are sent back to their starting position.
func reset_player():
	animation_player.play("default")
	position = start_position.position
	set_physics_process(true)
	next_movement_direction = Vector2.ZERO
	movement_direction = Vector2.ZERO
	
func _physics_process(delta):
	get_input()
	
	# When a player hits A, S, W, or D, a condition checks if there's a wall in that direction.
	if movement_direction == Vector2.ZERO:
		movement_direction= next_movement_direction
	if can_move_in_direction(next_movement_direction, delta):
		movement_direction = next_movement_direction
	
	velocity = movement_direction * speed
	move_and_slide() # API from node CharacterBody (renamed "Player") for moving objects.
	

func get_input():
	if Input.is_action_pressed("left"):
		next_movement_direction = Vector2.LEFT # Vector2(-1, 0)
		rotation_degrees = 180
		$Sprite2D.flip_h = false
	elif Input.is_action_pressed("right"):
		next_movement_direction = Vector2.RIGHT # Vector2(1, 0)
		rotation_degrees = 180
		$Sprite2D.flip_h = true
	elif Input.is_action_pressed("down"):
		next_movement_direction = Vector2.DOWN # Vector2(0, 1)
		$Sprite2D.flip_h = true
		rotation_degrees = 270
	elif Input.is_action_pressed("up"):
		next_movement_direction = Vector2.UP # Vector2(0, -1)
		$Sprite2D.flip_h = true
		rotation_degrees = 90
		
func can_move_in_direction(dir: Vector2, delta: float) -> bool:
	shape_query.transform = global_transform.translated(dir * speed * delta * 2) # Multiplying by 2 moves it a little further.
	# Result of the query. 
	# intersect_shape checks the intersections of the shape_query object against the space.
	var result = get_world_2d().direct_space_state.intersect_shape(shape_query)
	# result is an array. Inside it, from intersect_shape, is stored any colliding objects.
	# If the result array is empty, this means no colliding objects were stored in it, meaning it didn't hit any colliding objects.
	return result.size() == 0

func die():
	animation_player.play("death")
	set_physics_process(false)


func _on_animation_player_animation_finished(anim_name):
	if anim_name == "death":
		player_died.emit()
		lives -= 1
		if lives != 0:
			reset_player()
		else:
			get_tree().reload_current_scene() # Resets the scene.
