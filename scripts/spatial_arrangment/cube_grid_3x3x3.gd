extends Node3D

const GRID_SIZE = 3  # 3x3x3 cube
const SLOT_SIZE = 0.2
const SPACING = 0.25  # Slightly larger than slot size for spacing
const GRID_SLOT_SCENE = preload("res://scenes/spatial_arrangement/grid_slot.tscn")

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
