## Player Controller Script
## Integrates all character capabilities

extends CharacterBody3D

## Export Variables
@export_group("Movement Settings")
@export var walk_speed: float = 5.0
@export var run_speed: float = 10.0
@export var crouch_speed: float = 2.5
@export var jump_velocity: float = 8.0
@export var gravity: float = 9.8

## Node References
@onready var movement: CharacterMovement = $CharacterMovement
@onready var jump_comp: JumpComponent = $JumpComponent
@onready var sprint_comp: SprintComponent = $SprintComponent
@onready var crouch_comp: CrouchComponent = $CrouchComponent
@onready var health: HealthSystem = $HealthSystem
@onready var inventory: InventorySystem = $InventorySystem
@onready var equipment: EquipmentSystem = $EquipmentSystem
@onready var camera: ThirdPersonCamera = $ThirdPersonCamera
@onready var footstep_player: FootstepPlayer = $FootstepPlayer
@onready var impact_audio: ImpactAudio = $ImpactAudio
@onready var dust_effect: DustEffect = $DustEffect

## State Variables
var current_speed: float = 5.0
var is_grounded: bool = true

func _ready() -> void:
	_setup_capabilites()

func _setup_capabilites() -> void:
	# Configure movement
	if movement:
		movement.walk_speed = walk_speed
		movement.run_speed = run_speed
		movement.crouch_speed = crouch_speed
	
	# Configure jump
	if jump_comp:
		jump_comp.jump_velocity = jump_velocity
	
	# Configure sprint
	if sprint_comp:
		sprint_comp.walk_speed = walk_speed
		sprint_comp.sprint_speed = run_speed
	
	# Configure crouch
	if crouch_comp:
		crouch_comp.walk_speed = walk_speed
		crouch_comp.crouch_speed = crouch_speed

func _physics_process(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
		is_grounded = false
	else:
		is_grounded = true
	
	# Get movement input
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Determine speed
	if sprint_comp and sprint_comp.get_is_sprinting():
		current_speed = run_speed
	elif crouch_comp and crouch_comp.is_crouching:
		current_speed = crouch_speed
	else:
		current_speed = walk_speed
	
	# Apply movement
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)
	
	move_and_slide()
	
	# Play footstep sounds
	if footstep_player and is_grounded and direction:
		footstep_player.start_walking()
	elif footstep_player:
		footstep_player.stop_walking()

## Handle collisions
func _on_body_entered(body: Node3D) -> void:
	if impact_audio:
		var collision = KinematicCollision3D.new()
		if get_slide_collision_count() > 0:
			collision = get_slide_collision(0)
			impact_audio.on_collision(collision)

## Get current surface
func get_surface_type() -> String:
	# Simple surface detection
	return "concrete"
