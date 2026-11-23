extends CanvasLayer

@onready var hearts: Array[TextureRect] = [
	$SafeArea/TopBar/HealthPanel/Padding/Hearts/Heart1,
	$SafeArea/TopBar/HealthPanel/Padding/Hearts/Heart2,
	$SafeArea/TopBar/HealthPanel/Padding/Hearts/Heart3,
]
@onready var score_label: Label = $SafeArea/TopBar/ScorePanel/Padding/Score
@onready var rescue_label: Label = $SafeArea/TopBar/RescuePanel/Padding/Rescues
@onready var punch_cooldown: ColorRect = $SafeArea/TopBar/AbilitiesPanel/Padding/Abilities/Punch/Cooldown
@onready var double_jump_cooldown: ColorRect = $SafeArea/TopBar/AbilitiesPanel/Padding/Abilities/DoubleJump/Cooldown
@onready var roll_cooldown: ColorRect = $SafeArea/TopBar/AbilitiesPanel/Padding/Abilities/Roll/Cooldown

const HEART_FULL := preload("res://sprites/hud/heart_full.png")
const HEART_EMPTY := preload("res://sprites/hud/heart_empty.png")
const CAGES_PER_PHASE := 3

var rescue_prefix := ""


func _ready() -> void:
	rescue_prefix = "phase_%d_cage_" % (SaveManager.get_level_index(owner.scene_file_path) + 1)
	HealthManager.lives_changed.connect(_on_lives_changed)
	ScoreManager.score_changed.connect(_on_score_changed)
	RescueManager.rescue_count_changed.connect(_on_rescue_count_changed)

	_on_lives_changed(HealthManager.current_lives, HealthManager.MAX_LIVES)
	_on_score_changed(ScoreManager.current_score)
	_on_rescue_count_changed(RescueManager.get_rescue_count(), RescueManager.TOTAL_ANIMALS)


func _on_lives_changed(current: int, _maximum: int) -> void:
	for index in hearts.size():
		hearts[index].texture = HEART_FULL if index < current else HEART_EMPTY


func _on_score_changed(value: int) -> void:
	score_label.text = "PONTOS %06d" % value


func _on_rescue_count_changed(_current: int, _total: int) -> void:
	rescue_label.text = "RESGATES %d/%d" % [RescueManager.count_rescued(rescue_prefix), CAGES_PER_PHASE]


func _process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group(&"player")
	if player == null:
		return
	var anim: AnimatedSprite2D = player.anim
	_set_cooldown(punch_cooldown, _animation_remaining(anim, &"hit") if player.is_hitting else 0.0)
	_set_cooldown(roll_cooldown, player.get_roll_recharge())
	# O pulo duplo so volta ao tocar o chao ou segurar numa vinha.
	_set_cooldown(double_jump_cooldown, 1.0 if player.air_jumps_left <= 0 else 0.0)


func _animation_remaining(anim: AnimatedSprite2D, animation: StringName) -> float:
	if anim.animation != animation:
		return 0.0
	var frame_count := anim.sprite_frames.get_frame_count(animation)
	if frame_count <= 0:
		return 0.0
	return clampf(1.0 - (anim.frame + anim.frame_progress) / frame_count, 0.0, 1.0)


# O sombreado cobre o icone de cima para baixo e encolhe conforme a habilidade recarrega.
func _set_cooldown(overlay: ColorRect, remaining: float) -> void:
	var slot_size := (overlay.get_parent() as Control).size
	overlay.position = Vector2.ZERO
	overlay.size = Vector2(slot_size.x, slot_size.y * remaining)
	overlay.visible = remaining > 0.0
