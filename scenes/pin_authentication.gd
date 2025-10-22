extends Node3D

# Authentication settings
@export var correct_pin: String = "1234"
@export var max_attempts: int = 3
@export var lockout_time: float = 30.0  # seconds
@export var success_scene: String = "res://scenes/main.tscn"

# State tracking
var current_attempts: int = 0
var is_locked_out: bool = false
var lockout_timer: float = 0.0

# Node references
@onready var keypad_ui = $KeypadViewport/Viewport/KeypadUI
@onready var status_label: Label = null

var xr_interface: XRInterface

func _ready():
	# Initialize XR
	xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		print("OpenXR initialised successfully!")
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		get_viewport().use_xr = true
	else:
		print("OpenXR not initialised, please check if your headset is connected")
	
	# Wait for keypad to be ready
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Connect to keypad signals
	if keypad_ui:
		keypad_ui.pin_entered.connect(_on_pin_entered)
		print("Keypad connected successfully")
	else:
		print("ERROR: Could not find KeypadUI!")

func _process(delta):
	if is_locked_out:
		lockout_timer -= delta
		if lockout_timer <= 0:
			unlock_keypad()

func _on_pin_entered(pin: String):
	if is_locked_out:
		show_message("LOCKED OUT\nWait " + str(int(lockout_timer)) + "s", Color.RED)
		return
	
	print("PIN entered: " + pin)
	
	if pin == correct_pin:
		authenticate_success()
	else:
		authenticate_failure()

func authenticate_success():
	print("✓ Authentication successful!")
	show_message("ACCESS GRANTED", Color.GREEN)
	
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
	print("PIN changed to: " + correct_pin)

func reset_attempts():
	current_attempts = 0
	is_locked_out = false
	lockout_timer = 0.0
	print("Attempts reset")
