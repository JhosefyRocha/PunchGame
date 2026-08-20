extends CharacterBody2D
class_name Lumberjack

signal defeated(points_awarded: int)

const SPRITE_BASE_Y := 0.1

enum State {
	PATROL,
	ATTACK,
	HURT,
	DEAD,
}

@export_category("Patrol")
@export var patrol_speed := 28.0
@export var patrol_distance := 72.0
@export var turn_pause := 0.2

@export_category("Combat")
@export var max_health := 3
@export var contact_damage := 1
@export var score_reward := 100
@export var knockback_force := 110.0
@export var hurt_duration := 0.18
@export var attack_windup := 0.12
@export var attack_recovery := 0.32
@export var attack_cooldown := 0.8

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var body_collision: CollisionShape2D = $CollisionShape2D
@onready var ledge_check: RayCast2D = $LedgeCheck
@onready var wall_check: RayCast2D = $WallCheck
@onready var hurtbox: Area2D = $Hurtbox
@onready var axe_hitbox: Area2D = $AxeHitbox

var state := State.PATROL
var current_health: int
var patrol_origin_x: float
var move_direction := -1.0
var pause_time_left := 0.0
var hurt_time_left := 0.0
var attack_cooldown_left := 0.0
var action_sequence := 0
var walk_phase := 0.0
var players_in_axe_range: Array[Node2D] = []


func _ready() -> void:
	add_to_group(&"enemies")
	current_health = max_health
	patrol_origin_x = global_position.x
	update_facing()
	sprite.play(&"idle")


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return

	if not is_on_floor():
		velocity += get_gravity() * delta

	attack_cooldown_left = maxf(0.0, attack_cooldown_left - delta)

	if state == State.HURT:
		process_hurt(delta)
		move_and_slide()
		return

	if state == State.ATTACK:
		velocity.x = move_toward(velocity.x, 0.0, patrol_speed)
		move_and_slide()
		return

	remove_invalid_targets()
	if not players_in_axe_range.is_empty() and is_zero_approx(attack_cooldown_left):
		start_axe_attack()
		move_and_slide()
		return

	process_patrol(delta)
	move_and_slide()


func process_patrol(delta: float) -> void:
	if pause_time_left > 0.0:
		pause_time_left -= delta
		velocity.x = move_toward(velocity.x, 0.0, patrol_speed)
		sprite.play(&"idle")
		return

	if absf(global_position.x - patrol_origin_x) >= patrol_distance:
		move_direction = -signf(global_position.x - patrol_origin_x)
		pause_before_turn()
		return

	update_checks()
	if is_on_floor() and (not ledge_check.is_colliding() or wall_check.is_colliding()):
		move_direction *= -1.0
		pause_before_turn()
		return

	velocity.x = move_direction * patrol_speed
	sprite.play(&"walk")
	walk_phase += delta * 12.0
	sprite.position.y = SPRITE_BASE_Y + sin(walk_phase) * 0.35


func pause_before_turn() -> void:
	pause_time_left = turn_pause
	velocity.x = 0.0
	sprite.position.y = SPRITE_BASE_Y
	update_facing()
	sprite.play(&"idle")


func update_checks() -> void:
	ledge_check.position.x = 10.0 * move_direction
	wall_check.target_position.x = 12.0 * move_direction
	ledge_check.force_raycast_update()
	wall_check.force_raycast_update()


func update_facing() -> void:
	# A arte-base olha para a esquerda, com o machado desse lado.
	sprite.flip_h = move_direction > 0.0
	axe_hitbox.position.x = 15.0 * move_direction
	update_checks()


func start_axe_attack() -> void:
	if state != State.PATROL:
		return

	state = State.ATTACK
	action_sequence += 1
	var current_sequence := action_sequence
	velocity.x = 0.0
	sprite.position.y = SPRITE_BASE_Y
	sprite.play(&"attack")

	var swing := create_tween()
	swing.tween_property(sprite, "rotation", 0.12 * move_direction, attack_windup)
	swing.tween_property(sprite, "rotation", 0.0, attack_recovery)

	await get_tree().create_timer(attack_windup).timeout
	if current_sequence != action_sequence or state != State.ATTACK:
		return

	remove_invalid_targets()
	for player in players_in_axe_range:
		if player.has_method(&"take_damage"):
			player.take_damage(contact_damage, global_position)

	attack_cooldown_left = attack_cooldown
	await get_tree().create_timer(attack_recovery).timeout
	if current_sequence == action_sequence and state == State.ATTACK:
		state = State.PATROL
		sprite.play(&"idle")


func take_damage(amount: int, source_position: Vector2) -> void:
	if state == State.DEAD or amount <= 0:
		return

	action_sequence += 1
	current_health = maxi(0, current_health - amount)
	if current_health <= 0:
		die()
		return

	state = State.HURT
	hurt_time_left = hurt_duration
	move_direction = signf(global_position.x - source_position.x)
	if is_zero_approx(move_direction):
		move_direction = 1.0
	velocity = Vector2(move_direction * knockback_force, -35.0)
	update_facing()
	sprite.play(&"hurt")
	sprite.modulate = Color(1.0, 0.22, 0.22, 1.0)


func process_hurt(delta: float) -> void:
	hurt_time_left -= delta
	velocity.x = move_toward(velocity.x, 0.0, knockback_force * delta * 4.0)
	if hurt_time_left > 0.0:
		return

	sprite.modulate = Color.WHITE
	state = State.PATROL
	sprite.play(&"idle")


func die() -> void:
	if state == State.DEAD:
		return

	state = State.DEAD
	action_sequence += 1
	velocity = Vector2.ZERO
	ScoreManager.add_points(score_reward)
	defeated.emit(score_reward)
	set_physics_process(false)
	set_collision_layer_value(2, false)
	body_collision.set_deferred(&"disabled", true)
	hurtbox.set_deferred(&"monitorable", false)
	axe_hitbox.set_deferred(&"monitoring", false)
	sprite.modulate = Color.WHITE
	sprite.position.y = SPRITE_BASE_Y
	sprite.play(&"die")

	var death_tween := create_tween().set_parallel(true)
	death_tween.tween_property(sprite, "rotation", PI * 0.5 * move_direction, 0.24)
	death_tween.tween_property(sprite, "modulate:a", 0.0, 0.22).set_delay(0.12)
	await death_tween.finished
	queue_free()


func remove_invalid_targets() -> void:
	for index in range(players_in_axe_range.size() - 1, -1, -1):
		if not is_instance_valid(players_in_axe_range[index]):
			players_in_axe_range.remove_at(index)


func _on_axe_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"player") and not players_in_axe_range.has(body):
		players_in_axe_range.append(body)


func _on_axe_hitbox_body_exited(body: Node2D) -> void:
	players_in_axe_range.erase(body)
