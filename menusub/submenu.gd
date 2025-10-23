extends Node2D

@onready var pause_menu = $CanvasLayer/pauseMenu
@onready var submenu = $CanvasLayer/pauseMenu/submenu
@onready var options = $CanvasLayer/pauseMenu/Options

var game_paused: bool = false


func _ready():
	pause_menu.visible = false
	submenu.visible = false
	options.visible = false

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		handle_escape()

func handle_escape():
	if options.visible:
		options.visible = false
		submenu.visible = true
	elif submenu.visible:
		resume()
	elif pause_menu.visible:
		resume()
	else:
		toggle_pause()

func resume():
	game_paused = false
	pause_menu.visible = false
	submenu.visible = false
	options.visible = false
	get_tree().paused = false

func settings():
	submenu.visible = false
	options.visible = true

func sair():
	get_tree().paused = false
	get_tree().quit()

func toggle_pause():
	game_paused = not game_paused
	pause_menu.visible = game_paused
	submenu.visible = game_paused 
	get_tree().paused = game_paused
	pause_menu.process_mode = Node.PROCESS_MODE_ALWAYS
