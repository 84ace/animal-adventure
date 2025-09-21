# ----- create folders -----
mkdir -p client/scenes client/scripts/animal

# ----- Animal controller (only writes if missing) -----
if [ ! -f client/scripts/animal/AnimalController.gd ]; then
cat > client/scripts/animal/AnimalController.gd <<'GDS'
extends CharacterBody3D
class_name AnimalController

@export var walk_speed: float = 5.5
@export var sprint_speed: float = 8.0
@export var jump_velocity: float = 4.5

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var is_sprinting := false

func _physics_process(delta: float) -> void:
	var v := velocity
	if not is_on_floor():
		v.y -= gravity * delta

	var dir2 := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var cam := get_viewport().get_camera_3d()
	var f := -cam.transform.basis.z
	var r := cam.transform.basis.x
	var move := (f * dir2.y + r * dir2.x).normalized()

	var speed := is_sprinting ? sprint_speed : walk_speed
	v.x = move.x * speed
	v.z = move.z * speed

	if Input.is_action_just_pressed("jump") and is_on_floor():
		v.y = jump_velocity

	is_sprinting = Input.is_action_pressed("sprint")

	velocity = v
	move_and_slide()
GDS
fi

# ----- Minimal playable Main scene -----
cat > client/scenes/Main.tscn <<'TSCN'
[gd_scene load_steps=5 format=3]

[ext_resource type="Script" path="res://scripts/animal/AnimalController.gd" id="1"]

[sub_resource type="PlaneMesh" id="2"]
size = Vector2(100, 100)

[sub_resource type="StandardMaterial3D" id="3"]
albedo_color = Color(0.62, 0.78, 0.58, 1.0)

[node name="Main" type="Node3D"]

[node name="Ground" type="MeshInstance3D" parent="."]
mesh = SubResource("2")
material_override = SubResource("3")
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, -0.01, 0) # tiny drop so player doesn't clip

[node name="Sun" type="DirectionalLight3D" parent="."]
transform = Transform3D(0.866, 0, 0.5, 0.25, 0.866, -0.433, -0.433, 0.5, 0.75, 0, 8, 0)

[node name="Player" type="CharacterBody3D" parent="."]
transform = Transform3D(1,0,0, 0,1,0, 0,0,1, 0,1.1,0)
script = ExtResource("1")

[node name="Camera3D" type="Camera3D" parent="Player"]
transform = Transform3D(1,0,0, 0,1,0, 0,0,1, 0,2.2,6)
current = true

[node name="Capsule" type="MeshInstance3D" parent="Player"]
mesh = CapsuleMesh {
	radius = 0.3
	height = 1.2
}
TSCN

# ----- Ensure a main scene is set in project.godot -----
if ! grep -q "run/main_scene" client/project.godot 2>/dev/null; then
  # Create or append minimal project settings with input
  cat > client/project.godot <<'CFG'
; Engine configuration file.
config_version=5

[application]
config/name="Animal World Adventures"
run/main_scene="res://scenes/Main.tscn"

[input]
move_forward={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":87,"physical_keycode":0,"unicode":0,"echo":false,"script":null)]
}
move_back={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":83,"physical_keycode":0,"unicode":0,"echo":false,"script":null)]
}
move_left={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":65,"physical_keycode":0,"unicode":0,"echo":false,"script":null)]
}
move_right={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":68,"physical_keycode":0,"unicode":0,"echo":false,"script":null)]
}
jump={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":32,"physical_keycode":0,"unicode":0,"echo":false,"script":null)]
}
sprint={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":16777237,"physical_keycode":0,"unicode":0,"echo":false,"script":null)] ; Shift
}

[rendering]
environment/defaults/default_clear_color=Color(0.62, 0.83, 1.0, 1.0)
CFG
fi

# ----- Commit -----
#git checkout -b fix/client-main-scene || true
#git add client/scenes/Main.tscn client/scripts/animal/AnimalController.gd client/project.godot
#git commit -m "fix(client): add minimal Main.tscn and set as run/main_scene; wire basic input"
