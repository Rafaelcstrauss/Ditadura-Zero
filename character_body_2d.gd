extends CharacterBody2D

# --- PROPRIEDADES DE MOVIMENTO ---
const SPEED = 100.0
const RUN_SPEED = 250.0
const ACCELERATION = 1300.0
const DECELERATION_INSTANT = 8000.0
const JUMP_VELOCITY = -350.0
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# --- PROPRIEDADES DE VIDA E DANO ---
@export var max_health: float = 100.0
var current_health: float = max_health
var is_invulnerable: bool = false
const INVULNERABILITY_TIME = 0.5
@export var game_over_ui_scene: PackedScene = preload("res://game_over_ui.tscn") 
# --- PROPRIEDADES DE ATAQUE DO PLAYER ---
@export var attack_damage: float = 5.0
@export var attack_windup_time: float = 0.2 
@export var attack_cooldown: float = 0.2 
@export var hitbox_duration: float = 0.1 

# --- ESTADOS ---
enum PlayerState { NORMAL, ATTACKING_PLAYER }
var current_player_state: PlayerState = PlayerState.NORMAL

# --- VARIÁVEL DO COMBO ---
# 0 = NENHUM, 1 = attack, 2 = attack2, 3 = attack3
var current_combo_step: int = 0
var last_attack_time: float = 0.0 
const COMBO_WINDOW_TIME = 0.3 

# Referências
@onready var animated_sprite = $AnimatedSprite2D
@onready var invulnerability_timer = $InvulnerabilityTimer
@onready var footstep_sound = $FootstepSound         # NOVO: Referência ao som de passos
@onready var anim_player = $AnimPlayer             # NOVO: Referência ao AnimationPlayer
# Hitboxes
@onready var hitbox_direita = $Hitbox_Direita 
@onready var hitbox_esquerda = $Hitbox_Esquerda 

# Timers
@onready var attack_cooldown_timer = $AttackCooldownTimer
@onready var attack_windup_timer = $AttackWindupTimer
@onready var hitbox_duration_timer = $HitboxDurationTimer

# --- FUNÇÕES ---

func _ready():
	add_to_group("player")
	
	# Configuração dos Timers (restante do código _ready...)
	invulnerability_timer.wait_time = INVULNERABILITY_TIME
	invulnerability_timer.one_shot = true
	invulnerability_timer.timeout.connect(_on_invulnerability_timer_timeout)
	
	attack_cooldown_timer.wait_time = attack_cooldown
	attack_cooldown_timer.one_shot = true
	attack_cooldown_timer.timeout.connect(_on_attack_cooldown_timer_timeout)
	
	attack_windup_timer.wait_time = attack_windup_time
	attack_windup_timer.one_shot = true
	attack_windup_timer.timeout.connect(_on_attack_windup_timer_timeout)
	
	hitbox_duration_timer.wait_time = hitbox_duration
	hitbox_duration_timer.one_shot = true
	hitbox_duration_timer.timeout.connect(_on_hitbox_duration_timer_timeout)
	
	# Conexão dos Sinais de AMBAS as Hitboxes
	hitbox_direita.body_entered.connect(_on_player_hitbox_body_entered)
	hitbox_esquerda.body_entered.connect(_on_player_hitbox_body_entered)
	
	# Conecta o sinal para detectar o fim da animação de ataque
	animated_sprite.animation_finished.connect(_on_animated_sprite_2d_animation_finished)
	
	# Desativa AMBAS as hitboxes no início
	hitbox_direita.monitoring = false
	hitbox_direita.monitorable = false
	hitbox_esquerda.monitoring = false
	hitbox_esquerda.monitorable = false


