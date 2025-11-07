@tool
extends Node3D

const SHAPE = preload("uid://cnwslicak7xut")
const SHAPE_SLOT = preload("uid://dvgrd4iilfjx3")

# len() - 1 to remove the empty type and color
const num_shape_types = len(ShapeData.Types) - 1
const num_shape_colors = len(ShapeData.Colors) - 1


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
	var shuffled_columns = _range_random(num_shape_types)   # shuffled column order
	var shuffled_rows = _range_random(num_shape_colors)     # shuffled row order

	for row_pos in range(shuffled_rows.size()):
		var color_idx = shuffled_rows[row_pos]  # color for this row
		
		for col_pos in range(shuffled_columns.size()):
			var type_idx = shuffled_columns[col_pos]  # shape type for this column
			
			var shape = SHAPE.instantiate()
			shape.data = ShapeData.new(type_idx, color_idx)
			
			# Add shape to the corresponding slot in the table
			shape_table[row_pos][col_pos].get_node("ShapePlaceholder").add_child(shape)

func _create_empty_table():
	var shape_table : Array
	for i in range(num_shape_types):
		shape_table.append([])
		for j in range(num_shape_colors):
			var slot = SHAPE_SLOT.instantiate()
			add_child(slot)
			slot.position.y = i * 0.54
			slot.position.x = j * 0.6
			shape_table[i].append(slot) 
	return shape_table

func _ready() -> void:
	# instantiate any empty table/grid and populate it with the available shapes
	var shape_table = _create_empty_table()
	_populate_table(shape_table)
