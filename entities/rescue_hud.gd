extends CanvasLayer

@onready var count_label: Label = $Margin/Panel/Margin/Count


func _ready() -> void:
	RescueManager.rescue_count_changed.connect(_on_rescue_count_changed)
	_on_rescue_count_changed(RescueManager.get_rescue_count(), RescueManager.TOTAL_ANIMALS)


func _on_rescue_count_changed(current: int, total: int) -> void:
	count_label.text = "RESGATES  %d/%d" % [current, total]
