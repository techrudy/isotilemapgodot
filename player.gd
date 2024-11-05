extends AnimatedSprite2D

const SPEED = 50.0
const TILE_SIZE = Vector2(32, 16)
var movement_target: Vector2  # Renamed from target
var moving = false
var selected_cell: Vector2
var cells: Array[Vector2i]
var astar: AStar2D = AStar2D.new()
var path: Array[Vector2] = []
var current_target_index = 0
var last_movement_direction: Vector2 = Vector2.ZERO  # Renamed from last_direction
const show_debug_line: bool = false
@onready var path_line: Line2D = $"../PathLine"
var last_clicked_cell: Vector2i = Vector2i(-1, -1)

func _ready():
	if Globals.player_x != 0 or Globals.player_y != 0:
		match Globals.player_direction:
			"left":
				position.x = 220  # Define this constant
				position.y = Globals.player_y
			"right":
				position.x = -220  # Define this constant
				position.y = Globals.player_y
			"top":
				position.x = Globals.player_x
				position.y = 130  # Define this constant
			"bottom":
				position.x = Globals.player_x
				position.y = -130  # Define this constant
			_:
				position = Vector2(0, 0)
	else:
		position = Vector2(0, 0)
	
	play(Globals.player_last_animation)
	
	var main_tilemap = $"../Main"  # Reference to the main tilemap layer
	var obstacle_tilemap = $"../Layer1"  # Reference to the additional layer with non-walkable tiles
	
	cells = main_tilemap.get_used_cells()
	
	for i in range(cells.size()):
		var cell = cells[i]
		var main_tile_id = main_tilemap.get_cell_source_id(cell)
		var obstacle_tile_id = obstacle_tilemap.get_cell_source_id(cell)
		
		# Only add the point if it's walkable in the main tilemap and has no obstacle in the other layer
		if main_tile_id == 0 and (obstacle_tile_id == -1 or obstacle_tile_id == 0):
			astar.add_point(i, cell)
			connect_neighbors(i, cell)
	
	path_line.clear_points()  # Clear any existing points

func connect_neighbors(current_id: int, current_cell: Vector2i) -> void:
	var directions = [
		Vector2i(1, 0), Vector2i(-1, 0),
		Vector2i(0, 1), Vector2i(0, -1),
		Vector2i(1, -1), Vector2i(-1, 1),
		Vector2i(1, 1), Vector2i(-1, -1)
	]
	var obstacle_tilemap = $"../Layer1"
	
	for dir in directions:
		var neighbor_cell = current_cell + dir
		var neighbor_id = get_point_id_from_cell(neighbor_cell)
		if neighbor_id != -1:
			if abs(dir.x) == 1 and abs(dir.y) == 1:
				# Check orthogonal cells from both the current cell and neighbor cell
				var curr_adj1 = current_cell + Vector2i(dir.x, 0)
				var curr_adj2 = current_cell + Vector2i(0, dir.y)
				
				# Check if there are obstacles in the adjacent cells
				var obstacle1 = obstacle_tilemap.get_cell_source_id(curr_adj1)
				var obstacle2 = obstacle_tilemap.get_cell_source_id(curr_adj2)
				
				# Only connect if both adjacent cells are walkable and have no obstacles
				if get_point_id_from_cell(curr_adj1) != -1 and \
				   get_point_id_from_cell(curr_adj2) != -1 and \
				   (obstacle1 == -1 or obstacle1 == 0) and \
				   (obstacle2 == -1 or obstacle2 == 0):
					astar.connect_points(current_id, neighbor_id)
			else:
				astar.connect_points(current_id, neighbor_id)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("click"):
		handle_mouse_click()

func handle_mouse_click() -> void:
	var tilemap = $"../Main"
	selected_cell = Vector2i(int(tilemap.local_to_map(get_global_mouse_position() - Vector2(-2, 8)).x),
						int(tilemap.local_to_map(get_global_mouse_position() - Vector2(-2, 8)).y))

	# Convert selected_cell to Vector2i for comparison
	var selected_cell_i = Vector2i(selected_cell.x, selected_cell.y)

	# Check if the new clicked cell is the same as the last clicked cell
	if selected_cell_i == last_clicked_cell:
		return

	# Update last clicked cell
	last_clicked_cell = selected_cell_i

	var selected_cell_id = get_point_id_from_cell(selected_cell)
	var player_position_id = get_point_id_from_cell(tilemap.local_to_map(position))

	if selected_cell_id == -1 or player_position_id == -1:
		print("Invalid target or starting position.")
		return

	# Generate the path using A* if both IDs are valid
	var path_ids = astar.get_id_path(player_position_id, selected_cell_id)
	if path_ids.size() == 0:
		print("No valid path found.")
		return

	path.clear()  # Clear previous path
	path_line.clear_points()  # Clear previous line points

	for id in path_ids:
		# Center the target position on the tile
		path.append(tilemap.map_to_local(get_cell_from_point_id(id)))
		if show_debug_line:
			path_line.add_point(tilemap.map_to_local(get_cell_from_point_id(id)))

	current_target_index = 0
	if path.size() > 1:
		moving = true
		movement_target = path[current_target_index]
				
