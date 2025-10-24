extends Node3D

var xr_interface: XRInterface

func _ready():
	xr_interface = XRServer.find_interface("OpenXR")
	
	if xr_interface and xr_interface.is_initialized():
		print("OpenXR initialised successfully!")
		
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		
		get_viewport().use_xr = true
	else:
		print("OpenXR not initialised, please check if your headset is connected")
	
	# Re-enable viewport when scene loads (in case it was disabled)
	if $Viewport2Din3D:
		$Viewport2Din3D.enabled = true

# Add this function to handle scene changes
func change_to_scene(scene_path: String):
	if $Viewport2Din3D:
		$Viewport2Din3D.enabled = false
	
	await get_tree().process_frame
	get_tree().change_scene_to_file(scene_path)

# Add proper cleanup when scene exits
func _exit_tree():
	# Clean up viewport first
	if $Viewport2Din3D:
		$Viewport2Din3D.enabled = false
	
	# Don't uninitialize XR here if changing scenes
	# Only uninitialize on actual application quit

# Handle application quit properly
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		cleanup_xr()

func cleanup_xr():
	if xr_interface and xr_interface.is_initialized():
		xr_interface.uninitialize()
		print("XR interface cleaned up")
