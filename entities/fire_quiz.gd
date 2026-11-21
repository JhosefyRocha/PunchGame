extends CanvasLayer

signal finished(correct: bool)

const QUESTIONS := [
	{
		"question": "Um pequeno foco de incêndio começou na mata. Como apagá-lo?",
		"options": ["Abafar com terra", "Soprar com força", "Jogar óleo"],
		"correct": 0,
		"explanation": "A terra abafa o fogo e tira o oxigênio dele. Soprar espalha brasas e óleo alimenta as chamas.",
	},
	{
		"question": "Você vê fumaça no meio da floresta. O que fazer?",
		"options": ["Avisar os bombeiros ou a fiscalização", "Acender uma fogueira para ver melhor", "Ignorar, alguém deve ter avisado"],
		"correct": 0,
		"explanation": "Quanto mais rápido o incêndio é comunicado, menor é a área queimada e menor o dano para os animais.",
	},
	{
		"question": "Por que os incêndios florestais são tão graves para os animais?",
		"options": ["Destroem abrigos e fontes de alimento", "Deixam a floresta mais bonita", "Não causam nenhum efeito"],
		"correct": 0,
		"explanation": "Além de ferir e matar, o fogo destrói abrigos, comida e os locais de reprodução de muitas espécies.",
	},
]

var question: Dictionary
var option_buttons: Array[Button] = []
var question_label: Label
var explanation_label: Label
var continue_button: Button
var answered_correct := false


func _init() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	question = QUESTIONS[randi() % QUESTIONS.size()]

	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(260, 0)
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)

	question_label = Label.new()
	question_label.text = "FOCO DE INCÊNDIO: " + question["question"]
	question_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	question_label.add_theme_font_size_override("font_size", 10)
	box.add_child(question_label)

	for index in question["options"].size():
		var button := Button.new()
		button.text = question["options"][index]
		button.pressed.connect(_on_option_pressed.bind(index))
		box.add_child(button)
		option_buttons.append(button)

	explanation_label = Label.new()
	explanation_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	explanation_label.add_theme_font_size_override("font_size", 9)
	explanation_label.visible = false
	box.add_child(explanation_label)

	continue_button = Button.new()
	continue_button.text = "CONTINUAR"
	continue_button.visible = false
	continue_button.pressed.connect(_on_continue_pressed)
	box.add_child(continue_button)

	option_buttons[0].grab_focus()


func _on_option_pressed(index: int) -> void:
	answered_correct = index == question["correct"]
	if answered_correct:
		SaveManager.unlock(&"quiz_acertado")
	for button in option_buttons:
		button.disabled = true
	var prefix := "Acertou! " if answered_correct else "Não foi dessa vez. "
	explanation_label.text = prefix + question["explanation"]
	explanation_label.visible = true
	continue_button.visible = true
	continue_button.grab_focus()


func _on_continue_pressed() -> void:
	finished.emit(answered_correct)
	queue_free()
