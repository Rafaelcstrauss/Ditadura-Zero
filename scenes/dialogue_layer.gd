extends CanvasLayer

# ==============================================================================
# --- CONFIGURAÇÕES E SINAIS ---------------------------------------------------
# ==============================================================================

# Disparado quando todo o diálogo termina
signal dialogue_finished

@export_file("*.json") var dialogue_file_path: String = "res://dialogues/cutscene_intro.json"
@export var default_typing_speed: float = 0.05 # Velocidade ideal para pixel art (0.05s por letra)

# ==============================================================================
# --- REFERÊNCIAS DE NÓS (ONREADY) ---------------------------------------------
# ==============================================================================

@onready var background: ColorRect = $Background
@onready var speaker_name_label: Label = $Container/SpeakerName
@onready var dialogue_text_label: Label = $Container/DialogueText
@onready var text_timer: Timer = $Container/TextTimer # Referência ao nó Timer

# ==============================================================================
# --- VARIÁVEIS INTERNAS -------------------------------------------------------
# ==============================================================================

var dialogue_data: Dictionary = {}
var current_line_index: int = 0
var current_text: String = ""
var text_chars_displayed: int = 0
var is_typing: bool = false

# ==============================================================================
# --- READY & INICIALIZAÇÃO ----------------------------------------------------
# ==============================================================================

func _ready():
	# Esconde a caixa de diálogo no início
	visible = false
	
	# Conexões: Checa se o nó Timer existe antes de conectar
	if text_timer:
		text_timer.timeout.connect(_on_text_timer_timeout)
	else:
		push_error("ERRO FATAL: Nó 'TextTimer' não encontrado na cena DialogueBox!")

# Carrega o arquivo JSON no formato simples (lista de strings)
func load_dialogue_data(path: String) -> bool:
	var file = FileAccess.open(path, FileAccess.READ)
	if FileAccess.get_open_error() != OK:
		push_error("ERRO: Não foi possível abrir o arquivo de diálogo: " + path)
		return false

	var content = file.get_as_text()
	var json_result = JSON.parse_string(content)

	if json_result is Dictionary and json_result.has("falas"):
		dialogue_data = json_result
		return true
	else:
		push_error("ERRO: JSON inválido ou faltando a chave 'falas': " + path)
		return false

# Inicia a cutscene
func start_dialogue():
	if not load_dialogue_data(dialogue_file_path):
		return # Aborta se o carregamento falhar

	# 1. Pausa o jogo (todo o input e lógica de física do mundo)
	get_tree().paused = true
	
	# 2. Mostra a cutscene (tela preta)
	visible = true
	current_line_index = 0
	
	# 3. Inicia a primeira linha
	_show_next_line()

# ==============================================================================
# --- PROCESSAMENTO DO INPUT ---------------------------------------------------
# ==============================================================================

func _process(_delta):
	# Captura a entrada mesmo com o jogo pausado (requer Input Map configurado)
	if get_tree().paused and Input.is_action_just_pressed("ui_accept"):
		if is_typing:
			_skip_typing()
		else:
			_advance_dialogue()

func _advance_dialogue():
	current_line_index += 1
	if current_line_index < dialogue_data.falas.size():
		_show_next_line()
	else:
		_end_dialogue()

# ==============================================================================
# --- ANIMAÇÃO DE TEXTO --------------------------------------------------------
# ==============================================================================

func _show_next_line():
	# Assume que 'falas' é uma lista de strings
	var line = dialogue_data.falas[current_line_index] 
	
	current_text = line 
	text_chars_displayed = 0
	is_typing = true
	dialogue_text_label.text = ""

	# Orador Padrão (usa o valor de 'speaker_default' do JSON)
	var speaker = dialogue_data.get("speaker_default", "Narrador")
	speaker_name_label.text = speaker
	
	text_timer.wait_time = default_typing_speed
	text_timer.start()

func _on_text_timer_timeout():
	text_chars_displayed += 1
	dialogue_text_label.text = current_text.left(text_chars_displayed)
	
	if text_chars_displayed >= current_text.length():
		# Digitação finalizada
		is_typing = false
		text_timer.stop()

func _skip_typing():
	# Exibe o texto completo imediatamente
	dialogue_text_label.text = current_text
	text_chars_displayed = current_text.length()
	is_typing = false
	text_timer.stop()

# ==============================================================================
# --- FIM DO DIÁLOGO -----------------------------------------------------------
# ==============================================================================

func _end_dialogue():
	visible = false
	get_tree().paused = false # Despausa o jogo!
	emit_signal("dialogue_finished")
	queue_free() # Remove a caixa de diálogo da memória
