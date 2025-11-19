@tool
extends Node3D

# Visual components
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var snap_zone: XRToolsSnapZone = $XRToolsSnapZone

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

func _ready():
	# Don't set up runtime features in editor
	if Engine.is_editor_hint():
		return
	
	# Create materials
	_setup_materials()
	
	_connect_snapzone_signals()
	
	# Set initial material
	if mesh_instance:
		mesh_instance.material_override = normal_material

func _connect_snapzone_signals():
	if not snap_zone:
		push_warning("SnapZone not found in slot %s" % name)
		return

	snap_zone.body_entered.connect(_on_object_entered)
	snap_zone.body_exited.connect(_on_object_exited)
	snap_zone.has_picked_up.connect(_on_object_snapped)
	snap_zone.has_dropped.connect(_on_object_unsnapped)

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

func turn_off_snapzone():
	snap_zone.snap_require = 'temp'

func turn_on_snapzone():
	snap_zone.snap_require = 'Shape'

# --- SnapZone Event Handlers ---

func _on_object_entered(pickable):
	if pickable is XRToolsPickable:
		if is_occupied:
			return
		hovering_cube = pickable
		_update_visual_state()


func _on_object_exited(pickable):
	if pickable is XRToolsPickable:
		if hovering_cube == pickable:
			hovering_cube = null
			_update_visual_state()


func _on_object_snapped(pickable: XRToolsPickable):
	is_occupied = true
	locked_cube = pickable
	hovering_cube = null
	_update_visual_state()
	
	var color_name = _get_shape_color_name(pickable)
	print(color_name, " Cube locked at slot ", grid_position)


func _on_object_unsnapped(pickable: XRToolsPickable):
	if locked_cube == pickable:
		var color_name = _get_shape_color_name(pickable)
		is_occupied = false
		locked_cube = null
		_update_visual_state()
		print(color_name, " Cube unlocked at slot ", grid_position)


func _get_shape_color_name(pickable: XRToolsPickable) -> String:
	if pickable and pickable.get_parent() is Shape:
		var shape = pickable.get_parent() as Shape
		if shape.data:
			match shape.data.color:
				ShapeData.Colors.RED:
					return "RED"
				ShapeData.Colors.GREEN:
					return "GREEN"
				ShapeData.Colors.BLUE:
					return "BLUE"
				ShapeData.Colors.YELLOW:
					return "YELLOW"
				ShapeData.Colors.EMPTY:
					return "EMPTY"
	return "UNKNOWN"


func _update_visual_state():
	if not mesh_instance:
		return
	
	if is_occupied:
		mesh_instance.material_override = occupied_material
	elif hovering_cube:
		mesh_instance.material_override = hover_material
	else:
		mesh_instance.material_override = normal_material
