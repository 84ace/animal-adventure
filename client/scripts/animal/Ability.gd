extends Resource
class_name Ability


@export var id: String
@export var cooldown: float = 3.0
@export var energy_cost: float = 5.0


func can_cast(owner: Node) -> bool:
        return true


func cast(owner: Node) -> Vector3:
	# This method should be overridden by specific ability implementations.
	# It should return a velocity impulse to be applied to the character.
	return Vector3.ZERO