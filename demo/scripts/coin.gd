## Coin Collectible
## Collectible coin item

extends Area3D

@export var points: int = 100

var is_collected: bool = false

@onready var mesh: MeshInstance3D = $Mesh

signal collected(points: int)

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if mesh and not is_collected:
		mesh.rotate_y(delta * 3.0)

func _on_body_entered(body: Node3D) -> void:
	if is_collected:
		return
	
	if body.is_in_group("player"):
		is_collected = true
		collected.emit(points)
		body.collect_coin()
		
		if mesh:
			var tween = create_tween()
			tween.tween_property(mesh, "position:y", mesh.position.y + 1.0, 0.3)
			tween.parallel().tween_property(mesh, "modulate:a", 0.0, 0.3)
			tween.tween_callback(queue_free)
