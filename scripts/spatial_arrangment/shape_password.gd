@tool
extends Node3D

const SHAPE_SLOT = preload("uid://052u5iqeyxd7")
var password : Array[ShapeData]

@export_category("Configuration")
@export var num_slots : int = 4:
	set(value):
		num_slots = value
		if num_slots:
			_reset_slots()

func _reset_slots():
	# Clear previous slots
	password = []
	for slot in get_children():
		slot.queue_free()
	
	# Create new slots stacked on each other
	for i in range(num_slots):
		var slot = SHAPE_SLOT.instantiate()
		add_child(slot)
		slot.position.y = i * 0.540
		
		# set default to be empty
		password.append(ShapeData.new())
		
		if Engine.is_editor_hint():
			slot.owner = get_tree().edited_scene_root  # make persistent in editor
		
