extends CharacterBody3D
## Third-person player: WASD + mouse orbit camera, interaction, footsteps.

const WALK_SPEED := 2.6
const SPRINT_SPEED := 4.3
const GRAVITY := 9.8
const ACCEL := 12.0

signal interacted(action: String)
signal prompt_changed(text: String)

var yaw_node: Node3D
var pitch_node: Node3D
var cam: Camera3D
var spring: SpringArm3D
var body_mesh: Node3D

var frozen: bool = false
var mouse_captured: bool = false
var current_interactable: Node = null
var _step_accum: float = 0.0
var _bob_t: float = 0.0

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.28
	cap.height = 1.6
	cs.shape = cap
	cs.position = Vector3(0, 0.8, 0)
	add_child(cs)
	_build_visuals()
	_build_camera()

func _build_visuals() -> void:
	body_mesh = Node3D.new()
	add_child(body_mesh)
	var hoodie := Color(0.13, 0.35, 0.42)
	var pants := Color(0.15, 0.16, 0.22)
	var skin := Color(0.82, 0.62, 0.5)
	var shoe := Color(0.1, 0.1, 0.12)
	var m_hood := _mat(hoodie, 1.0)
	var m_pants := _mat(pants, 1.0)
	var m_skin := _mat(skin, 0.9)
	var m_shoe := _mat(shoe, 0.8)
	# torso + hoodie
	_part(body_mesh, Vector3(0.42, 0.52, 0.24), Vector3(0, 1.02, 0), m_hood)
	_part(body_mesh, Vector3(0.46, 0.14, 0.26), Vector3(0, 1.28, 0), _mat(hoodie.darkened(0.2), 1.0))
	# head
	_part(body_mesh, Vector3(0.24, 0.26, 0.24), Vector3(0, 1.52, 0), m_skin)
	# hair
	_part(body_mesh, Vector3(0.26, 0.1, 0.26), Vector3(0, 1.64, 0), _mat(Color(0.12, 0.09, 0.07), 1.0))
	# arms
	_part(body_mesh, Vector3(0.11, 0.5, 0.13), Vector3(-0.27, 1.04, 0), m_hood)
	_part(body_mesh, Vector3(0.11, 0.5, 0.13), Vector3(0.27, 1.04, 0), m_hood)
	# legs
	_part(body_mesh, Vector3(0.15, 0.62, 0.17), Vector3(-0.1, 0.42, 0), m_pants)
	_part(body_mesh, Vector3(0.15, 0.62, 0.17), Vector3(0.1, 0.42, 0), m_pants)
	# shoes
	_part(body_mesh, Vector3(0.16, 0.08, 0.24), Vector3(-0.1, 0.05, 0.02), m_shoe)
	_part(body_mesh, Vector3(0.16, 0.08, 0.24), Vector3(0.1, 0.05, 0.02), m_shoe)

func _mat(c: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m

func _part(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi

func _build_camera() -> void:
	yaw_node = Node3D.new()
	yaw_node.position = Vector3(0, 1.5, 0)
	add_child(yaw_node)
	pitch_node = Node3D.new()
	yaw_node.add_child(pitch_node)
	spring = SpringArm3D.new()
	spring.spring_length = 2.7
	spring.margin = 0.25
	spring.collision_mask = 1
	pitch_node.add_child(spring)
	cam = Camera3D.new()
	cam.fov = 70.0
	cam.near = 0.05
	spring.add_child(cam)
	cam.position = Vector3(0, 0, 0)
	cam.current = true

func get_yaw() -> float:
	return yaw_node.rotation.y

func set_yaw(v: float) -> void:
	yaw_node.rotation.y = v

func set_mouse_captured(on: bool) -> void:
	mouse_captured = on
	if on:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _unhandled_input(event: InputEvent) -> void:
	if frozen:
		return
	if event is InputEventMouseMotion and mouse_captured:
		var sens: float = 0.0022 * float(Config.values.get("mouse_sensitivity", 1.0))
		yaw_node.rotation.y -= event.relative.x * sens
		pitch_node.rotation.x = clampf(pitch_node.rotation.x - event.relative.y * sens, -0.9, 0.55)
	elif event.is_action_pressed("interact"):
		if current_interactable != null:
			var action: String = str(current_interactable.get_meta("action"))
			interacted.emit(action)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0
	var input_dir := Vector2.ZERO
	if not frozen:
		input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var dir := (yaw_node.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	dir.y = 0
	dir = dir.normalized()
	var speed := WALK_SPEED
	if Input.is_action_pressed("sprint") and not frozen and Game.energy > 12.0:
		speed = SPRINT_SPEED
	if not frozen and is_on_floor():
		var target := dir * speed
		velocity.x = move_toward(velocity.x, target.x, ACCEL * delta)
		velocity.z = move_toward(velocity.z, target.z, ACCEL * delta)
		if dir.length() > 0.1:
			_step_accum += delta * speed
			if _step_accum > 1.1:
				_step_accum = 0.0
				Sfx.play("footstep")
		else:
			_step_accum = 0.6
	move_and_slide()
	_update_bob(delta)
	_update_interactable()

func _update_bob(delta: float) -> void:
	if body_mesh == null:
		return
	var moving := Vector2(velocity.x, velocity.z).length() > 0.4
	_bob_t += delta * (7.0 if moving else 1.6)
	var amp := 0.035 if moving else 0.012
	body_mesh.position.y = absf(sin(_bob_t)) * amp
	body_mesh.rotation.z = sin(_bob_t) * (0.045 if moving else 0.0)
	# face movement direction
	if moving:
		var look := atan2(velocity.x, velocity.z)
		body_mesh.rotation.y = lerp_angle(body_mesh.rotation.y, look, 10.0 * delta)

func _update_interactable() -> void:
	if frozen:
		if current_interactable != null:
			current_interactable = null
			prompt_changed.emit("")
		return
	var best: Node = null
	var best_d := 2.3
	for node in get_tree().get_nodes_in_group("interactable"):
		var d: float = node.global_position.distance_to(global_position + Vector3(0, 0.9, 0))
		if d < best_d:
			best_d = d
			best = node
	if best != current_interactable:
		current_interactable = best
		if best != null:
			prompt_changed.emit(str(best.get_meta("prompt")))
		else:
			prompt_changed.emit("")

func freeze() -> void:
	frozen = true
	velocity = Vector3.ZERO

func unfreeze() -> void:
	frozen = false

# ---------------- scripted movement (used by capture mode) ----------------
func scripted_move_to(target: Vector3, timeout := 8.0) -> void:
	## Walk toward target on XZ plane; call from async context with awaits.
	var t := 0.0
	while t < timeout:
		var to := target - global_position
		to.y = 0
		if to.length() < 0.25:
			break
		var dir := to.normalized()
		velocity.x = dir.x * WALK_SPEED
		velocity.z = dir.z * WALK_SPEED
		# aim camera loosely toward movement
		var want := atan2(-dir.x, -dir.z)
		yaw_node.rotation.y = lerp_angle(yaw_node.rotation.y, want, 0.1)
		await get_tree().create_timer(0.05).timeout
		t += 0.05
	velocity.x = 0
	velocity.z = 0

func scripted_look(yaw: float, pitch: float) -> void:
	yaw_node.rotation.y = yaw
	pitch_node.rotation.x = pitch
