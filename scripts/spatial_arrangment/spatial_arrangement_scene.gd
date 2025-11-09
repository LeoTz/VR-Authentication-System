extends Node3D

# Preload shape scenes
const COLORED_CUBE = preload("res://scenes/spatial_arrangement/colored_cube.tscn")
const COLORED_SPHERE = preload("res://scenes/spatial_arrangement/colored_sphere.tscn")
const COLORED_CYLINDER = preload("res://scenes/spatial_arrangement/colored_cylinder.tscn")
const COLORED_TORUS = preload("res://scenes/spatial_arrangement/colored_torus.tscn")

# Reference to UI and spawn location
@onready var shape_selector_ui = $ColorSelectionViewport/Viewport/ShapeSelectorUI
@onready var spawn_point = $SpawnPoint
@onready var right_hand = $XROrigin3D/RightHand

# Auto-delete settings
const DELETE_TIMEOUT = 5.0  # Seconds before deleting untouched fallen shapes
const FALL_THRESHOLD_Y = 0.2  # Y position below which shape is considered on the floor

func _ready():
	# Connect to shape selector UI
	if shape_selector_ui:
		shape_selector_ui.shape_color_selected.connect(_on_shape_color_selected)
	else:
		push_error("Shape selector UI not found!")

func _on_shape_color_selected(shape_type: String, color_value: Color):
	# Determine which shape to spawn
	var shape_scene = null
	match shape_type:
		"Cube":
			shape_scene = COLORED_CUBE
		"Sphere":
			shape_scene = COLORED_SPHERE
		"Cylinder":
			shape_scene = COLORED_CYLINDER
		"Torus":
			shape_scene = COLORED_TORUS
		_:
			push_error("Unknown shape type: " + shape_type)
			return
	
	# Instantiate the shape
	var shape = shape_scene.instantiate()
	add_child(shape)
	
	# Position at right hand (with small offset above the hand)
	if right_hand:
		shape.global_position = right_hand.global_position + Vector3(0, 0.15, 0)
	elif spawn_point:
		shape.global_position = spawn_point.global_position
	else:
		shape.global_position = Vector3(0, 1.5, 0)
	
	# Apply color to the shape's material IMMEDIATELY
	_apply_color_to_shape(shape, color_value)
	
	# Start with gravity disabled - enable after a short delay
	if shape is RigidBody3D:
		shape.gravity_scale = 0.0
		# Start monitoring for auto-deletion
		_monitor_shape_for_deletion(shape)
		# Enable gravity after 0.5 seconds to give user time to grab
		await get_tree().create_timer(0.5).timeout
		if is_instance_valid(shape) and shape is RigidBody3D:
			shape.gravity_scale = 1.0

func _apply_color_to_shape(shape: Node3D, color: Color):
	# Find the CSG node and apply color
	for child in shape.get_children():
		if child is CSGShape3D:
			# Create or get material
			var material = child.material
			if not material:
				material = StandardMaterial3D.new()
			else:
				material = material.duplicate()
			
			# Set color
			material.albedo_color = color
			child.material = material
			break

func _monitor_shape_for_deletion(shape: Node3D):
	# Wait for the delete timeout
	await get_tree().create_timer(DELETE_TIMEOUT).timeout
	
	# Check if shape still exists
	if not is_instance_valid(shape):
		return
	
	# Only delete if object has fallen to the floor (below threshold)
	if shape.global_position.y > FALL_THRESHOLD_Y:
		return  # Object is not on the floor, don't delete
	
	# Check if it's locked in a slot
	var is_locked = false
	if "current_slot" in shape and shape.current_slot != null:
		is_locked = true
	
	# Check if it's currently being grabbed
	var is_grabbed = false
	if "is_being_grabbed" in shape:
		is_grabbed = shape.is_being_grabbed
	
	# Only delete if on the floor, not grabbed, and not locked
	if not is_grabbed and not is_locked:
		shape.queue_free()
