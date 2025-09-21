extends Resource
class_name Ability


@export var id: String
@export var cooldown: float = 3.0
@export var energy_cost: float = 5.0


func can_cast(owner: Node) -> bool:
        return true


func cast(owner: Node) -> void:
        # override in derived resources
        pass