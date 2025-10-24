extends Area2D

# Referência ao nó Label. @onready garante que o nó está pronto antes de ser acessado.
@onready var texto: Label = $Label

# Variável de estado para rastrear se o player está dentro da área.
var dentro: bool = false 

func _ready() -> void:
	# Inicializa o Label como invisível.
	texto.visible = false

# Função que é executada a cada frame para checar inputs e lógica.
# Corrigido: O parâmetro 'delta' agora é '_delta' para silenciar o aviso.
func _process(_delta: float) -> void:
	# Checa o input do jogador somente se ele estiver dentro da área.
	checar_entrada_cena()

# Sinal disparado quando um 'body' (corpo, como CharacterBody2D) entra na Area2D.
# Lembre-se que este sinal deve estar conectado corretamente no editor do Godot.
func _on_body_entered(body: Node2D) -> void:
	
	# Verifica se o corpo que entrou é o player (verificando o grupo).
	if body.is_in_group("player"):
		texto.visible = true
		dentro = true

# Sinal disparado quando um 'body' (corpo) sai da Area2D.
# Lembre-se que este sinal deve estar conectado corretamente no editor do Godot.
func _on_body_exited(body: Node2D) -> void:
	
	# Verifica se o corpo que saiu é o player.
	if body.is_in_group("player"):
		texto.visible = false
		dentro = false

# Lógica principal para mudar de cena.
func checar_entrada_cena():
	# 1. Verifica se o player está dentro da área.
	if dentro:
		# 2. Verifica se a ação "entrar" foi pressionada AGORA (apenas uma vez).
		# Certifique-se de configurar a ação "entrar" nas Configurações do Projeto -> Mapa de Entrada.
		if Input.is_action_just_pressed("entrar"):
			# Mudar a cena para o arquivo especificado.
			# Certifique-se que o caminho do arquivo está correto!
			get_tree().change_scene_to_file("res://mundo4.tscn")
