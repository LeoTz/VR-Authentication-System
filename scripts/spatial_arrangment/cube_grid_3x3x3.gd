@tool
extends Node3D

signal grid_changed()
signal grid_dropped()

@export var GRID_SIZE = 3  # 3x3x3 cube
@export var SLOT_SIZE = 0.15
@export var SPACING = 0.2  # Slightly larger than slot size for spacing
const GRID_SLOT_SCENE = preload("uid://bx255pwniwipu")

@onready var grid_slots = $GridSlots

# Store references to all slots
var slot_array: Array[Node3D] = []
var slot_map: Dictionary = {}  # Maps Vector3i grid position to slot

func _ready():
	_create_grid()

func _create_grid():
	# Calculate offset to center the grid
	var offset = Vector3(
		-(GRID_SIZE - 1) * SPACING / 2.0,
		-(GRID_SIZE - 1) * SPACING / 2.0,
		-(GRID_SIZE - 1) * SPACING / 2.0
	)
	
	# Create 3x3x3 cube grid
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			for z in range(GRID_SIZE):
				var slot = GRID_SLOT_SCENE.instantiate()
				slot.name = "Slot_%d_%d_%d" % [x, y, z]
				
				# Set grid position on the slot
				slot.grid_position = Vector3i(x, y, z)
				
				# Position the slot
				slot.position = Vector3(
					x * SPACING + offset.x,
					y * SPACING + offset.y,
					z * SPACING + offset.z
				)
				
				grid_slots.add_child(slot)
				
				# Store reference
				slot_array.append(slot)
				slot_map[Vector3i(x, y, z)] = slot
				
				# Connect to slot's snap zone signals to detect changes
				if not Engine.is_editor_hint():
					var snap_zone = slot.get_node_or_null("XRToolsSnapZone")
					if snap_zone:
						snap_zone.has_picked_up.connect(_on_slot_changed)
						snap_zone.has_dropped.connect(_on_slot_changed)
						snap_zone.has_dropped.connect(_on_grid_dropped)
				# Make sure it's owned by the scene root for persistence
				if Engine.is_editor_hint():
					slot.owner = get_tree().edited_scene_root
	
	print("Created 3x3x3 cube grid with ", GRID_SIZE * GRID_SIZE * GRID_SIZE, " interactive slots")

func get_slot_at_position(grid_pos: Vector3i) -> Node3D:
	return slot_map.get(grid_pos, null)

func get_all_slots() -> Array[Node3D]:
	return slot_array

func get_occupied_slots() -> Array:
	var occupied = []
	for slot in slot_array:
		if slot.is_occupied:
			occupied.append(slot)
	return occupied

func get_empty_slots() -> Array:
	var empty = []
	for slot in slot_array:
		if not slot.is_occupied:
			empty.append(slot)
	return empty

func get_grid_state() -> Array:
	"""Returns array of dictionaries with position, type, and color for occupied slots"""
	var state = []
	
	for slot in slot_array:
		if slot.is_occupied and slot.locked_cube:
			var pickable = slot.locked_cube
			if pickable and pickable.get_parent() is Shape:
				var shape = pickable.get_parent() as Shape
				if shape.data:
					state.append({
						"position": slot.grid_position,
						"type": shape.data.type,
						"color": shape.data.color
					})
	
	return state

func clear_all_slots():
	"""Removes all shapes from all slots"""
	for slot in slot_array:
		if slot.is_occupied and slot.locked_cube:
			var pickable = slot.locked_cube
			
			# Manually reset slot state before freeing
			slot.is_occupied = false
			slot.locked_cube = null
			slot.hovering_cube = null
			slot._update_visual_state()
			
			# Free the shape
			if pickable and pickable.get_parent():
				pickable.get_parent().queue_free()
	
	grid_changed.emit()

func turn_off_snapzone():
	for slot in slot_array:
		slot.turn_off_snapzone()

func turn_on_snapzone():
	for slot in slot_array:
		slot.turn_on_snapzone()

func _on_slot_changed(_pickable):
	"""Called when any slot has a shape added or removed"""
	grid_changed.emit()

func _on_grid_dropped(_pickable):
	grid_dropped.emit()
