extends Control

# Signal to notify when a shape+color combination is selected
signal shape_color_selected(shape_type: String, color_value: Color)

const SHAPE = preload("uid://cnwslicak7xut")

# Color values
var color_map = {
	"RED": Color.RED,
	"GREEN": Color.GREEN,
	"BLUE": Color.BLUE,
	"YELLOW": Color.YELLOW
}

# Shape symbols for display
var shape_symbols = { 
	"CUBE": "■",      
	"SPHERE": "●",     
	"CYLINDER": "▮", 
	"TORUS": "○"      
}

# Randomized orders
var shape_order = []
var color_order = []

@onready var title_label = $Panel/VBoxContainer/Title

func _ready():
	# Randomize shape and color orders
	_randomize_layout()
	# Connect all shape+color buttons (4 shapes × 4 colors = 16 buttons)
	_setup_buttons()

func _randomize_layout():
	# Randomize shape order (rows)
	shape_order = ShapeData.Types.keys().slice(0, ShapeData.Types.keys().size() - 1)
	shape_order.shuffle()
	
	# Randomize color order (columns)
	color_order = ShapeData.Colors.keys().slice(0, ShapeData.Colors.keys().size() - 1)
	color_order.shuffle()

func _setup_buttons():
	# Get the row containers
	var rows = [
		$Panel/VBoxContainer/Row1,
		$Panel/VBoxContainer/Row2,
		$Panel/VBoxContainer/Row3,
		$Panel/VBoxContainer/Row4
	]
	
	# Assign randomized shapes to rows and randomized colors to columns
	for row_idx in range(4):
		var row = rows[row_idx]
		var shape_type = shape_order[row_idx]
		
		# Get all buttons in this row in order
		var all_children = row.get_children()
		var buttons = []
		for child in all_children:
			if child is Button:
				buttons.append(child)
		
		# Sort buttons by their horizontal position to ensure left-to-right order
		buttons.sort_custom(func(a, b): return a.get_index() < b.get_index())
		
		# Assign colors to buttons in the randomized order
		for col_idx in range(min(4, buttons.size())):
			var button = buttons[col_idx]
			var color_name = color_order[col_idx]
			var color_value = color_map.get(color_name)
			
			# Update button text to show the shape symbol
			button.text = shape_symbols.get(shape_type, "?")
			
			# Update button background color
			var style_box = StyleBoxFlat.new()
			style_box.bg_color = color_value
			button.add_theme_stylebox_override("normal", style_box)
			button.add_theme_stylebox_override("hover", style_box)
			button.add_theme_stylebox_override("pressed", style_box)
			
			# Disconnect any existing connections first
			if button.pressed.is_connected(_on_shape_button_pressed):
				button.pressed.disconnect(_on_shape_button_pressed)
			
			# Connect button to the randomized shape and color
			button.pressed.connect(_on_shape_button_pressed.bind(shape_type, color_name))

func _on_shape_button_pressed(shape_type: String, color_name: String):
	print('clciked')
	var color_value = color_map.get(color_name, Color.WHITE)
	
	var shape = SHAPE.instantiate()
	
	shape.data = ShapeData.new(ShapeData.Types[shape_type], ShapeData.Colors[color_name])
	
	get_parent().get_parent().get_parent().get_parent().get_parent().add_child(shape)
	
	call_deferred('pickup', shape)
	
	# Update title to show selection
	title_label.text = shape_type.capitalize() + " - " + color_name.capitalize() 
	
	# Emit signal with the selected shape and color
	shape_color_selected.emit(shape_type, color_value)

func pickup(shape):
	
	var pickable: XRToolsPickable = shape.get_child(0)
	#pickable.picked_up_layer = 2
	var grabber : XRToolsFunctionPickup = get_node('/root/SpatialArrangementAuthentication/XROrigin3D/RightHand/XRToolsFunctionPickup')
	shape.global_transform = grabber.global_transform
	grabber.drop_object()
	grabber._pick_up_object(pickable)
