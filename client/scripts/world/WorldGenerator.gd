extends Node3D
class_name WorldGenerator


@export var size_x: int = 256
@export var size_z: int = 256
@export var scale: float = 12.0


var noise := FastNoiseLite.new()


func _ready() -> void:
        noise.noise_type = FastNoiseLite.TYPE_OPEN_SIMPLEX2
        _spawn_ground()


func _spawn_ground() -> void:
        var mesh := PlaneMesh.new()
        mesh.size = Vector2(size_x, size_z)
        var mi := MeshInstance3D.new()
        mi.mesh = mesh
        add_child(mi)