func is_at_button_boundary(button: Button, direction: String) -> bool:
	match direction:
		"right":
			return position.x >= button.position.x - button.size.x / 2 + 20  # Left edge of right button
		"left":
			return position.x <= (button.position.x + button.size.x / 2) + 20  # Right edge of left button
		"top":
			return position.y <= button.position.y + button.size.y / 2 + 10  # Bottom edge of top button
		"bottom":
			return position.y >= button.position.y - button.size.y / 2 - 5  # Top edge of bottom button
	return false

func _process(delta):
	if moving:
		move_toward_target(delta)
	else:
		path_line.clear_points()
		
func update_z_index() -> void:
	var obstacle_tilemap = $"../Layer1"
	var player_cell = obstacle_tilemap.local_to_map(position)
	
	var _obstacle_cells = obstacle_tilemap.get_used_cells()

	var cell_above = player_cell + Vector2i(-1, -1)
	var cell_below = player_cell + Vector2i(1, 1)

	var obstacle_above_id = obstacle_tilemap.get_cell_source_id(cell_above)
	var obstacle_below_id = obstacle_tilemap.get_cell_source_id(cell_below)

	if obstacle_below_id != -1 and obstacle_below_id != 0:
		z_index = 0
	elif obstacle_above_id != -1 and obstacle_above_id != 0:
		z_index = 1
	else:
		z_index = 1

func move_toward_target(delta: float) -> void:
	update_z_index()
	
	var speed_multiplier: float
	
	if path.size() >= 3:
		speed_multiplier = 1.5  # Double the speed if 4 or more cells away
	else:
		speed_multiplier = 0.7  # Normal speed otherwise

	if position.distance_to(movement_target) > 1:
		var direction = (movement_target - position).normalized()
		position += direction * SPEED * speed_multiplier * delta  # Adjust speed based on distance
		last_movement_direction = direction  # Update the last direction while moving
	else:
		current_target_index += 1
		if current_target_index < path.size():
			movement_target = path[current_target_index]
			var movement_direction = movement_target - position  # Calculate the direction to the next target
			play_animation_for_direction(movement_direction, movement_target)  # Play animation based on movement direction
		else:
			moving = false  # Reached the final target cell
			play_idle_animation(last_movement_direction)  # Play idle animation based on last direction

func play_animation_for_direction(direction: Vector2, target: Vector2) -> void:
	var current_cell = $"../Main".local_to_map(position)
	var next_cell = $"../Main".local_to_map(movement_target)
	
	var movement_offset = Vector2i(next_cell.x - current_cell.x, next_cell.y - current_cell.y)  # Renamed from offset

	if movement_offset == Vector2i(-1, 1):
		play("walk_west")
		Globals.player_last_animation = "standing_west"
	elif movement_offset == Vector2i(1, 1):
		play("walk_south")
		Globals.player_last_animation = "standing_south"
	elif movement_offset == Vector2i(-1, -1):
		play("walk_north")
		Globals.player_last_animation = "standing_north"
	elif movement_offset == Vector2i(1, -1):
		play("walk_east")
		Globals.player_last_animation = "standing_east"
	else:
		if movement_offset == Vector2i(1, 0):
			play("walk_south_east")
			Globals.player_last_animation = "standing_south_east"
		elif movement_offset == Vector2i(-1, 0):
			play("walk_north_west")
			Globals.player_last_animation = "standing_north_west"
		elif movement_offset == Vector2i(0, 1):
			play("walk_south_west")
			Globals.player_last_animation = "standing_south_west"
		elif movement_offset == Vector2i(0, -1):
			play("walk_north_east")
			Globals.player_last_animation = "standing_north_east"


func play_idle_animation(final_direction: Vector2) -> void:
	var tolerance = 0.1
	var x_offset: int
	var y_offset: int
	
	if abs(final_direction.x) > tolerance:
		x_offset = int(sign(final_direction.x))
	else:
		x_offset = 0
		
	if abs(final_direction.y) > tolerance:
		y_offset = int(sign(final_direction.y))
	else:
		y_offset = 0
		
	var movement_offset = Vector2i(x_offset, y_offset)  # Renamed from offset

	# Check for diagonal movements first
	if movement_offset == Vector2i(-1, 1):
		play("standing_south_west")
	elif movement_offset == Vector2i(1, 1):
		play("standing_south_east")
	elif movement_offset == Vector2i(-1, -1):
		play("standing_north_west")
	elif movement_offset == Vector2i(1, -1):
		play("standing_north_east")
	# Check for cardinal directions
	elif movement_offset == Vector2i(1, 0):
		play("standing_east")
	elif movement_offset == Vector2i(-1, 0):
		play("standing_west")
	elif movement_offset == Vector2i(0, 1):
		play("standing_south")
	elif movement_offset == Vector2i(0, -1):
		play("standing_north")


func get_point_id_from_cell(cell: Vector2) -> int:
	var cell_i = Vector2i(cell.x, cell.y)
	return cells.find(cell_i)

func get_cell_from_point_id(id: int) -> Vector2:
	if id in range(cells.size()):
		return cells[id]
	return Vector2(-1, -1)  # Return an invalid position if ID is out of range
