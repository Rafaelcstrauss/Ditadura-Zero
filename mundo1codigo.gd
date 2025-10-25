extends Node2D

# ==============================================================================
# --- REFERÊNCIA DA CENA DE DIÁLOGO --------------------------------------------
# ==============================================================================

# Altere este caminho se a sua cena DialogueBox.tscn estiver em outro lugar
const DIALOGUE_BOX_SCENE = preload("res://scenes/dialogue_layer.tscn") 


# ==============================================================================
# --- INICIALIZAÇÃO DO MUNDO ---------------------------------------------------
# ==============================================================================

func _ready() -> void:
	# 🛑 1. Inicia a cutscene imediatamente ao carregar o mundo
	start_intro_cutscene()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# O jogo estará pausado aqui enquanto a cutscene roda
	pass


# ==============================================================================
# --- FUNÇÕES DE CONTROLE DA CUTSCENE ------------------------------------------
# ==============================================================================

func start_intro_cutscene():
	# 1. Cria uma nova instância da caixa de diálogo
	var dialogue_box = DIALOGUE_BOX_SCENE.instantiate()
	
	# 2. Define qual JSON ele deve ler.
	# Certifique-se de que este caminho está correto para seu arquivo JSON.
	dialogue_box.dialogue_file_path = "res://scenes/cutscene.json"
	
	# 3. Adiciona a cutscene à árvore da cena
	add_child(dialogue_box) 
	
	# 4. Conecta o sinal para saber quando o diálogo terminou
	dialogue_box.dialogue_finished.connect(_on_intro_cutscene_finished)
	
	# 5. Inicia a cutscene (o script DialogueBox.gd fará o resto: pausa, tela preta, etc.)
	dialogue_box.start_dialogue()

func _on_intro_cutscene_finished():
	# Esta função é chamada quando o jogador clica no último texto da cutscene.
	print("Introdução finalizada. Liberando Player e iniciando o jogo!")
	
	# 🛑 Ações de início de jogo (Exemplos)
	# - Liberar o input do jogador
	# - Ativar a HUD
	# - Fazer o Player aparecer/spawnar
	# Ex: $Player.can_move = true
