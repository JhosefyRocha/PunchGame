extends CharacterBody2D
class_name Lumberjack

signal defeated(points_awarded: int)

const SPRITE_BASE_Y := 0.1
## A arte-base (`sprites/enemies/lumberjack.png`) desenha o tronco a direita do
## centro da textura, com o machado esticado para a esquerda. `flip_h` espelha a
## textura mas NAO espelha um deslocamento, entao o offset e virado na mao em
## `update_facing()` -- sem isso o corpo visivel nao bate com a colisao ao virar.
const SPRITE_BODY_OFFSET_X := 2.4
## Distancia do centro do corpo ate a cabeca do machado.
const AXE_REACH := 10.0

enum State {
	PATROL,
	CHASE,
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
@export var chase_speed := 42.0
## A que distancia horizontal o golpe comeca. Fica um pouco alem de `AXE_REACH`
## para o inimigo nao precisar encostar no jogador para atacar.
@export var attack_range := 18.0
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
@onready var detection_area: Area2D = $DetectionArea

var state := State.PATROL
var current_health: int
var patrol_origin_x: float
var move_direction := -1.0
var pause_time_left := 0.0
var hurt_time_left := 0.0
var attack_cooldown_left := 0.0
var attack_time_left := 0.0
## 0 = preparando o golpe, 1 = recuperando depois dele.
var attack_phase := 0
var attack_tween: Tween
var walk_phase := 0.0


func _ready() -> void:
	add_to_group(&"enemies")
	current_health = max_health
	patrol_origin_x = global_position.x
	reset_sprite_bob()
	update_facing()
	sprite.play(&"idle")


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return

	if not is_on_floor():
		velocity += get_gravity() * delta

	attack_cooldown_left = maxf(0.0, attack_cooldown_left - delta)

	match state:
		State.HURT:
			process_hurt(delta)
		State.ATTACK:
			process_attack(delta)
		_:
			process_ground_ai(delta)

	move_and_slide()


# --- Percepcao e locomocao ---------------------------------------------------


func process_ground_ai(delta: float) -> void:
	var target := find_target()
	if target != null:
		process_chase(delta, target)
		return

	state = State.PATROL
	process_patrol(delta)


func find_target() -> Node2D:
	for body in detection_area.get_overlapping_bodies():
		if body.is_in_group(&"player"):
			return body as Node2D
	return null


func process_chase(delta: float, target: Node2D) -> void:
	state = State.CHASE
	pause_time_left = 0.0

	var offset_x := target.global_position.x - global_position.x
	var desired_direction := signf(offset_x)
	if not is_zero_approx(desired_direction) and desired_direction != move_direction:
		move_direction = desired_direction
		update_facing()

	if absf(offset_x) <= attack_range:
		velocity.x = move_toward(velocity.x, 0.0, chase_speed)
		reset_sprite_bob()
		if is_zero_approx(attack_cooldown_left):
			start_axe_attack()
		else:
			sprite.play(&"idle")
		return

	# Perseguir nunca justifica cair da plataforma nem entrar na parede.
	update_checks()
	if is_on_floor() and (not ledge_check.is_colliding() or wall_check.is_colliding()):
		velocity.x = move_toward(velocity.x, 0.0, chase_speed)
		reset_sprite_bob()
		sprite.play(&"idle")
		return

