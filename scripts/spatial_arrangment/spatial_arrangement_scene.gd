extends Node3D

# Reference to the cube scene to spawn
const COLORED_CUBE = preload("res://scenes/spatial_arrangement/colored_cube.tscn")

# Spawn position on Table2 (above the table surface)
@onready var spawn_position = Vector3(2.69, 1.2, -0.38)

func _ready():
	# Connect to the color selection UI signal
	var color_ui_viewport = $ColorSelectionViewport
	if color_ui_viewport:
		# Get the scene instance from the viewport
		call_deferred("_connect_to_color_ui")

func _connect_to_color_ui():
	var color_ui_viewport = $ColorSelectionViewport
	if color_ui_viewport and color_ui_viewport.has_node("Viewport/ColorSelectionUI"):
		var color_ui = color_ui_viewport.get_node("Viewport/ColorSelectionUI")
		if color_ui:
			color_ui.color_selected.connect(_on_color_selected)
			print("Connected to color selection UI")
	else:
		# Try alternative path
		await get_tree().create_timer(0.5).timeout
		_try_alternate_connection()

func _try_alternate_connection():
	# Search for the ColorSelectionUI node in the viewport
	var viewports = get_tree().get_nodes_in_group("viewport_2d_in_3d")
	for vp in viewports:
		var ui = vp.get_node_or_null("Viewport/ColorSelectionUI")
		if ui:
			ui.color_selected.connect(_on_color_selected)
			print("Connected to color selection UI (alternate path)")
			return
	
	# Last resort: search entire tree
	var all_nodes = get_tree().get_nodes_in_group("color_selection_ui")
	for node in all_nodes:
		if node.has_signal("color_selected"):
			node.color_selected.connect(_on_color_selected)
			print("Connected to color selection UI (tree search)")
			return

func _on_color_selected(color_name: String, color_value: Color):
	print("Spawning cube with color: ", color_name, " - ", color_value)
	_spawn_cube(color_value)

func _spawn_cube(color: Color):
	# Instantiate a new cube
	var cube = COLORED_CUBE.instantiate()
	
	# Add cube to the scene first
	add_child(cube)
	
	# Set the cube's position on Table2 (higher up)
	cube.global_position = spawn_position
	
	# Temporarily freeze the cube to prevent it from falling through
	cube.freeze = true
	
	# Apply the selected color to the cube's material
	var csg_box = cube.get_node("CSGBox3D")
	if csg_box:
		var material = csg_box.material
		if material:
			material = material.duplicate()
			material.albedo_color = color
			csg_box.material = material
	
	# Unfreeze after a short delay to let physics settle
	await get_tree().create_timer(0.3).timeout
	cube.freeze = false
	
	print("Cube spawned at: ", spawn_position)
