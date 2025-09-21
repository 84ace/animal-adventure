extends Control
class_name AbilityWheel

signal ability_requested(ability: Ability)

# This will be populated by the AnimalController
var ability: Ability

func _ready() -> void:
	# Assuming the button is the first child or has a unique name
	var button = find_child("PounceButton")
	if button:
		button.pressed.connect(_on_pounce_button_pressed)

func _on_pounce_button_pressed() -> void:
	if ability:
		ability_requested.emit(ability)

func update_button_state(can_cast: bool) -> void:
	var button = find_child("PounceButton")
	if button:
		button.disabled = not can_cast
