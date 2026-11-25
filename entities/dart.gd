extends Area2D

@export var damage := 1
@export var lifetime := 2.5
@export var arc_gravity := 0.0
@export var spin_speed := 0.0

@onready var art: Node2D = $Art

var velocity := Vector2(-120.0, 0.0)


func _ready() -> void:
	art.rotation = velocity.angle()


func _physics_process(delta: float) -> void:
	velocity.y += arc_gravity * delta
	position += velocity * delta
	art.rotation += spin_speed * signf(velocity.x) * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"player") and body.has_method(&"take_damage"):
		body.take_damage(damage, global_position)
	queue_free()
