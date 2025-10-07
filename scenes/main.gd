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
