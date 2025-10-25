extends Control

signal pin_entered(pin: String)

var current_pin: String = ""
var max_pin_length: int = 4

@onready var display: Label = $Panel/VBoxContainer/Display

func _ready():
	# Connect all number buttons
	for i in range(10):
		var btn = get_node("Panel/VBoxContainer/GridContainer/Btn" + str(i))
		if btn:
			btn.pressed.connect(_on_number_pressed.bind(str(i)))
	
	# Connect special buttons
	$Panel/VBoxContainer/GridContainer/BtnBack.pressed.connect(_on_back_pressed)
	$Panel/VBoxContainer/GridContainer/BtnEnter.pressed.connect(_on_enter_pressed)
	
	update_display()

func _on_number_pressed(number: String):
	if current_pin.length() < max_pin_length:
		current_pin += number
		update_display()

func _on_back_pressed():
	if current_pin.length() > 0:
		current_pin = current_pin.substr(0, current_pin.length() - 1)
		update_display()

func _on_enter_pressed():
	if current_pin.length() == max_pin_length:
		pin_entered.emit(current_pin)
		# Don't clear here - let the parent handle it

func update_display():
	if current_pin.length() > 0:
		# Show dots for entered digits
		display.text = "•".repeat(current_pin.length())
	else:
		display.text = display.text  # Keep current message

func clear_pin():
	current_pin = ""
	update_display()

func set_message(text: String, color: Color = Color.BLACK):
	display.text = text
	display.modulate = color
	current_pin = ""

func get_display_label() -> Label:
	return display
