@tool
extends Node3D

# Visual components
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var detection_area: Area3D = $DetectionArea

# Slot state
var is_occupied: bool = false
var locked_cube: RigidBody3D = null
var hovering_cube: RigidBody3D = null

# Materials
var normal_material: StandardMaterial3D
var hover_material: StandardMaterial3D
var occupied_material: StandardMaterial3D

# Grid position
var grid_position: Vector3i = Vector3i.ZERO

signal cube_locked(slot, cube)
signal cube_unlocked(slot, cube)
signal hover_started(slot, cube)
signal hover_ended(slot, cube)

func _ready():
	# Don't set up runtime features in editor
	if Engine.is_editor_hint():
		return
	
	# Create materials
	_setup_materials()
	
	# Note: We don't connect Area3D signals anymore
	# The cube controls the hover state directly
	
	# Set initial material
	if mesh_instance:
		mesh_instance.material_override = normal_material

func _setup_materials():
	# Normal state: light blue, very translucent
	normal_material = StandardMaterial3D.new()
	normal_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	normal_material.albedo_color = Color(0.5, 0.7, 1, 0.15)
	normal_material.metallic = 0.0
	normal_material.roughness = 0.8
	normal_material.rim_enabled = true
	normal_material.rim = 0.5
	normal_material.rim_tint = 0.8
	
	# Hover state: bright green, much more visible
	hover_material = StandardMaterial3D.new()
	hover_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hover_material.albedo_color = Color(0.2, 1.0, 0.3, 0.25)  # Bright green, subtle opacity
	hover_material.metallic = 0.2
	hover_material.roughness = 0.5
	hover_material.rim_enabled = true
	hover_material.rim = 1.0  # Moderate rim
	hover_material.rim_tint = 1.0
	hover_material.emission_enabled = true
	hover_material.emission = Color(0.2, 0.8, 0.3, 1.0)  # Green glow
	hover_material.emission_energy_multiplier = 1.0
	
	# Occupied state: orange, very subtle
	occupied_material = StandardMaterial3D.new()
	occupied_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	occupied_material.albedo_color = Color(1, 0.6, 0.2, 0.15)  # Orange, very subtle opacity
	occupied_material.metallic = 0.1
	occupied_material.roughness = 0.6
	occupied_material.rim_enabled = true
	occupied_material.rim = 0.6
	occupied_material.rim_tint = 0.8
	occupied_material.emission_enabled = true
	occupied_material.emission = Color(1.0, 0.5, 0.1, 1.0)  # Orange glow
	occupied_material.emission_energy_multiplier = 0.5

func set_hovering_cube(cube: RigidBody3D):
	if hovering_cube == cube:
		return
	
	var old_cube = hovering_cube
	hovering_cube = cube
	
	if old_cube:
		hover_ended.emit(self, old_cube)
	
	if cube:
		hover_started.emit(self, cube)
		print("Slot ", grid_position, " now hovering")
	
	_update_visual_state()

func _update_visual_state():
	if not mesh_instance:
		return
	
	if is_occupied:
		mesh_instance.material_override = occupied_material
	elif hovering_cube:
		mesh_instance.material_override = hover_material
	else:
		mesh_instance.material_override = normal_material

func lock_cube(cube: RigidBody3D):
	if is_occupied or not cube:
		return false
	
	locked_cube = cube
	is_occupied = true
	hovering_cube = null
	
	# Snap cube to slot center
	cube.global_position = global_position
	
	# Reset cube rotation to match slot (identity rotation)
	cube.global_rotation = global_rotation
	
	# Freeze the cube completely - no gravity, no movement
	cube.freeze = true
	cube.gravity_scale = 0.0
	
	# Update visual
	_update_visual_state()
	
	# Emit signal
	cube_locked.emit(self, cube)
	
	print("Cube locked at slot ", grid_position)
	
	return true

func unlock_cube():
	if not is_occupied or not locked_cube:
		return null
	
	var cube = locked_cube
	locked_cube = null
	is_occupied = false
	
	# Unfreeze the cube and restore gravity
	cube.freeze = false
	cube.gravity_scale = 1.0
	
	# Update visual
	_update_visual_state()
	
	# Emit signal
	cube_unlocked.emit(self, cube)
	
	return cube

func get_hovering_cube() -> RigidBody3D:
	return hovering_cube

func is_cube_hovering() -> bool:
	return hovering_cube != null
