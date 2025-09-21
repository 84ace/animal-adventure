extends CharacterBody3D
class_name AnimalController

@export var walk_speed: float = 5.5
@export var sprint_speed: float = 8.0
@export var jump_velocity: float = 4.5

@onready var needs_component: NeedsComponent = $NeedsComponent
@onready var hud = $CanvasLayer/HUD

signal jumped
signal sprint_started
signal sprint_stopped

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var is_sprinting := false
var can_move := true

func _ready() -> void:
	sprint_started.connect(_on_sprint_changed.bind(true))
	sprint_stopped.connect(_on_sprint_changed.bind(false))
	needs_component.fainted.connect(_on_fainted)
	needs_component.recovered.connect(_on_recovered)

func _physics_process(delta: float) -> void:
	hud.set_needs(needs_component.hunger, needs_component.energy, needs_component.comfort)

	var v := velocity
	if not is_on_floor():
		v.y -= gravity * delta

	if can_move:
		if Input.is_action_just_pressed("sprint"):
			is_sprinting = not is_sprinting
			if is_sprinting:
				sprint_started.emit()
			else:
				sprint_stopped.emit()

		var dir2 := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		var cam := get_viewport().get_camera_3d()
		var f := -cam.transform.basis.z
		var r := cam.transform.basis.x
		var move := (f * dir2.y + r * dir2.x).normalized()

		var speed := sprint_speed if is_sprinting else walk_speed
		v.x = move.x * speed
		v.z = move.z * speed

		if Input.is_action_just_pressed("jump") and is_on_floor():
			v.y = jump_velocity
			jumped.emit()

	velocity = v
	move_and_slide()

func _on_sprint_changed(sprinting: bool) -> void:
	needs_component.set_sprinting(sprinting)

func _on_fainted() -> void:
	can_move = false
	is_sprinting = false # Ensure sprint is off after fainting
	sprint_stopped.emit()
	hud.faint()

func _on_recovered() -> void:
	can_move = true
