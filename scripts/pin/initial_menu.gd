extends Control

signal create_pin_pressed
signal login_pressed

func _ready():
	# Connect button signals
	$Panel/VBoxContainer/CreatePinBtn.pressed.connect(_on_create_pin_pressed)
	$Panel/VBoxContainer/LoginBtn.pressed.connect(_on_login_pressed)

func _on_create_pin_pressed():
	create_pin_pressed.emit()

func _on_login_pressed():
	login_pressed.emit()
