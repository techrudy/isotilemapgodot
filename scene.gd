extends Node2D

var current_button: Button = null
var button_direction: String = ""
var sprite: Sprite2D

func _ready():
	
	sprite = $CharacterBody2D/Sprite2D
	if sprite:
		sprite.visible = false
	
	var buttonRight: Button = $ButtonRight
	var buttonLeft: Button = $ButtonLeft
	var buttonTop: Button = $ButtonTop
	var buttonBottom: Button = $ButtonBottom
	
	$ButtonRight.mouse_entered.connect(func(): _on_button_mouse_entered($ButtonRight, "right"))
	$ButtonLeft.mouse_entered.connect(func(): _on_button_mouse_entered($ButtonLeft, "left"))
	$ButtonTop.mouse_entered.connect(func(): _on_button_mouse_entered($ButtonTop, "top"))
	$ButtonBottom.mouse_entered.connect(func(): _on_button_mouse_entered($ButtonBottom, "bottom"))
	
	$ButtonRight.mouse_exited.connect(func(): _on_button_mouse_exited($ButtonRight))
	$ButtonLeft.mouse_exited.connect(func(): _on_button_mouse_exited($ButtonLeft))
	$ButtonTop.mouse_exited.connect(func(): _on_button_mouse_exited($ButtonTop))
	$ButtonBottom.mouse_exited.connect(func(): _on_button_mouse_exited($ButtonBottom))

	# Set initial opacity
	buttonRight.modulate.a = 0
	buttonLeft.modulate.a = 0
	buttonTop.modulate.a = 0
	buttonBottom.modulate.a = 0
	
func _on_button_mouse_entered(button: Button, direction: String):
	button.modulate.a = 1
	current_button = button
	button_direction = direction
	if sprite:
		sprite.visible = true
		# Set arrow rotation based on direction
		match direction:
			"right": sprite.rotation_degrees = 0
			"left": sprite.rotation_degrees = 180
			"top": sprite.rotation_degrees = -90
			"bottom": sprite.rotation_degrees = 90
	
func _on_button_mouse_exited(button: Button):
	button.modulate.a = 0
	if sprite:
		sprite.visible = false
	current_button = null
	button_direction = ""

func scene_exists(path: String) -> bool:
	return FileAccess.file_exists(path)

func change_scene_if_exists(direction: String) -> void:
	var new_x: int = Globals.current_x
	var new_y: int = Globals.current_y
	if direction == "right":
		new_x += 1
	elif direction == "left":
		new_x -= 1
	elif direction == "top":
		new_y += 1
	elif direction == "bottom":
		new_y -= 1
	var target_scene = "res://scene%d%d.tscn" % [new_x, new_y]
	if scene_exists(target_scene):
		Globals.current_x = new_x
		Globals.current_y = new_y
		Globals.player_x = $Player.position.x
		Globals.player_y = $Player.position.y
		Globals.player_direction = direction
		get_tree().change_scene_to_file(target_scene)

func _process(delta):
	if $Player.is_at_button_boundary($ButtonRight, "right"):
		change_scene_if_exists("right")
	elif $Player.is_at_button_boundary($ButtonLeft, "left"):
		change_scene_if_exists("left")
	elif $Player.is_at_button_boundary($ButtonTop, "top"):
		change_scene_if_exists("top")
	elif $Player.is_at_button_boundary($ButtonBottom, "bottom"):
		change_scene_if_exists("bottom")
	if sprite:
		$CharacterBody2D/Sprite2D.position = get_global_mouse_position()
		if current_button and $CharacterBody2D/Sprite2D.visible:
			var mouse_pos = get_global_mouse_position()
			var sprite = $CharacterBody2D/Sprite2D
			var button_rect = current_button.get_global_rect()
			
			match button_direction:
				"right":
					sprite.global_position.x = button_rect.position.x - 8
					sprite.global_position.y = mouse_pos.y
				"left":
					sprite.global_position.x = button_rect.position.x + button_rect.size.x + 8 
					sprite.global_position.y = mouse_pos.y
				"top":
					sprite.global_position.x = mouse_pos.x
					sprite.global_position.y = button_rect.position.y + button_rect.size.y + 8
				"bottom":
					sprite.global_position.x = mouse_pos.x
					sprite.global_position.y = button_rect.position.y - 8
		
		
