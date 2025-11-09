@tool
extends "res://addons/godot-xr-tools/objects/pickable.gd"

# Reference to the current slot this shape is in/near
var current_slot: Node3D = null
var best_hover_slot: Node3D = null
var is_being_grabbed: bool = false
var last_hover_slot: Node3D = null

func _ready():
	super._ready()
	
	# Don't connect signals in editor
	if Engine.is_editor_hint():
		return
	
	# Connect to pickable signals
	if has_signal("picked_up"):
		picked_up.connect(_on_picked_up)
	if has_signal("dropped"):
		dropped.connect(_on_dropped)

func _process(delta):
	if Engine.is_editor_hint():
		return
	
	# Always update hover - whether grabbed or not
	_update_best_hover_slot()

func _on_picked_up(pickable):
	is_being_grabbed = true
	
	# If we were locked in a slot, unlock it
	if current_slot and current_slot.has_method("unlock_cube"):
		current_slot.unlock_cube()
		current_slot = null

func _on_dropped(pickable):
	is_being_grabbed = false
	
	# Small delay to ensure physics settle
	await get_tree().create_timer(0.05).timeout
	
	# Snap to the best hover slot if available
	if best_hover_slot and best_hover_slot.has_method("lock_cube"):
		if best_hover_slot.lock_cube(self):
			current_slot = best_hover_slot
			
			# Clear hover state from the slot since it's now locked
			if best_hover_slot.has_method("set_hovering_cube"):
				best_hover_slot.set_hovering_cube(null)
			best_hover_slot = null

func _update_best_hover_slot():
	# Don't update hover if we're currently locked
	if current_slot != null and not is_being_grabbed:
		return
	
	# Find the cube grid
	var grid_node = get_tree().get_first_node_in_group("cube_grid")
	if not grid_node or not grid_node.has_method("get_all_slots"):
		return
	
	# Find the closest slot that is not occupied
	var slots = grid_node.get_all_slots()
	var new_best_slot = null
	var closest_distance = 999999.0
	
	for slot in slots:
		# Skip occupied slots
		if slot.is_occupied:
			continue
		
		# Check distance to this slot
		var distance = global_position.distance_to(slot.global_position)
		
		# Only consider slots within hover range (0.35m from center)
		if distance < 0.35 and distance < closest_distance:
			closest_distance = distance
			new_best_slot = slot
	
	# Update best hover slot
	if new_best_slot != best_hover_slot:
		# Clear old slot's hover state
		if best_hover_slot and best_hover_slot.has_method("set_hovering_cube"):
			best_hover_slot.set_hovering_cube(null)
		
		# Set new slot's hover state
		if new_best_slot and new_best_slot.has_method("set_hovering_cube"):
			new_best_slot.set_hovering_cube(self)
		
		best_hover_slot = new_best_slot
