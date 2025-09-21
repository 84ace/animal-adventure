extends Node


class_name NeedsComponent


@export var hunger: float = 100.0
@export var energy: float = 100.0
@export var comfort: float = 100.0


@export var decay_hunger: float = 0.5 # per second
@export var decay_energy: float = 0.2
@export var decay_comfort: float = 0.1


signal fainted
signal recovered


var fainted_state := false


func _process(delta: float) -> void:
if fainted_state:
return
hunger = max(0.0, hunger - decay_hunger * delta)
energy = max(0.0, energy - decay_energy * delta)
comfort = max(0.0, comfort - decay_comfort * delta)


if hunger <= 0.0 or energy <= 0.0 or comfort <= 0.0:
fainted_state = true
fainted.emit()
get_tree().create_timer(3.0).timeout.connect(_recover)


func _recover() -> void:
hunger = max(hunger, 30.0)
energy = max(energy, 50.0)
comfort = max(comfort, 50.0)
fainted_state = false
recovered.emit()