func _physics_process(delta):
	# 1. Aplicar Gravidade
	var velocity = self.velocity
	
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# 2. Processar Pulo
	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# 3. Lógica de Combo/Ataque
	if Input.is_action_just_pressed("ui_down"):
		try_attack()

	# 4. Checar se a janela de combo expirou (reseta o combo para o início)
	var current_time = Time.get_ticks_msec() / 1000.0 
	if current_combo_step > 0 and current_time > (last_attack_time + COMBO_WINDOW_TIME):
		reset_combo()
			
	# --- BLOQUEIO DE MOVIMENTO DURANTE O ATAQUE ---
	if current_player_state == PlayerState.ATTACKING_PLAYER:
		velocity.x = 0.0 
		self.velocity = velocity
		move_and_slide()
	# ----------------------------------------------
	
	# 5. Processar Movimento Horizontal (Somente se não estiver em estado de ataque)
	if current_player_state != PlayerState.ATTACKING_PLAYER:
		
		var direction = Input.get_axis("ui_left", "ui_right")
		
		var target_speed = 0.0
		var acceleration_rate = DECELERATION_INSTANT
		
		if direction:
			if Input.is_action_pressed("shift") and is_on_floor():
				target_speed = RUN_SPEED
			else:
				target_speed = SPEED

			acceleration_rate = ACCELERATION
			
			# Define o FLIP do sprite
			animated_sprite.flip_h = direction < 0
			
			var desired_velocity_x = direction * target_speed
			
			velocity.x = move_toward(velocity.x, desired_velocity_x, acceleration_rate * delta)
			
		else:
			if is_on_floor():
				velocity.x = 0.0
			
		# 6. Atualizar o estado da velocity do CharacterBody2D
		self.velocity = velocity
		
		# 7. Mover o personagem
		move_and_slide()
		
		# 8. Atualizar Animação E SOM DE PASSOS
		update_animation(direction)
	else:
		# Se estiver atacando, apenas garante que o som de passos pare
		if anim_player.is_playing():
			anim_player.stop()
		update_animation(0) # Passa 0 para garantir que ele não entre em walk/run


# --------------------------------------------------------------------------
# --- FUNÇÕES DE SOM DE PASSOS ---
# --------------------------------------------------------------------------

# Esta função é chamada PELO AnimationPlayer no momento exato do passo.
func play_footstep_sound():
	if is_on_floor(): # Garante que o som só toca se estiver no chão
		# Opcional: Adiciona variação de pitch para passos mais realistas
		footstep_sound.pitch_scale = randf_range(0.9, 1.1)
		footstep_sound.play()

# --------------------------------------------------------------------------
# --- FUNÇÕES DE COMBO ---
# --------------------------------------------------------------------------

func try_attack():
	if not is_on_floor():
		return
		
	var current_time = Time.get_ticks_msec() / 1000.0 
		
	# 1. Se estiver NORMAL e sem cooldown, inicia o combo
	if current_player_state == PlayerState.NORMAL and attack_cooldown_timer.is_stopped():
		start_combo(current_time)
	
	# 2. Se estiver atacando, tenta continuar o combo (se estiver na janela de tempo)
	elif current_player_state == PlayerState.ATTACKING_PLAYER:
		if last_attack_time != 0.0 and current_time < (last_attack_time + COMBO_WINDOW_TIME):
			continue_combo(current_time)
		else:
			reset_combo()
			try_attack()


func start_combo(time_ms):
	current_player_state = PlayerState.ATTACKING_PLAYER
	current_combo_step = 1
	last_attack_time = time_ms 
	
	play_attack_step(current_combo_step)
	
	attack_cooldown_timer.start() 
	print("Player: Combo iniciado (Ataque 1).")

func continue_combo(time_ms):
	current_combo_step += 1
	
	if current_combo_step > 3:
		current_combo_step = 1

	last_attack_time = time_ms 
	
	play_attack_step(current_combo_step)
	
	print("Player: Combo continuado (Ataque ", current_combo_step, ").")

func play_attack_step(step: int):
	var attack_name = "attack"
	if step == 2:
		attack_name = "attack2"
	elif step == 3:
		attack_name = "attack3"
		
	animated_sprite.play(attack_name)
	
	velocity.x = 0
	
	setup_hitbox_for_attack()
	attack_windup_timer.start()

func reset_combo():
	current_combo_step = 0
	last_attack_time = 0.0
	current_player_state = PlayerState.NORMAL
	print("Player: Combo resetado.")

func setup_hitbox_for_attack():
	if animated_sprite.flip_h:
		hitbox_esquerda.monitorable = true
		hitbox_direita.monitorable = false
	else:
		hitbox_esquerda.monitorable = false
		hitbox_direita.monitorable = true
	
# --------------------------------------------------------------------------
# --- FUNÇÕES DE TIMERS E SINAIS ---
# --------------------------------------------------------------------------
# ... (Funções de Timer e Hitbox permanecem iguais, pois não mudam a lógica central)
# ... (Funções de Dano e Vida também permanecem iguais)
# ... (Aqui ficaria o código das suas funções de timer, como _on_attack_windup_timer_timeout, etc.)

func _on_attack_windup_timer_timeout():
	if hitbox_esquerda.monitorable:
		hitbox_esquerda.monitoring = true
	elif hitbox_direita.monitorable:
		hitbox_direita.monitoring = true
	
	hitbox_duration_timer.start()

