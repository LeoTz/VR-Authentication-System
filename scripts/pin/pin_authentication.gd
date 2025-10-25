extends Node3D

# Authentication settings
@export var correct_pin: String = ""  # Empty means no PIN set yet
@export var max_attempts: int = 3
@export var lockout_time: float = 30.0  # seconds
@export var success_scene: String = "res://scenes/main.tscn"
@export var save_pin_to_file: bool = true  # Save PIN to config file

# State management
enum State { MENU, CREATE_PIN, CONFIRM_PIN, LOGIN }
var current_state: State = State.MENU

# State tracking
var current_attempts: int = 0
var is_locked_out: bool = false
var lockout_timer: float = 0.0
var temp_pin: String = ""  # Temporary storage for PIN creation

# Node references
@onready var menu_viewport = $MenuViewport
@onready var keypad_viewport = $KeypadViewport
@onready var menu_ui = $MenuViewport/Viewport/InitialMenu
@onready var keypad_ui = $KeypadViewport/Viewport/KeypadUI

var xr_interface: XRInterface
var config_file_path: String = "res://data/pin/pin_config.cfg"  # Saved in project folder for Git

func _ready():
	# Initialize XR
	xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		print("OpenXR initialised successfully!")
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		get_viewport().use_xr = true
	else:
		print("OpenXR not initialised, please check if your headset is connected")
	
	# Load saved PIN if available
	load_pin_from_file()
	
	# Wait for UI to be ready
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Connect signals
	if menu_ui:
		menu_ui.create_pin_pressed.connect(_on_create_pin_pressed)
		menu_ui.login_pressed.connect(_on_login_pressed)
		print("Menu connected successfully")
	
	if keypad_ui:
		keypad_ui.pin_entered.connect(_on_pin_entered)
		print("Keypad connected successfully")
	
	# Start with menu
	show_menu()

func _process(delta):
	if is_locked_out:
		lockout_timer -= delta
		if lockout_timer <= 0:
			unlock_keypad()
		else:
			# Update lockout message
			if current_state == State.LOGIN:
				keypad_ui.set_message("LOCKED OUT\nWait " + str(int(lockout_timer)) + "s", Color.RED)

func show_menu():
	current_state = State.MENU
	menu_viewport.visible = true
	keypad_viewport.visible = false
	print("Showing menu")

func show_keypad():
	menu_viewport.visible = false
	keypad_viewport.visible = true
	print("Showing keypad")

func _on_create_pin_pressed():
	print("Create PIN pressed")
	current_state = State.CREATE_PIN
	temp_pin = ""
	show_keypad()
	keypad_ui.set_message("Enter New PIN\n(4 digits)", Color.BLACK)

func _on_login_pressed():
	print("Login pressed")
	
	# Check if a PIN exists
	if correct_pin == "":
		# No PIN set, prompt to create one
		show_temp_message("No PIN set!\nPlease create a PIN first", Color.ORANGE_RED, 2.0)
		return
	
	current_state = State.LOGIN
	show_keypad()
	keypad_ui.set_message("Enter PIN", Color.BLACK)

func _on_pin_entered(pin: String):
	print("PIN entered in state: " + State.keys()[current_state] + " - PIN: " + pin)
	
	match current_state:
		State.CREATE_PIN:
			handle_create_pin(pin)
		State.CONFIRM_PIN:
			handle_confirm_pin(pin)
		State.LOGIN:
			handle_login(pin)

func handle_create_pin(pin: String):
	temp_pin = pin
	current_state = State.CONFIRM_PIN
	keypad_ui.set_message("Confirm PIN\n(Re-enter)", Color.BLACK)
	await get_tree().create_timer(0.5).timeout
	keypad_ui.clear_pin()

func handle_confirm_pin(pin: String):
	if pin == temp_pin:
		# PINs match, save it
		correct_pin = temp_pin
		if save_pin_to_file:
			save_pin_to_file_func()
		
		keypad_ui.set_message("PIN SAVED!", Color.GREEN)
		print("✓ New PIN created and saved: " + correct_pin)
		
		# Return to menu after delay
		await get_tree().create_timer(2.0).timeout
		keypad_ui.clear_pin()
		show_menu()
	else:
		# PINs don't match
		keypad_ui.set_message("PINs Don't Match!\nTry Again", Color.ORANGE_RED)
		print("✗ PIN confirmation failed")
		
		await get_tree().create_timer(2.0).timeout
		temp_pin = ""
		current_state = State.CREATE_PIN
		keypad_ui.set_message("Enter New PIN\n(4 digits)", Color.BLACK)
		keypad_ui.clear_pin()

