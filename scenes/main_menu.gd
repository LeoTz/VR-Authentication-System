extends Control

func _on_sequential_button_pressed() -> void:
	print("Sequential Button pressed!")
	var main = get_tree().root.get_node_or_null("Main")
	if main:
		main.change_to_scene("res://scenes/sequential_interaction_authentication.tscn")

func _on_spatial_button_pressed() -> void:
	print("Spatial Button pressed!")
	var main = get_tree().root.get_node_or_null("Main")
	if main:
		main.change_to_scene("res://scenes/spatial_arrangement_authentication.tscn")