func _on_hitbox_duration_timer_timeout():
	hitbox_direita.monitoring = false
	hitbox_esquerda.monitoring = false


func _on_attack_cooldown_timer_timeout():
	if not animated_sprite.animation.begins_with("attack"):
		reset_combo()
	
func _on_animated_sprite_2d_animation_finished():
	if animated_sprite.animation.begins_with("attack"):
		if current_combo_step == 3 and attack_cooldown_timer.is_stopped():
			reset_combo()
		elif current_combo_step > 0:
			pass 
		else:
			current_player_state = PlayerState.NORMAL

func _on_player_hitbox_body_entered(body: Node2D):
	if body.is_in_group("enemy"):
		body.take_damage(attack_damage)
		hitbox_direita.set_deferred("monitoring", false) 
		hitbox_esquerda.set_deferred("monitoring", false)
		print("Player: Dano ", attack_damage, " aplicado a ", body.name)

func take_damage(amount: float):
	if is_invulnerable:
		return

	current_health -= amount
	print("Player recebeu ", amount, " de dano. Vida restante: ", current_health)
	
	is_invulnerable = true
	invulnerability_timer.start() 
	
	modulate = Color.DARK_RED 
	
	if current_health <= 0:
		die()
	else:
		pass

func die():
	print("Player derrotado! Game Over.")
	
	# 1. Pausa o jogo
	get_tree().paused = true
	
	# 2. Desativa o personagem para que ele não responda a input ou física
	set_process_mode(Node.PROCESS_MODE_DISABLED)
	
	# 3. Emite um sinal visual (opcional, como trocar a modulação ou animação)
	modulate = Color.GRAY
	# Se você tiver uma animação de morte, use:
	# animated_sprite.play("death") 
	
	# 4. Instancia e adiciona a tela de Game Over
	if game_over_ui_scene:
		var game_over_ui = game_over_ui_scene.instantiate()
		get_tree().root.add_child(game_over_ui)
	else:
		# Se a cena não foi carregada corretamente, apenas reinicia para evitar travamento
		get_tree().reload_current_scene()
	
	# 5. O nó do jogador será liberado após o retry ser clicado (na UI) 
	#    ou o jogador pode simplesmente ser invisível.
	#    É MELHOR DEIXAR O JOGADOR SER REMOVIDO PELA UI, MAS AQUI O REMOVEMOS IMEDIATAMENTE.
	queue_free()

func _on_invulnerability_timer_timeout():
	is_invulnerable = false
	modulate = Color.WHITE

# --------------------------------------------------------------------------
# --- FUNÇÕES DE ANIMAÇÃO COM CHAMADA DE SOM ---
# --------------------------------------------------------------------------

func update_animation(direction):
	if current_player_state == PlayerState.ATTACKING_PLAYER:
		# Garante que o som de passos não toca durante o ataque
		if anim_player.is_playing():
			anim_player.stop()
		return
		
	# Animações de Pulo e Queda
	if not is_on_floor():
		if velocity.y < 0:
			animated_sprite.play("jump")
		else:
			animated_sprite.play("fall")
		
		# PARE o som de passo quando estiver no ar
		if anim_player.is_playing() and anim_player.get_current_animation() == "walk_step":
			anim_player.stop()
		return

	# Animações de Movimento no Chão (Idle, Andar, Correr)
	if abs(velocity.x) > 1.0:
		
		# **********************************************
		# LÓGICA DE SOM DE PASSOS (USANDO ANIMATIONPLAYER)
		# **********************************************
		if not anim_player.is_playing() or anim_player.get_current_animation() != "walk_step":
			# Toca a animação que contém a chamada de método para o som
			anim_player.play("walk_step", -1.0, 1.0, true) # Toca em loop (true)
		
		
		if Input.is_action_pressed("shift") and abs(velocity.x) > SPEED:
			animated_sprite.play("run")
			# Acelera a taxa de repetição do som para corrida
			anim_player.speed_scale = RUN_SPEED / SPEED 
		else:
			animated_sprite.play("walk")
			# Volta à velocidade de repetição normal
			anim_player.speed_scale = 1.0 
			
	else:
		# Parado
		animated_sprite.play("idle")
		
		# PARE o som de passo quando estiver parado
		if anim_player.is_playing() and anim_player.get_current_animation() == "walk_step":
			anim_player.stop()
