extends CharacterBody3D

# variaveis de velocidades
const WALK_SPEED = 5.0
const RUN_SPEED = 7.0

# variaveis de pulo
const JUMP_VELOCITY = 4.5

# variaveis de camera
const SENSITIVITY = 0.004

# Headbob e inclinação
const BOB_FREQ = 8.0
const BOB_AMP_X = 0.02
const BOB_AMP_Y = 0.03

const MAX_CAMERA_TILT = deg_to_rad(5.0) # inclinação lateral máxima

var t_bob = 0.0
var bob_offset := Vector3.ZERO
var target_tilt = 0.0
var current_tilt = 0.0

#fov variables
const BASE_FOV = 75.0
const FOV_CHANGE = 1.5

var gravity = 9.8;
var speed

@onready var head = $Head
@onready var camera = $Head/Camera

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	# Handle Toggle Mouse
	if Input.is_action_just_pressed("mouse"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-60), deg_to_rad(60))

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Sprint.
	if Input.is_action_pressed("sprint"):
		speed = RUN_SPEED
	else:
		speed = WALK_SPEED

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (head.transform.basis * transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 7.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 7.0)
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 3.0)
	
	# Headbob
	if direction.length() > 0.1 and is_on_floor():
		t_bob += delta * speed
		var bob_target = _headbob(t_bob)
		bob_offset = bob_offset.lerp(bob_target, delta * 10.0)
		
		# Tilt lateral com base no input lateral
		target_tilt = -input_dir.x * MAX_CAMERA_TILT
	else:
		bob_offset = bob_offset.lerp(Vector3.ZERO, delta * 5.0)
		target_tilt = 0.0

	current_tilt = lerp(current_tilt, target_tilt, delta * 10.0)

	# Aplicar bob + tilt na câmera
	camera.rotation.z = current_tilt
	camera.position = bob_offset
		
	# FOV
	var velocity_clamped = clamp(velocity.length(), 0.5, RUN_SPEED * 2)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)

	move_and_slide()

func _headbob(time: float) -> Vector3:
	var pos = Vector3.ZERO
	pos.x = sin(time) * BOB_AMP_X   # balanço lateral
	pos.y = abs(cos(time * 2.0)) * BOB_AMP_Y  # impacto vertical
	return pos
