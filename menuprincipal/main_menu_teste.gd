extends Control

@onready var main_buttons: VBoxContainer = $MainButtons
@onready var options: Panel = $Options
@onready var titulo: VBoxContainer = $Panel/Titulo

var titulo_ativo: bool = true  

func _ready() -> void:
	titulo.visible = true
	main_buttons.visible = false
	options.visible = false



func _unhandled_input(event: InputEvent) -> void:
	if not titulo_ativo:
		return


	if event is InputEventKey and event.pressed:
		input_config_titulo()
		return


	if event is InputEventMouseButton and event.pressed:
		input_config_titulo()
		return


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://word_1.tscn")

func _on_settings_back_pressed() -> void:
	main_buttons.visible = true
	options.visible = false

func _on_settings_pressed() -> void:
	print("Configurações")
	main_buttons.visible = false
	options.visible = true

func _on_exit_pressed() -> void:
	get_tree().quit()


func _on_titulo_input(event: InputEvent) -> void:
	if titulo_ativo and event.is_pressed():
		input_config_titulo()

func input_config_titulo() -> void:
	titulo.visible = false
	main_buttons.visible = true
	options.visible = false
	titulo_ativo = false 
