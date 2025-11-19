extends Node3D

# Authentication states
enum AuthState {
	CHOICE,
	CREATE_PASSWORD,
	LOGIN,
	AUTHENTICATED
}

# Password storage settings
const PASSWORD_FILE_PATH = "user://spatial_password.cfg"

var current_state: AuthState = AuthState.CHOICE
# moved password to global script because reloading scenes deletes this var.
var stored_password: Array = []  # Array of dictionaries with position, type, and color
var max_attempts: int = 3
var current_attempts: int = 0
var blocks_placed: int = 0
var time_elapsed: float = 0.0
var grid_dropped_count : int = 0
var timer_started: bool = false


# Node references
@onready var choice_ui_viewport = $ChoiceViewport/Viewport/SpatialPasswordChoiceUI
@onready var create_ui_viewport = $CreatePasswordViewport/Viewport/SpatialPasswordCreateUI
@onready var login_ui_viewport = $LoginPasswordViewport/Viewport/SpatialPasswordLoginUI
@onready var choice_viewport_3d = $ChoiceViewport
@onready var create_viewport_3d = $CreatePasswordViewport
@onready var login_viewport_3d = $LoginPasswordViewport
@onready var cube_grid = $"../CubeGrid3x3x3"
@onready var shape_table_viewport = $"../XROrigin3D/LeftHand/Viewport2Din3D"

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
	
	# Wait for UI to be ready
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Connect signals
	if choice_ui_viewport:
		choice_ui_viewport.login_selected.connect(_on_choice_login)
		choice_ui_viewport.create_selected.connect(_on_choice_create)
	
	if create_ui_viewport:
		create_ui_viewport.password_created.connect(_on_password_created)
		create_ui_viewport.cleared.connect(_on_create_cleared)
	
	if login_ui_viewport:
		login_ui_viewport.password_submitted.connect(_on_password_submitted)
		login_ui_viewport.cleared.connect(_on_login_cleared)
	
	# Connect to grid signals
	if cube_grid:
		cube_grid.grid_changed.connect(_on_grid_changed)
		cube_grid.grid_dropped.connect(_on_grid_dropped)
	
	# Load saved password if it exists
	load_password('sign_up')
	
	# Start with choice state
	set_state(AuthState.CHOICE)

func _process(delta: float) -> void:
	if timer_started:
		time_elapsed += delta

func set_state(new_state: AuthState):
	current_state = new_state
	
	match current_state:
		AuthState.CHOICE:
			show_choice_ui()
			hide_create_ui()
			hide_login_ui()
			hide_grid()
			hide_shape_table()
			print("State: CHOICE")
		
		AuthState.CREATE_PASSWORD:
			hide_choice_ui()
			show_create_ui()
			hide_login_ui()
			show_grid()
			show_shape_table()
			clear_grid()
			print("State: CREATE_PASSWORD")
		
		AuthState.LOGIN:
			hide_choice_ui()
			hide_create_ui()
			show_login_ui()
			show_grid()
			show_shape_table()
			clear_grid()
			current_attempts = 0
			print("State: LOGIN")
		
		AuthState.AUTHENTICATED:
			hide_choice_ui()
			hide_create_ui()
			hide_login_ui()
			show_grid()
			show_shape_table()
			clear_grid()
			print("State: AUTHENTICATED - Full access granted")

func show_choice_ui():
	if choice_viewport_3d:
		choice_viewport_3d.visible = true

func hide_choice_ui():
	if choice_viewport_3d:
		choice_viewport_3d.visible = false

func show_create_ui():
	if create_viewport_3d:
		create_viewport_3d.visible = true

func hide_create_ui():
	if create_viewport_3d:
		create_viewport_3d.visible = false

func show_login_ui():
	if login_viewport_3d:
		login_viewport_3d.visible = true

func hide_login_ui():
	if login_viewport_3d:
		login_viewport_3d.visible = false

func show_grid():
	if cube_grid:
		cube_grid.visible = true

func hide_grid():
	if cube_grid:
		cube_grid.visible = false

func show_shape_table():
	if shape_table_viewport:
		shape_table_viewport.visible = true

func hide_shape_table():
	if shape_table_viewport:
		shape_table_viewport.visible = false

func clear_grid():
	if cube_grid:
		cube_grid.clear_all_slots()

func get_current_grid_state() -> Array:
	if not cube_grid:
		return []
	
	return cube_grid.get_grid_state()

func _on_choice_login():
	if stored_password.size() == 0:
		print("No password exists, redirecting to create")
		set_state(AuthState.CREATE_PASSWORD)
	else:
		set_state(AuthState.LOGIN)

func _on_choice_create():
	set_state(AuthState.CREATE_PASSWORD)

func _on_grid_changed():	
	var grid_state = get_current_grid_state()
	var blocks_count = grid_state.size()
	
	if not timer_started and blocks_count != 0:
		timer_started = true
	
	if blocks_count >= 4:
		hide_shape_table()
		cube_grid.turn_off_snapzone()
	else:
		show_shape_table()
		cube_grid.turn_on_snapzone()
	
	# Update UI based on current state
	if current_state == AuthState.CREATE_PASSWORD and create_ui_viewport:
		create_ui_viewport.update_blocks_count(blocks_count)
	elif current_state == AuthState.LOGIN and login_ui_viewport:
		login_ui_viewport.update_blocks_count(blocks_count)


