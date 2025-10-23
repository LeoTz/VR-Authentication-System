@tool
extends Node3D
class_name Shape

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
	
	var shape: CSGPrimitive3D
	
	# Create the right shape
	match type:
		ShapeData.Types.CUBE:
			shape = CSGBox3D.new()
		ShapeData.Types.CYLINDER:
			shape = CSGCylinder3D.new()
			shape.height = 1.0
		ShapeData.Types.SPHERE:
			shape = CSGSphere3D.new()
		ShapeData.Types.TORUS:
			shape = CSGTorus3D.new()
		ShapeData.Types.EMPTY:
			shape = null
	
	if shape:
		shape.scale = Vector3(0.3, 0.3, 0.3)
		# Apply the color
		var mat := StandardMaterial3D.new()
		mat.albedo_color = _get_color_from_enum(color)
		shape.material = mat
		
		add_child(shape)
		
		if Engine.is_editor_hint():
			shape.owner = get_tree().edited_scene_root  # make persistent in editor

func _apply_data():
	if not is_inside_tree():
		return
	_create_shape(data.type, data.color)
