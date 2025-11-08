@tool
extends Node3D

@export var chosen_shapes : Array[ShapeData.Types]:
	set(values):
		# Remove duplicates
		values = values.duplicate()
		values = values.filter(func(v): return v != ShapeData.Types.EMPTY)
		values = unique_arr(values) # removes duplicates, preserving order
		chosen_shapes = values

const SHAPE = preload("uid://cnwslicak7xut")
const SHAPE_SLOT = preload("uid://dvgrd4iilfjx3")


# len() - 1 to remove the empty type and color
@onready var num_shape_types = len(chosen_shapes) if chosen_shapes else len(ShapeData.Types) - 1
const num_shape_colors = len(ShapeData.Colors) - 1

func _ready() -> void:
	print(chosen_shapes)
	print(num_shape_types)
	# instantiate any empty table/grid and populate it with the available shapes
	var shape_table = _create_empty_table()
	_populate_table(shape_table)
	#if Engine.is_editor_hint():
		#shape_table.owner = get_tree().edited_scene_root  # make persistent in editor

func _range_random(n: int) -> Array:
	var arr = []
	for i in range(0, n):
		arr.append(i)
	arr.shuffle()  # randomize order
	return arr


func _populate_table(shape_table : Array):
	'''
	table format: a column will contain the same shape but with different colors at each row
	the table format is constant but shuffles the columns and rows randomly per run
	example: 
		s1c1 | s2c1 | s3c1
		s1c2 | s2c2 | s3c2
		s1c3 | s2c3 | s3c3
	another run would produce:
		s2c2 | s3c2 | s1c2
		s2c1 | s3c1 | s1c1
		s2c3 | s3c3 | s1c3
	'''
	# Generate shuffled column and row indices
	var shuffled_columns = _range_random(num_shape_colors)  # shuffled column order
	var shuffled_rows = _range_random(num_shape_types)  # shuffled row order

	for row_pos in range(shuffled_rows.size()):
		var type_idx = shuffled_rows[row_pos]  # color for this row
		
		for col_pos in range(shuffled_columns.size()):
			var color_idx = shuffled_columns[col_pos]  # shape type for this column
			
			var shape = SHAPE.instantiate()
			
			shape.data = ShapeData.new(type_idx, color_idx)
			
			var slot_snap_zone : XRToolsSnapZone = shape_table[row_pos][col_pos].get_node('%SlotSnapZone')
			# Add shape to the corresponding slot in the table
			slot_snap_zone.add_child(shape)
			call_deferred('_init_snap_zone', slot_snap_zone, shape)


func _create_empty_table():
	var shape_table : Array
	for i in range(num_shape_types):
		shape_table.append([])
		for j in range(num_shape_colors):
			var slot = SHAPE_SLOT.instantiate()
			add_child(slot)
			slot.position.y = i * 0.1
			slot.position.x = j * 0.1
			shape_table[i].append(slot) 
	print(num_shape_types)
	print(len(shape_table))
	return shape_table

func _init_snap_zone(slot_snap_zone, shape):
	slot_snap_zone.initial_object = shape.get_child(0).get_path()
	slot_snap_zone.snap_exclude = 'Shape'
	slot_snap_zone.spawn_again = true


func unique_arr(arr):
	var unique :Array[int] = []

	for item in arr:
		if not unique.has(item):
			unique.append(item)
			
	return unique
