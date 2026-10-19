## Flag Pole
## End of level flag

extends Area3D

@export var flag_points: int = 5000

var is_activated: bool = false

@onready var flag_mesh: MeshInstance3D = $FlagMesh
@onready var pole_mesh: MeshInstance3D = $PoleMesh

signal level_complete(points: int)

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if is_activated:
		return
	
	if body.is_in_group("player"):
		is_activated = true
		level_complete.emit(flag_points)
		
		if flag_mesh:
			var tween = create_tween()
			tween.tween_property(flag_mesh, "position:y", -1.0, 1.0)
