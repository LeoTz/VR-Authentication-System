extends Node3D

# Authentication states
enum AuthState {
	CHOICE,
	CREATE_PIN,
	CONFIRM_PIN,
	LOGIN
}

var current_state: AuthState = AuthState.CHOICE
var temp_pin: String = ""  # Store PIN during creation for confirmation

# Password storage settings
const PIN_FILE_PATH = "user://pin_password.cfg"
const DEV_PIN_FILE_PATH = "res://pin_password.cfg"

# Authentication settings
@export var default_pin: String = "1234"
var correct_pin: String = ""
@export var max_attempts: int = 3
@export var lockout_time: float = 30.0  # seconds
@export var success_scene: String = "res://scenes/main.tscn"

# State tracking
var current_attempts: int = 0
var is_locked_out: bool = false
var lockout_timer: float = 0.0
var time_elapsed: float = 0.0
var timer_started: bool = false
var backspaces_count: int = 0
var current_pin: String = ""

# Node references
@onready var choice_ui = $ChoiceViewport/Viewport/PinChoiceUI
@onready var keypad_ui = $KeypadViewport/Viewport/KeypadUI
@onready var choice_viewport = $ChoiceViewport
@onready var keypad_viewport = $KeypadViewport
@onready var status_label: Label = null

var xr_interface: XRInterface

func _ready():
	# Load saved PIN or use default
	load_pin()
	
	# Initialize XR
	xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		print("OpenXR initialised successfully!")
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		get_viewport().use_xr = true
	else:
		print("OpenXR not initialised, please check if your headset is connected")
	
	# Wait for UI to be ready
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Connect to choice UI signals
	if choice_ui:
		choice_ui.login_selected.connect(_on_choice_login)
		choice_ui.create_selected.connect(_on_choice_create)
	
	# Connect to keypad signals
	if keypad_ui:
		keypad_ui.pin_entered.connect(_on_pin_entered)
		keypad_ui.pin_cleared.connect(_on_pin_cleared)
		keypad_ui.pin_num_pressed.connect(_on_pin_num_pressed)
		print("Keypad connected successfully")
	else:
		print("ERROR: Could not find KeypadUI!")
	
	# Start with choice state
	set_state(AuthState.CHOICE)

func _process(delta):
	if timer_started:
		time_elapsed += delta
	if is_locked_out:
		lockout_timer -= delta
		if lockout_timer <= 0:
			unlock_keypad()

func set_state(new_state: AuthState):
	current_state = new_state
	
	match current_state:
		AuthState.CHOICE:
			show_choice_ui()
			hide_keypad_ui()
			temp_pin = ""
			print("State: CHOICE")
		
		AuthState.CREATE_PIN:
			hide_choice_ui()
			show_keypad_ui()
			temp_pin = ""
			if keypad_ui:
				keypad_ui.set_prompt("Create New PIN")
				keypad_ui.clear_pin()
			print("State: CREATE_PIN")
		
		AuthState.CONFIRM_PIN:
			# Stay on keypad
			if keypad_ui:
				keypad_ui.set_prompt("Confirm PIN")
				keypad_ui.clear_pin()
			print("State: CONFIRM_PIN")
		
		AuthState.LOGIN:
			hide_choice_ui()
			show_keypad_ui()
			temp_pin = ""
			if keypad_ui:
				keypad_ui.set_prompt("Enter PIN")
				keypad_ui.clear_pin()
			print("State: LOGIN")

func show_choice_ui():
	if choice_viewport:
		choice_viewport.visible = true

func hide_choice_ui():
	if choice_viewport:
		choice_viewport.visible = false

func show_keypad_ui():
	if keypad_viewport:
		keypad_viewport.visible = true

func hide_keypad_ui():
	if keypad_viewport:
		keypad_viewport.visible = false

func _on_choice_login():
	set_state(AuthState.LOGIN)

func _on_choice_create():
	set_state(AuthState.CREATE_PIN)

func _on_pin_entered(pin: String):
	if current_state == AuthState.CREATE_PIN:
		# First PIN entry
		temp_pin = pin
		show_message("Confirm your PIN", Color.WHITE)
		await get_tree().create_timer(1.0).timeout
		set_state(AuthState.CONFIRM_PIN)
		return
	
	if current_state == AuthState.CONFIRM_PIN:
		# Confirm PIN entry
		if pin == temp_pin:
			# PINs match - save it
			correct_pin = pin
			save_pin('sign_up')
			show_message("PIN SAVED!", Color.GREEN)
			await get_tree().create_timer(1.5).timeout
			set_state(AuthState.CHOICE)
		else:
			# PINs don't match - restart
			show_message("PINs don't match!\nTry again", Color.RED)
			await get_tree().create_timer(2.0).timeout
			set_state(AuthState.CREATE_PIN)
		return
	
	# Login state
	if is_locked_out:
		show_message("LOCKED OUT\nWait " + str(int(lockout_timer)) + "s", Color.RED)
		return
	
	print("PIN entered: " + pin)
	
	if pin == correct_pin:
		authenticate_success()
	else:
		authenticate_failure()

