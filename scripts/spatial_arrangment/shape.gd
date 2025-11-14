extends Node3D
class_name Shape

const CUBE = preload("uid://cy2q6kfcih4gr")
const TORUS = preload("uid://dxs4dp7ewbwg8")
const SPHERE = preload("uid://h5ixyu701hg7")
const CYLINDER = preload("uid://fa52g5uavh3n")

# Auto-deletion settings
const DELETION_TIMEOUT = 10.0  # Seconds of inactivity before deletion
const DELETION_HEIGHT = 0.1    # Y position below which to delete immediately (floor is at Y = -0.05)

var last_interaction_time: float = 0.0
var deletion_timer: Timer = null
var pickable_child: XRToolsPickable = null

@export var data: ShapeData:
	set(value):
		data = value.duplicate()
		if data.type == ShapeData.Types.EMPTY:
			data.color = ShapeData.Colors.EMPTY
		elif data.color == ShapeData.Colors.EMPTY:
			data.type = ShapeData.Types.EMPTY
		
		if data:
			_apply_data()

func _ready():
	if data:
		_apply_data()
	
	# Setup deletion timer
	deletion_timer = Timer.new()
	deletion_timer.wait_time = DELETION_TIMEOUT
	deletion_timer.one_shot = true
	deletion_timer.timeout.connect(_on_deletion_timeout)
	add_child(deletion_timer)
	
	last_interaction_time = Time.get_ticks_msec() / 1000.0

func _process(delta):
	# Check if shape has fallen below deletion threshold
	if global_position.y < DELETION_HEIGHT:
		queue_free()

func _on_deletion_timeout():
	# Check if shape is still not being interacted with
	if pickable_child and not pickable_child.is_picked_up():
		queue_free()

func _get_color_from_enum(c : ShapeData.Colors):
	match c:
		ShapeData.Colors.RED: return Color.RED
		ShapeData.Colors.GREEN: return Color.GREEN
		ShapeData.Colors.BLUE: return Color.BLUE
		ShapeData.Colors.YELLOW: return Color.YELLOW
		ShapeData.Colors.EMPTY: return null

func _create_shape(type : ShapeData.Types, color : ShapeData.Colors):
	# Clear previous shapes
	for child in get_children():
		child.queue_free()
	
	var shape: XRToolsPickable
	
	# Create the right shape
	match type:
		ShapeData.Types.CUBE:
			shape = CUBE.instantiate()
		ShapeData.Types.CYLINDER:
			shape = CYLINDER.instantiate()
		ShapeData.Types.SPHERE:
			shape = SPHERE.instantiate()
		ShapeData.Types.TORUS:
			shape = TORUS.instantiate()
		ShapeData.Types.EMPTY:
			shape = null
	
	if shape:
		# Disable physics
		shape.release_mode = XRToolsPickable.ReleaseMode.UNFROZEN
		shape.freeze = true
		shape.picked_up_layer = 2
		shape.add_to_group('Shape')
		shape.gravity_scale = 0.75
		shape.second_hand_grab = XRToolsPickable.SecondHandGrab.SWAP
		
		# Connect interaction signals
		shape.picked_up.connect(_on_picked_up)
		shape.dropped.connect(_on_dropped)
		
		# Apply the color
		var mat := StandardMaterial3D.new()
		mat.albedo_color = _get_color_from_enum(color)
		shape.get_child(0).material = mat
		
		add_child(shape)
		pickable_child = shape
		
		# Start deletion timer
		if deletion_timer:
			deletion_timer.start()
		
		# make persistent in editor
		if Engine.is_editor_hint():
			shape.owner = get_tree().edited_scene_root 

func _apply_data():
	if not is_inside_tree():
		return
	_create_shape(data.type, data.color)

func _on_picked_up(_pickable):
	last_interaction_time = Time.get_ticks_msec() / 1000.0
	if deletion_timer:
		deletion_timer.stop()

func _on_dropped(_pickable):
	last_interaction_time = Time.get_ticks_msec() / 1000.0
	if deletion_timer:
		deletion_timer.start()
