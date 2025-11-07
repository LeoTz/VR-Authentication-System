@tool
extends Node3D

var password : Array[ShapeData]
const SHAPE_SLOT = preload("uid://dvgrd4iilfjx3")
var EMPTY_SLOT = ShapeData.new()
@export_category("Configuration")
@export var num_slots : int = 4:
	set(value):
		num_slots = value
		if num_slots:
			_reset_slots()

func _ready() -> void:
	_reset_slots()

func _reset_slots():
	# Clear previous slots
	password = []
	for slot in get_children():
		slot.queue_free()
	
	# Create new slots stacked on each other
	for i in range(num_slots):
		var slot = SHAPE_SLOT.instantiate()
		
		slot.add_to_group('PasswordSlot{0}'.format([i]))
		var slot_snap_zone : XRToolsSnapZone = slot.get_node('%SlotSnapZone')
		slot_snap_zone.snap_require = 'Shape'
		slot_snap_zone.has_picked_up.connect(_on_shape_added_to_slot.bind(i))
		slot_snap_zone.has_dropped.connect(_on_shape_removed_from_slot.bind(i))
		add_child(slot)
		slot.position.y = i * 0.540
		
		# set default to be empty
		password.append(EMPTY_SLOT)
		
		if Engine.is_editor_hint():
			slot.owner = get_tree().edited_scene_root  # make persistent in editor

func _on_shape_added_to_slot(what: Variant, slot_idx):
	if what.is_in_group('Shape'):
		var shape : Node3D = what.get_parent()
		password[slot_idx] = shape.data
	print('\n')
	for shape in password:
		print("("+shape.Types.keys()[shape.type] + ", " + shape.Colors.keys()[shape.color] + ")")

func _on_shape_removed_from_slot(slot_idx):
	password[slot_idx] = EMPTY_SLOT
	print('\n')
	for shape in password:
		print("("+shape.Types.keys()[shape.type] + ", " + shape.Colors.keys()[shape.color] + ")")
