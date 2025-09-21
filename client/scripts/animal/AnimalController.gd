extends CharacterBody3D
class_name AnimalController

@export var walk_speed: float = 5.5
@export var sprint_speed: float = 8.0
@export var jump_velocity: float = 4.5

signal jumped
signal sprint_started
signal sprint_stopped

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var is_sprinting := false

func _physics_process(delta: float) -> void:
	var v := velocity
	if not is_on_floor():
		v.y -= gravity * delta

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