func _on_pin_num_pressed(digit : String):
	timer_started = true
	current_pin += digit

func _on_pin_cleared():
	if current_pin != "":
		current_pin = current_pin.left(current_pin.length() - 1)
		backspaces_count += 1
	
	print(backspaces_count)
	print(time_elapsed)

func authenticate_success():
	print("✓ Authentication successful!")
	show_message("ACCESS GRANTED", Color.GREEN)
	save_pin('sign_in')
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
		show_message("INCORRECT PIN\n" + str(remaining) + " attempt(s) remaining", Color.ORANGE_RED)
		
		# Clear the keypad after a moment
		await get_tree().create_timer(1.5).timeout
		if keypad_ui:
			keypad_ui.clear_pin()

func lockout_keypad():
	is_locked_out = true
	lockout_timer = lockout_time
	print("⚠ Keypad locked out for " + str(lockout_time) + " seconds")
	show_message("TOO MANY ATTEMPTS\nLocked for " + str(int(lockout_time)) + "s", Color.RED)
	
	if keypad_ui:
		keypad_ui.clear_pin()

func unlock_keypad():
	is_locked_out = false
	current_attempts = 0
	lockout_timer = 0.0
	print("✓ Keypad unlocked")
	show_message("KEYPAD UNLOCKED\nEnter PIN", Color.WHITE)
	
	if keypad_ui:
		keypad_ui.clear_pin()

func show_message(text: String, color: Color = Color.WHITE):
	# Update the keypad display with the message
	if keypad_ui and keypad_ui.has_node("Panel/VBoxContainer/Display"):
		var display = keypad_ui.get_node("Panel/VBoxContainer/Display")
		display.text = text
		display.modulate = color
		
		# Reset color after a moment (except for lockout messages)
		if not is_locked_out and color != Color.GREEN:
			await get_tree().create_timer(2.0).timeout
			if display:
				display.modulate = Color.BLACK

func change_to_scene(scene_path: String):
	# Disable viewport before changing scenes
	if $KeypadViewport:
		$KeypadViewport.enabled = false
	
	await get_tree().process_frame
	get_tree().change_scene_to_file(scene_path)

# Cleanup XR on exit
func _exit_tree():
	if $KeypadViewport:
		$KeypadViewport.enabled = false

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		cleanup_xr()

func cleanup_xr():
	if xr_interface and xr_interface.is_initialized():
		xr_interface.uninitialize()
		print("XR interface cleaned up")

# Helper functions for testing or external control
func set_pin(new_pin: String):
	correct_pin = new_pin
	save_pin('sign_up')
	print("PIN changed to: " + correct_pin)

func reset_attempts():
	current_attempts = 0
	is_locked_out = false
	lockout_timer = 0.0
	print("Attempts reset")

func reset_tracking_stats():
	timer_started = false
	time_elapsed = 0
	current_pin = ""
	backspaces_count = 0
	print("Stats reset")
	
func save_pin(section : String = ""):
	"""Save the PIN to a config file"""
	var config = ConfigFile.new()
	if section == 'sign_in':
		config.load('user://pin_password.cfg')
	config.set_value(section, "pin", correct_pin)
	config.set_value(section, "time_elapsed", time_elapsed)
	config.set_value(section, "number_of_backspaces", backspaces_count)
	config.set_value(section, "number_of_unsuccessful_attempts", current_attempts)
	var err = config.save(PIN_FILE_PATH)
	if err == OK:
		print("PIN saved to: ", PIN_FILE_PATH)
	else:
		print("Error saving PIN: ", err)
	reset_tracking_stats()

func load_pin():
	"""Load the PIN from config file"""
	var config = ConfigFile.new()
	var err = config.load(PIN_FILE_PATH)
	
	if err != OK:
		print("No saved PIN found, using default: ", default_pin)
		correct_pin = default_pin
		save_pin('sign_up')  # Save the default PIN for next time
		return
	
	correct_pin = config.get_value("authentication", "pin", default_pin)
	print("PIN loaded from file")

func delete_pin():
	"""Delete the saved PIN file and reset to default"""
	if FileAccess.file_exists(PIN_FILE_PATH):
		DirAccess.remove_absolute(PIN_FILE_PATH)
		print("PIN file deleted")
	correct_pin = default_pin
	save_pin()
