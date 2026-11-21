extends CharacterBody2D

const SPEED := 80.0
const JUMP_VELOCITY := -300.0
const DOUBLE_JUMP_VELOCITY := -260.0
const MAX_AIR_JUMPS := 1
const HIT_SCALE_FACTOR := 0.25
const VINE_CLIMB_SPEED := 65.0
const DAMAGE_INVULNERABILITY_TIME := 1.0
const ROLL_SPEED := 120.0
const ROLL_INVULNERABLE_FIRST_FRAME := 1
const ROLL_INVULNERABLE_LAST_FRAME := 6

@export_category("Combat")
@export var attack_damage := 1
@export_range(0.05, 1.0, 0.01) var attack_active_time := 0.16
@export var attack_offset := 12.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_hitbox: Area2D = $AttackHitbox
@onready var punch_swing_sound: AudioStreamPlayer = $PunchSwingSound
@onready var punch_hit_sound: AudioStreamPlayer = $PunchHitSound
@onready var punch_miss_sound: AudioStreamPlayer = $PunchMissSound
@onready var camera: Camera2D = $Camera2D

var is_hitting := false
var is_dead := false
var is_invulnerable := false
var is_rolling := false
var roll_direction := 1.0
var default_sprite_scale: Vector2
var vines_in_reach := 0
var respawn_position: Vector2
var attack_targets_hit: Dictionary = {}
var attack_sequence := 0
var air_jumps_left := MAX_AIR_JUMPS


func _ready() -> void:
	add_to_group(&"player")
	default_sprite_scale = anim.scale
	respawn_position = global_position
	attack_hitbox.monitoring = false


func _physics_process(delta: float) -> void:
	var is_on_vine := vines_in_reach > 0 and not is_rolling
	var vertical_direction := Input.get_axis(&"climb_up", &"climb_down")

	if is_on_vine and not is_hitting:
		velocity.y = vertical_direction * VINE_CLIMB_SPEED
	elif not is_on_floor():
		velocity += get_gravity() * delta

	# O pulo extra no ar recarrega ao tocar o chao ou segurar numa vinha.
	if is_on_floor() or is_on_vine:
		air_jumps_left = MAX_AIR_JUMPS

	if Input.is_action_just_pressed(&"roll") and is_on_floor() and not is_hitting and not is_rolling:
		start_roll()

	if is_rolling:
		velocity.x = roll_direction * ROLL_SPEED if anim.frame <= ROLL_INVULNERABLE_LAST_FRAME else 0.0
		move_and_slide()
		return

	if is_on_vine and Input.is_action_just_pressed(&"vine_release"):
		velocity.y = JUMP_VELOCITY
		vines_in_reach = 0
	elif not is_on_vine and Input.is_action_just_pressed(&"jump"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
		elif air_jumps_left > 0:
			air_jumps_left -= 1
			velocity.y = DOUBLE_JUMP_VELOCITY
			# Reinicia a animacao para o segundo pulo ficar visivel.
			if not is_hitting:
				anim.play(&"jump")
				anim.frame = 0

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


func start_roll() -> void:
	var direction := Input.get_axis(&"left", &"right")
	if not is_zero_approx(direction):
		anim.flip_h = direction < 0.0
	roll_direction = -1.0 if anim.flip_h else 1.0
	is_rolling = true
	anim.play(&"roll")


func is_roll_invulnerable() -> bool:
	return is_rolling \
		and anim.frame >= ROLL_INVULNERABLE_FIRST_FRAME \
		and anim.frame <= ROLL_INVULNERABLE_LAST_FRAME


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
	punch_swing_sound.play()

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
		if attack_targets_hit.is_empty():
			punch_miss_sound.play()


func try_hit_enemy(target: Node) -> void:
	if not is_hitting:
		return

	var enemy := target
	if not _is_attackable(enemy):
		enemy = target.get_parent()
	if enemy == null or not _is_attackable(enemy):
		return
	if attack_targets_hit.has(enemy) or not enemy.has_method(&"take_damage"):
		return

	var is_first_connection := attack_targets_hit.is_empty()
	attack_targets_hit[enemy] = true
	enemy.take_damage(attack_damage, global_position)
	if is_first_connection:
		punch_hit_sound.play()


func _is_attackable(node: Node) -> bool:
	return node.is_in_group(&"enemies")


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


func take_damage(amount: int = 1, source_position: Vector2 = Vector2.INF) -> void:
	if is_dead or is_invulnerable or amount <= 0:
		return
	if source_position != Vector2.INF and is_roll_invulnerable():
		return

	cancel_attack()
	is_rolling = false
	if HealthManager.lose_life(amount) <= 0:
		die()
		return

	is_invulnerable = true
	vines_in_reach = 0
	velocity = Vector2.ZERO
	global_position = respawn_position
	# Sem isto o amortecimento da camera arrasta a visao por todo o mapa ate o
	# checkpoint, passando por cima de area sem cenario.
	camera.reset_smoothing()
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
	if anim.animation == &"roll":
		is_rolling = false
	elif anim.animation == &"hit":
		cancel_attack()
	else:
		return

	var direction := Input.get_axis(&"left", &"right")
	update_movement_animation(direction, vines_in_reach > 0)
