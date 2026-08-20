extends CharacterBody2D

const SPEED := 80.0
const JUMP_VELOCITY := -300.0
const HIT_SCALE_FACTOR := 0.25
const VINE_CLIMB_SPEED := 65.0
const DAMAGE_INVULNERABILITY_TIME := 1.0

@export_category("Combat")
@export var attack_damage := 1
@export_range(0.05, 1.0, 0.01) var attack_active_time := 0.16
@export var attack_offset := 14.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_hitbox: Area2D = $AttackHitbox

var is_hitting := false
var is_dead := false
var is_invulnerable := false
var default_sprite_scale: Vector2
var vines_in_reach := 0
var respawn_position: Vector2
var attack_targets_hit: Dictionary = {}
var attack_sequence := 0


func _ready() -> void:
	add_to_group(&"player")
	default_sprite_scale = anim.scale
	respawn_position = global_position
	attack_hitbox.monitoring = false


func _physics_process(delta: float) -> void:
	var is_on_vine := vines_in_reach > 0
	var vertical_direction := Input.get_axis(&"climb_up", &"climb_down")

	if is_on_vine and not is_hitting:
		velocity.y = vertical_direction * VINE_CLIMB_SPEED
	elif not is_on_floor():
		velocity += get_gravity() * delta

	if is_on_vine and Input.is_action_just_pressed(&"vine_release"):
		velocity.y = JUMP_VELOCITY
		vines_in_reach = 0
	elif not is_on_vine and Input.is_action_just_pressed(&"jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	if Input.is_action_just_pressed(&"attack") and not is_hitting:
		start_attack()

	var direction := Input.get_axis(&"left", &"right")
	if is_hitting:
		velocity.x = 0.0
	elif not is_zero_approx(direction):
		velocity.x = direction * SPEED
		anim.flip_h = direction < 0.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)

	if not is_hitting:
		update_movement_animation(direction, is_on_vine)

	move_and_slide()


func start_attack() -> void:
	is_hitting = true
	attack_sequence += 1
	var current_sequence := attack_sequence
	attack_targets_hit.clear()
	velocity.x = 0.0

	var facing_sign := -1.0 if anim.flip_h else 1.0
	attack_hitbox.position.x = absf(attack_offset) * facing_sign
	attack_hitbox.monitoring = true
	anim.scale = default_sprite_scale * HIT_SCALE_FACTOR
	anim.play(&"hit")

	# Tambem detecta alvos que ja estavam dentro da area quando ela foi ativada.
	await get_tree().physics_frame
	if current_sequence != attack_sequence or not is_hitting:
		return
	for body in attack_hitbox.get_overlapping_bodies():
		try_hit_enemy(body)
	for area in attack_hitbox.get_overlapping_areas():
		try_hit_enemy(area)

	await get_tree().create_timer(attack_active_time).timeout
	if current_sequence == attack_sequence:
		attack_hitbox.monitoring = false


func try_hit_enemy(target: Node) -> void:
	if not is_hitting:
		return

	var enemy := target
	if not enemy.is_in_group(&"enemies"):
		enemy = target.get_parent()
	if enemy == null or not enemy.is_in_group(&"enemies"):
		return
	if attack_targets_hit.has(enemy) or not enemy.has_method(&"take_damage"):
		return

	attack_targets_hit[enemy] = true
	enemy.take_damage(attack_damage, global_position)


func _on_attack_hitbox_body_entered(body: Node2D) -> void:
	try_hit_enemy(body)


func _on_attack_hitbox_area_entered(area: Area2D) -> void:
	try_hit_enemy(area)


func update_movement_animation(direction: float, is_on_vine: bool) -> void:
	if is_on_floor():
		anim.play(&"walk" if not is_zero_approx(direction) else &"idle")
	elif is_on_vine:
		anim.play(&"idle")
	else:
		anim.play(&"fall" if velocity.y > 0.0 else &"jump")


func set_checkpoint(checkpoint_position: Vector2) -> void:
	respawn_position = checkpoint_position


func take_damage(amount: int = 1, _source_position: Vector2 = Vector2.INF) -> void:
	if is_dead or is_invulnerable or amount <= 0:
		return

	cancel_attack()
	if HealthManager.lose_life(amount) <= 0:
		die()
		return

	is_invulnerable = true
	vines_in_reach = 0
	velocity = Vector2.ZERO
	global_position = respawn_position
	anim.play(&"idle")

	var blink := create_tween().set_loops(5)
	blink.tween_property(anim, "modulate:a", 0.25, 0.08)
	blink.tween_property(anim, "modulate:a", 1.0, 0.08)
	await get_tree().create_timer(DAMAGE_INVULNERABILITY_TIME).timeout
	anim.modulate.a = 1.0
	is_invulnerable = false


func die() -> void:
	if is_dead:
		return

	is_dead = true
	cancel_attack()
	velocity = Vector2.ZERO
	set_physics_process(false)
	get_tree().call_group(&"game_menu", &"show_death_screen")


func cancel_attack() -> void:
	attack_sequence += 1
	is_hitting = false
	attack_targets_hit.clear()
	attack_hitbox.set_deferred(&"monitoring", false)
	anim.scale = default_sprite_scale


func enter_vine() -> void:
	vines_in_reach += 1


func exit_vine() -> void:
	vines_in_reach = maxi(0, vines_in_reach - 1)


func _on_animated_sprite_2d_animation_finished() -> void:
	if anim.animation != &"hit":
		return

	cancel_attack()
	var direction := Input.get_axis(&"left", &"right")
	update_movement_animation(direction, vines_in_reach > 0)
