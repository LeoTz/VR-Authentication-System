extends Control

signal login_selected()
signal create_selected()

@onready var login_button: Button = $Panel/VBoxContainer/ButtonContainer/LoginButton
@onready var create_button: Button = $Panel/VBoxContainer/ButtonContainer/CreateButton

func _ready():
	login_button.pressed.connect(_on_login_pressed)
	create_button.pressed.connect(_on_create_pressed)

func _on_login_pressed():
	login_selected.emit()

func _on_create_pressed():
	create_selected.emit()
