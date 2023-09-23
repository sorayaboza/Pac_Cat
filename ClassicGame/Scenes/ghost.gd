extends Area2D

class_name Ghost

enum GhostState {
	SCATTER,
	CHASE
}

signal direction_change(current_direction: String)

var current_scatter_index = 0 # Index for the current target marker, from the scatter_targets array.
var direction = null
var current_state: GhostState

@export var speed = 120
@export var movement_targets: Resource
@export var tile_map: TileMap # Reference for navigation/tile map
@export var color: Color
@export var chasing_target: Node2D
@export var starting_position: Node2D

# Navigation agent used to pathfind to a position.
@onready var navigation_agent_2d = $NavigationAgent2D
@onready var scatter_timer = $ScatterTimer
@onready var update_chasing_target_position_timer = $UpdateChasingTargetPositionTimer

# The starting position is the agents parent position.
func _ready():
	# Set desired distances for path and target.
	navigation_agent_2d.path_desired_distance = 4.0
	navigation_agent_2d.target_desired_distance = 4.0
	
	navigation_agent_2d.target_reached.connect(on_position_reached) # Connect target_reached signal to on_position_reached function.
	call_deferred("setup") # Calls the setup function during idle time, AKA at the end of process & physics frame

func _process(delta):
	# Calculate the distance to the current target marker.
	var current_ghost_position = global_position
	var current_target = movement_targets.scatter_targets[current_scatter_index].position
	var distance_to_target = current_ghost_position.distance_to(current_target)

	# If close enough to the target marker, switch to the next one.
	if distance_to_target <= 4.0:
		on_position_reached()
	
	# Update the ghost's position using pathfinding.
	move_ghost(navigation_agent_2d.get_next_path_position(), delta)

# Calculate the new velocity to move the ghost.
func move_ghost(next_position: Vector2, delta: float):
	var current_ghost_position = global_position # global_position is the distance from the window's (0,0) (top left)
	
	# normalized() sets the vector's length to 1. Vector becomes a unit vector. Useful for representing directions,
	# as it retains the direction of the (next_position - current_ghost_position) vector.
	var new_velocity = (next_position - current_ghost_position).normalized() * speed * delta
	
	calculate_direction(new_velocity)
	
	position += new_velocity # This is what moves the ghost.

func calculate_direction(new_velocity: Vector2):
	var current_direction = direction  # Initialize with the current direction
	
	if abs(new_velocity.x) > abs(new_velocity.y):
		if new_velocity.x > 0:
			current_direction = "right"
		else:
			current_direction = "left"
	else:
		if new_velocity.y > 0:
			current_direction = "down"
		else:
			current_direction = "up"
	
	if current_direction != direction:
		direction = current_direction
		direction_change.emit(direction)


# By default, Godot creates a navigation map RID for the World2D.
# RID is a handle for a Resource's unique identifier. Used to access a resource by its ID.
func setup():
	position = starting_position.position
	# Makes the agent switch between TileMap layer navigation maps, received from get_navigation_map.
	# get_navigation_map returns the NavigationServer2D navigation map RID currently assigned to the TileMap layer.
	navigation_agent_2d.set_navigation_map(tile_map.get_navigation_map(0)) # 0 is the layer.
	
	# NavigationServer2D is the server that handles navigation maps, regions, and agents.
	# agent_set_map puts the agent in the map. Parameters: agent_set_map( RID agent, RID map )
	NavigationServer2D.agent_set_map(navigation_agent_2d.get_rid(), tile_map.get_navigation_map(0))
	scatter()
	
func scatter():
	scatter_timer.start()
	current_state = GhostState.SCATTER
	set_collision_mask_value(1, true)
	
	# Set the target position for the ghost based on the marker coordinates.
	# Red1: (-180, -215), Red2: (-300, -215), Red3: (-300, -311), Red4: (-180, -311)
	navigation_agent_2d.target_position = movement_targets.scatter_targets[current_scatter_index].position

func on_position_reached(): 
	if current_state == GhostState.SCATTER:
		scatter_position_reached()
	elif current_state == GhostState.CHASE:
		chase_position_reached()

func scatter_position_reached():
		# Loop through markers [0, 1, 2, 3].
	if current_scatter_index < 3:
		current_scatter_index += 1
	else: 
		current_scatter_index = 0 # Reset when reaching the last marker.
	# Update the target position to the next marker.
	navigation_agent_2d.target_position = movement_targets.scatter_targets[current_scatter_index].position

func chase_position_reached():
	print("KILL PAC-CAT!")

func _on_scatter_timer_timeout():
	starting_chasing_pacman()
	
func starting_chasing_pacman():
	if chasing_target == null:
		print("ERROR: NO CHASING TARGET. CHASING WILL NOT WORK.")
	current_state = GhostState.CHASE
	update_chasing_target_position_timer.start()
	navigation_agent_2d.target_position = chasing_target.position


func _on_update_chasing_target_position_timer_timeout():
	navigation_agent_2d.target_position = chasing_target.position


func _on_body_entered(body):
	var player = body as Player
	if current_state == GhostState.CHASE || current_state == GhostState.SCATTER:
		set_collision_mask_value(1, false)
		update_chasing_target_position_timer.stop()
		player.die()
		scatter_timer.wait_time = 600
