extends CharacterBody2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

const SPEED = 80.0
const JUMP_VELOCITY = -300.0
const HIT_SCALE_FACTOR = 0.25
const VINE_CLIMB_SPEED = 65.0

var is_hitting := false
var is_dead := false
var default_sprite_scale: Vector2
var vines_in_reach := 0


func _ready() -> void:
	default_sprite_scale = anim.scale

func _physics_process(delta: float) -> void:
	var is_on_vine := vines_in_reach > 0
	var vertical_direction := Input.get_axis("climb_up", "climb_down")

	# On a vine the player can climb, or hang still without gravity.
	if is_on_vine and not is_hitting:
		velocity.y = vertical_direction * VINE_CLIMB_SPEED
	elif not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if is_on_vine and Input.is_action_just_pressed("vine_release"):
		velocity.y = JUMP_VELOCITY
		vines_in_reach = 0
	elif not is_on_vine and Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	if Input.is_action_just_pressed("hit") and not is_hitting:
		is_hitting = true
		velocity.x = 0.0
		anim.scale = default_sprite_scale * HIT_SCALE_FACTOR
		anim.play("hit")

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("left", "right")
	if is_hitting:
		velocity.x = 0.0
	elif direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	if is_hitting:
		pass
	elif is_on_floor():
		if direction > 0:
			anim.flip_h = false
			anim.play("walk")
		elif direction < 0:
			anim.flip_h = true
			anim.play("walk")
		else:
			anim.play("idle")
	elif is_on_vine:
		anim.play("idle")
	else:
		anim.play("jump")

	move_and_slide()


func die() -> void:
	if is_dead:
		return

	is_dead = true
	velocity = Vector2.ZERO
	set_physics_process(false)
	get_tree().call_group(&"game_menu", &"show_death_screen")


func enter_vine() -> void:
	vines_in_reach += 1


func exit_vine() -> void:
	vines_in_reach = maxi(0, vines_in_reach - 1)


func _on_animated_sprite_2d_animation_finished() -> void:
	if anim.animation == &"hit":
		is_hitting = false

		# Troca o sprite antes de restaurar a escala para que o ultimo
		# frame de ataque (128x128) nunca apareca no tamanho normal.
		var direction := Input.get_axis("left", "right")
		if not is_on_floor():
			anim.play("jump")
		elif direction:
			anim.play("walk")
		else:
			anim.play("idle")

		anim.scale = default_sprite_scale
