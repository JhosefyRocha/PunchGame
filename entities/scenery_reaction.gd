extends Node2D

@export var canopy_path: NodePath
@export var rescue_prefix := "phase_1_cage_"
@export var total_cages := 3
@export var level_width := 3840.0
@export var bird_count := 4

const DIM_TINT := Color(0.72, 0.62, 0.55, 1.0)
const BLOOM_TINT := Color(1.25, 1.25, 1.25, 1.0)

var canopy: CanvasItem
var birds: Array[Node2D] = []
var shown_progress := -1.0


func _ready() -> void:
	canopy = get_node_or_null(canopy_path) as CanvasItem
	for index in bird_count:
		birds.append(_make_bird())
	RescueManager.rescue_count_changed.connect(_on_rescue_count_changed)
	_apply_progress(_progress(), false)


func _progress() -> float:
	var rescued := 0
	for rescue_id in RescueManager.rescued_animals:
		if String(rescue_id).begins_with(rescue_prefix):
			rescued += 1
	return clampf(float(rescued) / float(total_cages), 0.0, 1.0)


func _on_rescue_count_changed(_current: int, _total: int) -> void:
	var progress := _progress()
	var was_complete := shown_progress >= 1.0
	_apply_progress(progress, true)
	if progress >= 1.0 and not was_complete:
		_bloom()


func _apply_progress(progress: float, animate: bool) -> void:
	shown_progress = progress
	if canopy != null:
		var target := DIM_TINT.lerp(Color.WHITE, progress)
		if animate:
			create_tween().tween_property(canopy, "modulate", target, 0.8).set_trans(Tween.TRANS_SINE)
		else:
			canopy.modulate = target

	var visible_birds := ceili(progress * bird_count)
	for index in birds.size():
		var bird := birds[index]
		var should_show := index < visible_birds
		if should_show and not bird.visible:
			bird.visible = true
			bird.scale = Vector2.ZERO
			create_tween().tween_property(bird, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK)
		elif not should_show:
			bird.visible = false


func _bloom() -> void:
	if canopy == null:
		return
	var tween := create_tween()
	tween.tween_property(canopy, "modulate", BLOOM_TINT, 0.25)
	tween.tween_property(canopy, "modulate", Color.WHITE, 0.6)


func _make_bird() -> Node2D:
	var bird := Node2D.new()
	bird.z_index = -1
	bird.visible = false
	var shape := Line2D.new()
	shape.points = PackedVector2Array([Vector2(-4, -2), Vector2(0, 0), Vector2(4, -2)])
	shape.width = 1.2
	shape.default_color = Color(0.1, 0.13, 0.1, 0.85)
	bird.add_child(shape)
	bird.position = Vector2(randf_range(0.0, level_width), randf_range(20.0, 60.0))
	add_child(bird)
	_fly(bird)
	return bird


func _fly(bird: Node2D) -> void:
	var start_x := bird.position.x
	var tween := bird.create_tween().set_loops()
	tween.tween_property(bird, "position:x", start_x + 60.0, 4.0).set_trans(Tween.TRANS_SINE)
	tween.tween_property(bird, "position:x", start_x, 4.0).set_trans(Tween.TRANS_SINE)
