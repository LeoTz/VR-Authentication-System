extends Control

signal pin_entered(pin: String)
signal pin_cleared()

var current_pin: String = ""
var max_length: int = 4
var prompt_text: String = "Enter PIN"

@onready var display: Label = $Panel/VBoxContainer/Display

func _ready():
	# Connect all number buttons
	for i in range(10):
		var btn_name = "Btn" + str(i)
		var button = $Panel/VBoxContainer/GridContainer.get_node(btn_name)
		if button:
			button.pressed.connect(_on_digit_pressed.bind(str(i)))
	
	# Connect backspace and enter
	$Panel/VBoxContainer/GridContainer/BtnBack.pressed.connect(_on_backspace_pressed)
	$Panel/VBoxContainer/GridContainer/BtnEnter.pressed.connect(_on_enter_pressed)
	
	update_display()

func _on_digit_pressed(digit: String):
	if current_pin.length() < max_length:
		current_pin += digit
		update_display()
		print("PIN: ", current_pin)

func _on_backspace_pressed():
	if current_pin.length() > 0:
		current_pin = current_pin.substr(0, current_pin.length() - 1)
		update_display()
		pin_cleared.emit()
		print("PIN: ", current_pin)

func _on_enter_pressed():
	if current_pin.length() > 0:
		pin_entered.emit(current_pin)
		print("PIN Entered: ", current_pin)
		# Optionally clear after enter
		# current_pin = ""
		# update_display()

func update_display():
	if current_pin.length() == 0:
		display.text = prompt_text
	else:
		# Show asterisks for entered digits
		display.text = "*".repeat(current_pin.length())

func clear_pin():
	current_pin = ""
	update_display()

func set_prompt(text: String):
	"""Set the prompt text shown when no PIN is entered"""
	prompt_text = text
	update_display()

func get_pin() -> String:
	return current_pin
