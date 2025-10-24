extends Node2D

# Referência ao nó Label. É CRUCIAL que o nome do nó na cena seja EXATAMENTE "Label".
# 🛑 CORRIGIDO o problema de 'null instance' com a checagem de validade.
@onready var texto: Label = $Label

# Variável de estado para rastrear se o player está dentro da área.
var dentro: bool = false 

#==================== READY ====================

func _ready() -> void:
	# 🛑 CORREÇÃO FINAL: Garante que só acessa a propriedade se o nó existir.
	if is_instance_valid(texto):
		texto.visible = false
	else:
		print("ERRO CRÍTICO: Nó Label ('texto') não encontrado! Verifique o nome/caminho.")
	
	# Garante que o nó PARE de processar quando o jogo for pausado.
	set_process_mode(Node.PROCESS_MODE_INHERIT) 


#==================== PROCESSAMENTO ====================

func _process(delta: float) -> void:
	# Este _process só rodará se o jogo NÃO estiver pausado.
	checar_entrada_cena()


#==================== SINAIS DE COLISÃO ====================

# Sinal disparado quando um 'body' entra na Area2D.
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if is_instance_valid(texto):
			texto.visible = true
		dentro = true

# Sinal disparado quando um 'body' sai da Area2D.
func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		if is_instance_valid(texto):
			texto.visible = false
		dentro = false


#==================== LÓGICA DE TRANSIÇÃO ====================

func checar_entrada_cena():
	if dentro:
		# Verifica se a ação "entrar" foi pressionada AGORA.
		if Input.is_action_just_pressed("entrar"):
			# Mudar a cena para o arquivo especificado.
			get_tree().change_scene_to_file("res://mundo3.tscn")
			set_process(false)
