extends Control

# Signal to notify when a shape+color combination is selected
signal shape_color_selected(shape_type: String, color_value: Color)

# Shape types
enum ShapeType {
	CUBE,
	SPHERE,
	CYLINDER,
	TORUS
}

# Color values
var color_map = {
	"Red": Color(0.8, 0.1, 0.1, 1),
	"Green": Color(0.1, 0.8, 0.1, 1),
	"Blue": Color(0.1, 0.1, 0.8, 1),
	"Yellow": Color(0.9, 0.9, 0.1, 1)
}

# Shape symbols for display
var shape_symbols = {
	"Cube": "■",
	"Sphere": "●",
	"Cylinder": "⬬",
	"Torus": "◯"
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
	shape_order = ["Cube", "Sphere", "Cylinder", "Torus"]
	shape_order.shuffle()
	
	# Randomize color order (columns)
	color_order = ["Red", "Green", "Blue", "Yellow"]
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
	var color_value = color_map.get(color_name, Color.WHITE)
	
	# Update title to show selection
	title_label.text = shape_type + " - " + color_name
	
	# Emit signal with the selected shape and color
	shape_color_selected.emit(shape_type, color_value)
