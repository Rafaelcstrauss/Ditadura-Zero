extends Area2D

# Altere este caminho para a sua cena de Diálogo/Caixa de Texto (DialogueBox.tscn)
const DIALOGUE_SCENE = preload("res://scenes/dialogue_layer.tscn")
const BETA_END_JSON = "res://scenes/end_beta_message.json"

var is_ending: bool = false
# 🛑 CORRIGIDO: O nó principal de 'dialogue_layer.tscn' é um CanvasLayer
var active_dialogue_box: CanvasLayer = null 

# 🛑 CERTIFIQUE-SE QUE ESTA LINHA EXISTE NO TOPO:
@onready var sound_player: AudioStreamPlayer = $Sound 


# 🛑 FUNÇÃO CENTRALIZADA (AGORA PODE USAR AWAIT)
func _on_body_entered(body: Node2D):
	
	if body.is_in_group("player") and not is_ending:
		
		if Globals.has_access_card:
			
			is_ending = true
			print("Player acessou a área final com o cartão! Iniciando Sequência.")
			
			# Desliga o Player
			if body.has_method("stop_movement"):
				body.stop_movement()
			
			# 🛑 1. TOCA O SOM E ESPERA ELE TERMINAR
			if sound_player:
				sound_player.play()
				# O await pausa a execução da função até que o sinal 'finished' seja emitido.
				await sound_player.finished 
			else:
				print("AVISO: Nó de som não encontrado. Prosseguindo sem som.")
			
			# 2. Pausa o jogo (só depois do som terminar)
			get_tree().paused = true
			
			# 3. INSTANCIAÇÃO
			active_dialogue_box = DIALOGUE_SCENE.instantiate()
			get_tree().root.add_child(active_dialogue_box)
			
			# 4. Configura e inicia o diálogo
			if active_dialogue_box.has_method("start_dialogue_from_file"):
				active_dialogue_box.start_dialogue_from_file(BETA_END_JSON)
			elif active_dialogue_box.has_method("start_dialogue"):
				active_dialogue_box.dialogue_file_path = BETA_END_JSON
				active_dialogue_box.start_dialogue()
			
			# 5. Conecta o sinal para fechar o jogo
			active_dialogue_box.dialogue_finished.connect(_on_cutscene_finished)
			
			# 6. Remove o gatilho
			queue_free()
		
		else:
			print("Player tentou acessar a área final, mas precisa do Cartão de Acesso.")


func _on_cutscene_finished():
	print("Cutscene final concluída. Preparando para fechar o Jogo...")
	
	# PASSO CRÍTICO 1: REMOVE A CAIXA DE DIÁLOGO DA CENA
	if active_dialogue_box and is_instance_valid(active_dialogue_box):
		active_dialogue_box.queue_free()
		
	# 2. Despausa o jogo
	get_tree().paused = false
	
	# 3. 🛑 CHAMA A FUNÇÃO DE SAÍDA SEGURA DE FORMA ADIADA
	# Isso garante que a despausa seja processada antes do comando de saída.
	call_deferred("safe_quit")


func safe_quit():
	await get_tree().process_frame
	
	print("Executando fechamento forçado...")
	
	# AÇÃO FINAL: FECHAR O JOGO DE FORMA ADIADA
	get_tree().quit()
