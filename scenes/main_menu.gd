extends Control

func _on_pin_button_pressed() -> void:
	print("PIN Button pressed!")
	var main = get_tree().root.get_node_or_null("Main")
	if main:
		main.change_to_scene("res://scenes/pin_based_authentication.tscn")

func _on_spatial_button_pressed() -> void:
	print("Spatial Button pressed!")
	var main = get_tree().root.get_node_or_null("Main")
	if main:
		main.change_to_scene("res://scenes/spatial_arrangement_authentication.tscn")
		
