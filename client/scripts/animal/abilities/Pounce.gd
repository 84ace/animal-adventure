extends Ability
class_name PounceAbility

@export var pounce_strength: float = 10.0
@export var pounce_lift: float = 4.0

func cast(owner: Node) -> Vector3:
	if not owner is CharacterBody3D:
		return Vector3.ZERO

	var forward_dir = -owner.get_viewport().get_camera_3d().transform.basis.z
	var pounce_velocity = forward_dir * pounce_strength
	pounce_velocity.y = pounce_lift

	return pounce_velocity