func handle_login(pin: String):
	if is_locked_out:
		keypad_ui.set_message("LOCKED OUT\nWait " + str(int(lockout_timer)) + "s", Color.RED)
		keypad_ui.clear_pin()
		return
	
	if pin == correct_pin:
		authenticate_success()
	else:
		authenticate_failure()

func authenticate_success():
	print("✓ Authentication successful!")
	keypad_ui.set_message("ACCESS GRANTED", Color.GREEN)
	
	# Wait a moment before transitioning
	await get_tree().create_timer(1.5).timeout
	
	# Change to success scene
	change_to_scene(success_scene)

func authenticate_failure():
	current_attempts += 1
	print("✗ Authentication failed! Attempts: " + str(current_attempts) + "/" + str(max_attempts))
	
	if current_attempts >= max_attempts:
		lockout_keypad()
	else:
		var remaining = max_attempts - current_attempts
		keypad_ui.set_message("INCORRECT PIN\n" + str(remaining) + " attempt(s) left", Color.ORANGE_RED)
		
		# Clear the keypad after a moment
		await get_tree().create_timer(1.5).timeout
		if keypad_ui:
			keypad_ui.set_message("Enter PIN", Color.BLACK)
			keypad_ui.clear_pin()

func lockout_keypad():
	is_locked_out = true
	lockout_timer = lockout_time
	print("⚠ Keypad locked out for " + str(lockout_time) + " seconds")
	keypad_ui.set_message("TOO MANY ATTEMPTS\nLocked " + str(int(lockout_time)) + "s", Color.RED)
	keypad_ui.clear_pin()

func unlock_keypad():
	is_locked_out = false
	current_attempts = 0
	lockout_timer = 0.0
	print("✓ Keypad unlocked")
	keypad_ui.set_message("KEYPAD UNLOCKED\nEnter PIN", Color.WHITE)
	
	# Flash white then back to black
	await get_tree().create_timer(1.5).timeout
	keypad_ui.set_message("Enter PIN", Color.BLACK)
	keypad_ui.clear_pin()

func show_temp_message(text: String, color: Color, duration: float):
	"""Show a temporary message on the menu screen"""
	if menu_ui and menu_ui.has_node("Panel/VBoxContainer/Title"):
		var title = menu_ui.get_node("Panel/VBoxContainer/Title")
		var original_text = title.text
		var original_color = title.modulate
		
		title.text = text
		title.modulate = color
		
		await get_tree().create_timer(duration).timeout
		
		title.text = original_text
		title.modulate = original_color

func save_pin_to_file_func():
	var config = ConfigFile.new()
	config.set_value("pin", "code", correct_pin)
	var err = config.save(config_file_path)
	if err == OK:
		print("PIN saved to file")
	else:
		print("Error saving PIN to file: " + str(err))

func load_pin_from_file():
	if not save_pin_to_file:
		return
	
	var config = ConfigFile.new()
	var err = config.load(config_file_path)
	
	if err == OK:
		correct_pin = config.get_value("pin", "code", "")
		print("PIN loaded from file: " + ("SET" if correct_pin != "" else "NOT SET"))
	else:
		print("No saved PIN found (this is normal on first run)")

func change_to_scene(scene_path: String):
	# Disable viewports before changing scenes
	if menu_viewport:
		menu_viewport.enabled = false
	if keypad_viewport:
		keypad_viewport.enabled = false
	
	await get_tree().process_frame
	get_tree().change_scene_to_file(scene_path)

# Cleanup XR on exit
func _exit_tree():
	if menu_viewport:
		menu_viewport.enabled = false
	if keypad_viewport:
		keypad_viewport.enabled = false

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		cleanup_xr()

func cleanup_xr():
	if xr_interface and xr_interface.is_initialized():
		xr_interface.uninitialize()
		print("XR interface cleaned up")

# Helper functions for testing or external control
func reset_attempts():
	current_attempts = 0
	is_locked_out = false
	lockout_timer = 0.0
	print("Attempts reset")

func clear_saved_pin():
	correct_pin = ""
	var config = ConfigFile.new()
	config.save(config_file_path)
	print("Saved PIN cleared")
