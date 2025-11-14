extends Control

signal password_submitted()
signal cleared()

@onready var status_label: Label = $Panel/VBoxContainer/StatusLabel
@onready var clear_button: Button = $Panel/VBoxContainer/ButtonContainer/ClearButton
@onready var submit_button: Button = $Panel/VBoxContainer/ButtonContainer/SubmitButton

var blocks_placed: int = 0

func _ready():
	clear_button.pressed.connect(_on_clear_pressed)
	submit_button.pressed.connect(_on_submit_pressed)
	update_status()

func update_blocks_count(count: int):
	blocks_placed = count
	update_status()

func update_status():
	status_label.text = str(blocks_placed) + " blocks placed"
	
	# Enable submit button only if at least one block is placed
	submit_button.disabled = blocks_placed == 0

func _on_clear_pressed():
	cleared.emit()

func _on_submit_pressed():
	password_submitted.emit()

func show_message(message: String, color: Color = Color.BLACK):
	status_label.text = message
	status_label.add_theme_color_override("font_color", color)
	
	# Reset color after delay
	await get_tree().create_timer(2.0).timeout
	status_label.remove_theme_color_override("font_color")
	update_status()