func _on_grid_dropped():
	grid_dropped_count += 1

func _on_password_created(_data):
	# Get the current grid state
	stored_password = get_current_grid_state()
	
	if stored_password.size() == 0:
		if create_ui_viewport:
			create_ui_viewport.show_message("Please place at least one block!", Color.ORANGE_RED)
		return
	# Save password to file
	save_password('sign_up')
	
	print("Password created with ", stored_password.size(), " blocks")
	if create_ui_viewport:
		create_ui_viewport.show_message("Password Saved!", Color.GREEN)
	
	# Wait a moment then reload the scene
	await get_tree().create_timer(1.5).timeout
	get_tree().reload_current_scene()
	
	

func _on_create_cleared():
	clear_grid()

func _on_password_submitted():
	# Get current grid state
	var current_grid = get_current_grid_state()
	
	# Compare with stored password
	if passwords_match(current_grid, stored_password):
		authenticate_success()
	else:
		authenticate_failure()

func _on_login_cleared():
	clear_grid()

func passwords_match(grid1: Array, grid2: Array) -> bool:
	if grid1.size() != grid2.size():
		return false
	
	# Create dictionaries for easier comparison
	var dict1 = {}
	var dict2 = {}
	
	for block in grid1:
		var key = str(block.position)
		dict1[key] = {"type": block.type, "color": block.color}
	
	for block in grid2:
		var key = str(block.position)
		dict2[key] = {"type": block.type, "color": block.color}
	
	# Compare all positions
	for key in dict1.keys():
		if not dict2.has(key):
			return false
		if dict1[key].type != dict2[key].type or dict1[key].color != dict2[key].color:
			return false
	
	return true

func authenticate_success():
	print("✓ Authentication successful!")
	if login_ui_viewport:
		login_ui_viewport.show_message("ACCESS GRANTED", Color.GREEN)
	
	save_password('sign_in')
	
	# Wait a moment before transitioning to main scene
	await get_tree().create_timer(1.5).timeout
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func authenticate_failure():
	current_attempts += 1
	print("✗ Authentication failed! Attempts: ", current_attempts, "/", max_attempts)
	
	if current_attempts >= max_attempts:
		if login_ui_viewport:
			login_ui_viewport.show_message("TOO MANY ATTEMPTS\nResetting...", Color.RED)
		await get_tree().create_timer(2.0).timeout
		set_state(AuthState.CREATE_PASSWORD)
	else:
		var remaining = max_attempts - current_attempts
		if login_ui_viewport:
			login_ui_viewport.show_message("INCORRECT\n" + str(remaining) + " attempt(s) remaining", Color.ORANGE_RED)
		
		# Clear the grid after a moment
		await get_tree().create_timer(1.5).timeout
		clear_grid()

func save_password(section : String = ""):
	"""Save the password to a config file"""
	var config = ConfigFile.new()
	
	if section == 'sign_in':
		config.load(PASSWORD_FILE_PATH)
	
	# Store each block's data
	for i in range(stored_password.size()):
		var block = stored_password[i]
		var _section = "block_" + str(i)
		
		config.set_value(section, _section + "_position_x", block.position.x)
		config.set_value(section, _section + "_position_y", block.position.y)
		config.set_value(section, _section + "_position_z", block.position.z)
		config.set_value(section, _section + "_type", block.type)
		config.set_value(section, _section + "_color", block.color)
	
	# Store total count
	config.set_value(section, "block_count", stored_password.size())
	config.set_value(section, "time_elapsed", time_elapsed)
	config.set_value(section, "number_of_grid_changes", grid_dropped_count)
	config.set_value(section, "number_of_unsuccessful_attempts", current_attempts)
	
	_reset_stats()
	
	var err = config.save(PASSWORD_FILE_PATH)
	if err == OK:
		print("Password saved to: ", PASSWORD_FILE_PATH)
	else:
		print("Error saving password: ", err)

func load_password(section:String):
	"""Load the password from config file"""
	var config = ConfigFile.new()
	var err = config.load(PASSWORD_FILE_PATH)
	
	if err != OK:
		print("No saved password found (this is normal for first run)")
		stored_password = []
		return
	
	var block_count = config.get_value(section, "block_count", 0)
	stored_password = []
	for i in range(block_count):
		var _section = "block_" + str(i)
		var block = {
			"position": Vector3i(
				config.get_value(section, _section + "_position_x"),
				config.get_value(section, _section + "_position_y"),
				config.get_value(section, _section + "_position_z")
			),
			"type": config.get_value(section, _section + "_type"),
			"color": config.get_value(section, _section + "_color")
		}
		stored_password.append(block)
	
	print("Password loaded: ", stored_password.size(), " blocks")

func delete_password():
	"""Delete the saved password file"""
	if FileAccess.file_exists(PASSWORD_FILE_PATH):
		DirAccess.remove_absolute(PASSWORD_FILE_PATH)
		print("Password file deleted")
	stored_password = []

func _reset_stats():
	timer_started = false
	time_elapsed = 0.0
	grid_dropped_count = 0
	current_attempts = 0
