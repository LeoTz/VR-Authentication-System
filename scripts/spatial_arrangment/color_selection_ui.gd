extends Control

# Signal to notify when a color is selected
signal color_selected(color_name: String, color_value: Color)

# Dictionary mapping button names to their colors
var color_map = {
	"RedButton": Color(0.8, 0.1, 0.1, 1),
	"GreenButton": Color(0.1, 0.8, 0.1, 1),
	"BlueButton": Color(0.1, 0.1, 0.8, 1),
	"YellowButton": Color(0.9, 0.9, 0.1, 1),
	"PurpleButton": Color(0.7, 0.1, 0.8, 1),
	"OrangeButton": Color(1, 0.5, 0.1, 1),
	"CyanButton": Color(0.1, 0.8, 0.8, 1),
	"PinkButton": Color(1, 0.4, 0.7, 1),
	"WhiteButton": Color(0.95, 0.95, 0.95, 1)
}

@onready var title_label = $Panel/VBoxContainer/Title

func _ready():
	# Connect all color buttons
	_connect_button("Panel/VBoxContainer/Row1/RedButton", "Red")
	_connect_button("Panel/VBoxContainer/Row1/GreenButton", "Green")
	_connect_button("Panel/VBoxContainer/Row1/BlueButton", "Blue")
	
	_connect_button("Panel/VBoxContainer/Row2/YellowButton", "Yellow")
	_connect_button("Panel/VBoxContainer/Row2/PurpleButton", "Purple")
	_connect_button("Panel/VBoxContainer/Row2/OrangeButton", "Orange")
	
	_connect_button("Panel/VBoxContainer/Row3/CyanButton", "Cyan")
	_connect_button("Panel/VBoxContainer/Row3/PinkButton", "Pink")
	_connect_button("Panel/VBoxContainer/Row3/WhiteButton", "White")

func _connect_button(button_path: String, color_name: String):
	var button = get_node(button_path)
	if button:
		button.pressed.connect(_on_color_button_pressed.bind(color_name, button.name))

func _on_color_button_pressed(color_name: String, button_name: String):
	var color_value = color_map.get(button_name, Color.WHITE)
	
	# Update title to show selection
	title_label.text = "Selected: " + color_name
	
	# Emit signal with the selected color
	color_selected.emit(color_name, color_value)
	
	# Print for debugging
	print("Color selected: ", color_name, " - ", color_value)
