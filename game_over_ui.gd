# Nome do Script: GameOverUI.gd (Anexar ao nó raiz CanvasLayer)
extends CanvasLayer

@onready var retry_button := $Node/MainButtons/RetryButton 

func _ready():
	# Conecta o botão diretamente a uma função dentro deste script
	if is_instance_valid(retry_button):
		retry_button.pressed.connect(_on_retry_pressed)
		print("DEBUG UI: Botão conectado dentro do próprio GameOverUI.")
	else:
		print("ERRO UI: Botão 'RetryButton' não encontrado no caminho interno.")

func _on_retry_pressed():

	# 1. Despausa o jogo

	get_tree().paused = false

	

	# 🛑 CORREÇÃO AQUI: Use .scene_file_path em vez de .filename

	# Esta propriedade armazena o caminho do arquivo original da cena instanciada.

	var current_scene_path = get_tree().current_scene.scene_file_path

	

	# 2. Libera ESTE nó de UI primeiro

	# Isto deve ser feito antes da troca de cena, pois 'change_scene_to_file' 

	# já pode começar a desalocar recursos.

	queue_free() 

	

	# 3. Troca a cena 

	if current_scene_path:

		# Troca a cena para o caminho salvo

		get_tree().change_scene_to_file(current_scene_path)

	else:

		# Se por algum motivo o caminho não foi salvo (ex: é a Main Scene), recarrega

		get_tree().reload_current_scene()
