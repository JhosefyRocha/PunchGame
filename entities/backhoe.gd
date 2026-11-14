extends CharacterBody2D

signal broken

enum State {
	IDLE,
	DRIVE,
	TURN,
	WINDUP,
	SLAM,
	STUCK,
	RECOVER,
	BROKEN,
}

const ARM_REST := -0.12
const ARM_RAISED := 0.75
const ARM_SLAMMED := -0.3
const ARM_BROKEN := -0.45

@export var max_health := 8
@export var score_reward := 300
@export var drive_speed := 34.0
@export var slam_range := 58.0
@export var windup_time := 0.7
@export var slam_time := 0.12
@export var stuck_time := 1.1
@export var recover_time := 0.4
@export var turn_time := 0.5
@export var arena_left := 0.0
@export var arena_right := 0.0

@onready var visual: Node2D = $Visual
@onready var body_sprite: Sprite2D = $Visual/Body
@onready var arm: Node2D = $Visual/Arm
@onready var dust: CPUParticles2D = $Visual/Arm/Dust
@onready var crush_area: Area2D = $CrushArea
@onready var slam_area: Area2D = $SlamArea
@onready var health_bar: Node2D = $HealthBar
@onready var smoke: CPUParticles2D = $Smoke

var current_health: int
var state := State.IDLE
var state_time := 0.0
var facing := -1.0
var flash_time := 0.0
var slam_area_x := 0.0


func _ready() -> void:
	add_to_group(&"enemies")
	current_health = max_health
	arm.rotation = ARM_REST
	smoke.emitting = false
	slam_area_x = slam_area.position.x


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += get_gravity().y * delta
	state_time += delta
	update_flash(delta)

	match state:
		State.IDLE, State.DRIVE:
			process_drive(delta)
		State.TURN:
			velocity.x = 0.0
			if state_time >= turn_time:
				set_facing(-facing)
				enter(State.DRIVE)
		State.WINDUP:
			velocity.x = 0.0
			arm.rotation = lerpf(ARM_REST, ARM_RAISED, minf(state_time / windup_time, 1.0))
			body_sprite.modulate = Color(1.0, 0.72, 0.55) if int(state_time * 10.0) % 2 == 0 else Color.WHITE
			if state_time >= windup_time:
				body_sprite.modulate = Color.WHITE
				enter(State.SLAM)
		State.SLAM:
			arm.rotation = lerpf(ARM_RAISED, ARM_SLAMMED, minf(state_time / slam_time, 1.0))
			if state_time >= slam_time:
				dust.restart()
				hurt_bodies_in(slam_area)
				enter(State.STUCK)
		State.STUCK:
			if state_time >= stuck_time:
				enter(State.RECOVER)
		State.RECOVER:
			arm.rotation = lerpf(ARM_SLAMMED, ARM_REST, minf(state_time / recover_time, 1.0))
			if state_time >= recover_time:
				enter(State.DRIVE)
		State.BROKEN:
			velocity.x = move_toward(velocity.x, 0.0, drive_speed)

	move_and_slide()


func process_drive(delta: float) -> void:
	var player := get_tree().get_first_node_in_group(&"player") as Node2D
	if player == null or not is_in_arena(player):
		state = State.IDLE
		velocity.x = move_toward(velocity.x, 0.0, drive_speed)
		return

	state = State.DRIVE
	var offset := player.global_position.x - global_position.x
	if absf(offset) > 4.0 and signf(offset) != facing:
		enter(State.TURN)
		return
	if absf(offset) <= slam_range:
		enter(State.WINDUP)
		return

	var next_x := global_position.x + facing * drive_speed * delta
	velocity.x = 0.0 if next_x < arena_left or next_x > arena_right else facing * drive_speed
	hurt_bodies_in(crush_area)


func is_in_arena(player: Node2D) -> bool:
	return player.global_position.x > arena_left - 60.0 \
		and player.global_position.x < arena_right + 60.0 \
		and absf(player.global_position.y - global_position.y) < 90.0


func enter(new_state: State) -> void:
	state = new_state
	state_time = 0.0


func set_facing(direction: float) -> void:
	facing = direction
	visual.scale.x = -facing
	slam_area.position.x = slam_area_x * -facing


func hurt_bodies_in(area: Area2D) -> void:
	for body in area.get_overlapping_bodies():
		if body.is_in_group(&"player") and body.has_method(&"take_damage"):
			body.take_damage(1, global_position)


func take_damage(amount: int, _source_position: Vector2 = Vector2.ZERO) -> void:
	if state == State.BROKEN or amount <= 0:
		return
	current_health = maxi(0, current_health - amount)
	flash_time = 0.12
	if current_health <= 0:
		break_down()


func update_flash(delta: float) -> void:
	if flash_time <= 0.0:
		return
	flash_time -= delta
	body_sprite.modulate = Color(1.0, 0.35, 0.3) if flash_time > 0.0 else Color.WHITE


func break_down() -> void:
	enter(State.BROKEN)
	ScoreManager.add_points(score_reward)
	set_collision_layer_value(2, false)
	crush_area.set_deferred(&"monitoring", false)
	slam_area.set_deferred(&"monitoring", false)
	health_bar.hide()
	smoke.emitting = true
	var tween := create_tween().set_parallel(true)
	tween.tween_property(arm, "rotation", ARM_BROKEN, 0.35).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_property(visual, "rotation", 0.05 * facing, 0.3)
	tween.tween_property(visual, "modulate", Color(0.5, 0.45, 0.42), 0.4)
	broken.emit()
