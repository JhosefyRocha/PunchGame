extends StaticBody2D

@export var boss_path: NodePath

@onready var body: Node2D = $Body
@onready var cages: Node2D = $Body/Cages
@onready var exhaust: CPUParticles2D = $Exhaust

var engine_tween: Tween


func _ready() -> void:
	engine_tween = create_tween().set_loops()
	engine_tween.tween_property(body, "position:y", -1.0, 0.09)
	engine_tween.tween_property(body, "position:y", 0.0, 0.09)
	var boss := get_node_or_null(boss_path)
	if boss != null:
		boss.defeated.connect(_on_boss_defeated, CONNECT_ONE_SHOT)


func _on_boss_defeated(_points: int) -> void:
	engine_tween.kill()
	body.position.y = 0.0
	exhaust.emitting = false
	for cage in cages.get_children():
		var tween := create_tween().set_parallel(true)
		tween.tween_property(cage, "scale", cage.scale * Vector2(1.3, 0.6), 0.15)
		tween.tween_property(cage, "modulate:a", 0.0, 0.35)
