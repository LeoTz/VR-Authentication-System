extends Node3D
class_name Shape

const CUBE = preload("uid://cy2q6kfcih4gr")
const TORUS = preload("uid://dxs4dp7ewbwg8")
const SPHERE = preload("uid://h5ixyu701hg7")
const CYLINDER = preload("uid://fa52g5uavh3n")

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
		# Apply the color
		var mat := StandardMaterial3D.new()
		mat.albedo_color = _get_color_from_enum(color)
		shape.get_child(0).material = mat
		
		add_child(shape)
		
		# make persistent in editor
		if Engine.is_editor_hint():
			shape.owner = get_tree().edited_scene_root 

func _apply_data():
	if not is_inside_tree():
		return
	_create_shape(data.type, data.color)