	velocity.x = move_direction * chase_speed
	sprite.play(&"walk")
	advance_walk_bob(delta)


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
	advance_walk_bob(delta)


func pause_before_turn() -> void:
	pause_time_left = turn_pause
	velocity.x = 0.0
	reset_sprite_bob()
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
	sprite.position.x = SPRITE_BODY_OFFSET_X * (1.0 if sprite.flip_h else -1.0)
	axe_hitbox.position.x = AXE_REACH * move_direction
	update_checks()


func advance_walk_bob(delta: float) -> void:
	walk_phase += delta * 12.0
	sprite.position.y = SPRITE_BASE_Y + sin(walk_phase) * 0.35


func reset_sprite_bob() -> void:
	sprite.position.y = SPRITE_BASE_Y


# --- Ataque ------------------------------------------------------------------
#
# O golpe e um relogio tocado em `_physics_process`, nao uma corrotina com
# `await`. A versao antiga aguardava dois timers da SceneTree e qualquer retorno
# antecipado deixava `state` preso em ATTACK para sempre, congelando o inimigo.
# Aqui `attack_time_left` e a unica autoridade: enquanto o estado for ATTACK ha
# sempre um contador correndo em direcao a `finish_attack()`.


func start_axe_attack() -> void:
	state = State.ATTACK
	attack_phase = 0
	attack_time_left = attack_windup
	# O cooldown trava no inicio do golpe, nao depois do windup: assim um golpe
	# interrompido por dano nao libera um ataque imediato na sequencia.
	attack_cooldown_left = attack_cooldown
	velocity.x = 0.0
	reset_sprite_bob()
	sprite.play(&"attack")

	attack_tween = create_tween()
	attack_tween.tween_property(sprite, "rotation", 0.12 * move_direction, attack_windup)
	attack_tween.tween_property(sprite, "rotation", 0.0, attack_recovery)


func process_attack(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, patrol_speed)

	attack_time_left -= delta
	if attack_time_left > 0.0:
		return

	if attack_phase == 0:
		attack_phase = 1
		attack_time_left = attack_recovery
		apply_axe_damage()
		return

	finish_attack()


func apply_axe_damage() -> void:
	# Consulta a sobreposicao no instante do golpe. Uma lista alimentada por
	# body_entered/exited fica desatualizada quando `Player.take_damage()`
	# teleporta o jogador para o checkpoint no meio do swing.
	for body in axe_hitbox.get_overlapping_bodies():
		if body.is_in_group(&"player") and body.has_method(&"take_damage"):
			body.take_damage(contact_damage, global_position)


func finish_attack() -> void:
	cancel_attack()
	if state == State.ATTACK:
		state = State.PATROL
		sprite.play(&"idle")


func cancel_attack() -> void:
	if attack_tween != null and attack_tween.is_valid():
		attack_tween.kill()
	attack_tween = null
	attack_time_left = 0.0
	attack_phase = 0
	sprite.rotation = 0.0


# --- Dano e morte ------------------------------------------------------------


func take_damage(amount: int, source_position: Vector2) -> void:
	if state == State.DEAD or amount <= 0:
		return

	cancel_attack()
	current_health = maxi(0, current_health - amount)
	if current_health <= 0:
		die()
		return

	state = State.HURT
	hurt_time_left = hurt_duration
	# Nao pode revidar no mesmo quadro em que termina de se recuperar.
	attack_cooldown_left = maxf(attack_cooldown_left, hurt_duration + 0.15)
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
	cancel_attack()
	velocity = Vector2.ZERO
	ScoreManager.add_points(score_reward)
	defeated.emit(score_reward)
	set_physics_process(false)
	set_collision_layer_value(2, false)
	body_collision.set_deferred(&"disabled", true)
	hurtbox.set_deferred(&"monitorable", false)
	axe_hitbox.set_deferred(&"monitoring", false)
	detection_area.set_deferred(&"monitoring", false)
	sprite.modulate = Color.WHITE
	reset_sprite_bob()
	sprite.play(&"die")

	# TWEEN_PAUSE_PROCESS: se o inimigo morrer no mesmo quadro em que a tela de
	# morte pausa a arvore, o padrao (BOUND) congelaria o tween e o no nunca
	# chegaria ao `queue_free()`.
	var death_tween := create_tween().set_parallel(true).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	death_tween.tween_property(sprite, "rotation", PI * 0.5 * move_direction, 0.24)
	death_tween.tween_property(sprite, "modulate:a", 0.0, 0.22).set_delay(0.12)
	await death_tween.finished
	queue_free()
