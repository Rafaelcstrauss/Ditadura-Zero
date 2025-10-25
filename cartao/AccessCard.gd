extends CharacterBody2D

# ==============================================================================
# --- VARIÁVEIS DE EXPORTAÇÃO E FÍSICA ----------------------------------------
# ==============================================================================

# Gravidade padrão (pegue do seu projeto/mundo se for diferente)
const GRAVITY = 980 
const MAX_FALL_SPEED = 1500

# Velocidade inicial da queda (pode dar um pequeno "pulo" ao cair)
var drop_velocity_y = -100 

# Estado do cartão
var is_on_ground = false
var is_player_nearby = false


# ==============================================================================
# --- REFERÊNCIAS E READY ------------------------------------------------------
# ==============================================================================

@onready var interaction_area: Area2D = $Area2D
@onready var interaction_label: Label = $Area2D/Label # Se você tiver um Label para o texto

func _ready():
	# Conecta o sinal da área de interação
	interaction_area.body_entered.connect(_on_area_body_entered)
	interaction_area.body_exited.connect(_on_area_body_exited)
	
	# Esconde o texto de interação inicialmente
	if interaction_label:
		interaction_label.visible = false

# ==============================================================================
# --- PROCESSAMENTO FÍSICO (QUEDA) ---------------------------------------------
# ==============================================================================

func _physics_process(delta):
	var velocity = get_velocity()

	# 1. Lógica de queda (apenas se não estiver no chão)
	if not is_on_ground:
		# Aplica a gravidade
		velocity.y += GRAVITY * delta
		
		# Limita a velocidade de queda
		velocity.y = min(velocity.y, MAX_FALL_SPEED)
		
		# 2. Move o corpo e verifica colisão
		set_velocity(velocity)
		move_and_slide()
		
		# 3. Verifica se colidiu com o chão e para
		if is_on_floor():
			is_on_ground = true
			set_velocity(Vector2.ZERO)
			
			# Se colidiu, o timer/processamento pode ser desativado para otimização
			set_physics_process(false) 

# ==============================================================================
# --- INPUT E INTERAÇÃO (COLETA) -----------------------------------------------
# ==============================================================================

func _process(delta):
	# Verifica se o cartão está no chão E o Player está na área E o botão "entrar" foi pressionado
	if is_on_ground and is_player_nearby and Input.is_action_just_pressed("entrar"):
		collect_card()

func _on_area_body_entered(body: CharacterBody2D):
	if body.is_in_group("player"):
		is_player_nearby = true
		if is_on_ground and interaction_label:
			interaction_label.visible = true

func _on_area_body_exited(body: CharacterBody2D):
	if body.is_in_group("player"):
		is_player_nearby = false
		if interaction_label:
			interaction_label.visible = false

func collect_card():
	# 🛑 1. Define a variável global (requer que 'Globals' seja um AutoLoad)
	Globals.has_access_card = true 
	
	print("Cartão de Acesso coletado com sucesso!")
	
	# 2. Remove o nó da cena
	queue_free()

# ==============================================================================
# --- FUNÇÕES PÚBLICAS (PARA O INIMIGO USAR) -----------------------------------
# ==============================================================================

# Esta função é chamada pelo script do inimigo ao instanciar o cartão
func drop(initial_horizontal_speed: float):
	# Inicia a queda e dá um pequeno empurrão lateral
	var velocity = Vector2(initial_horizontal_speed, drop_velocity_y)
	set_velocity(velocity)
	
	# Garante que o processamento físico comece
	set_physics_process(true)
