extends CharacterBody2D



# --- CONSTANTES DE CENAS (Altere o caminho se necessário) ---

const ACCESS_CARD_SCENE = preload("res://cartao/AccessCard.tscn")



# --- VARIÁVEIS EXPORTADAS (Ajuste no Inspector) ---

@export var patrol_speed: float = 50.0	 	 

@export var chase_speed: float = 150.0	 	 

@export var chase_acceleration: float = 800.0	

@export var walk_to_run_speed: float = 100.0	

@export var initial_walk_time: float = 0.3	



@export var min_duration: float = 1.0	 	 	

@export var max_duration: float = 3.0	 	 	

@export var attack_distance: float = 30.0	

@export var attack_cooldown: float = 2.0	 

@export var attack_damage: float = 10.0	 	

@export var attack_windup_time: float = 0.3	



# --- PROPRIEDADES DE VIDA E DANO ---



@export var max_health: float = 50.0 # Exemplo: vida do inimigo

var current_health: float = max_health	



# --- ENUM DE ESTADOS ---



enum State { IDLE, MOVING, CHASING, ATTACKING, RECOVERING, OBSERVING, RETURNING }	



# --- VARIÁVEIS DE ESTADO E REFERÊNCIA ---



var current_state: State = State.IDLE

var patrol_direction: int = 1	 	 	 

var target: CharacterBody2D = null	 	 

var initial_position: Vector2 = Vector2.ZERO

signal jaula_pode_abrir # Sinal que já existia no seu código





# --- REFERÊNCIAS ONREADY (AGORA COM animated_sprite CORRETO) ---



@onready var state_timer: Timer = $Timer	 	 

@onready var attack_timer: Timer = $AttackTimer	 

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D # 🛑 CORRIGIDO

@onready var vision_area: Area2D = $visão	 	 	 

@onready var attack_hitbox: Area2D = $Hitbox	 	 

@onready var windup_timer: Timer = $WindupTimer	 

@onready var acceleration_timer: Timer = $AccelerationTimer	

@onready var exclamacao_sprite: Sprite2D = $Exclamacao	

@onready var exclamacao_timer: Timer = $ExclamacaoTimer	





func _ready():

	randomize()

	

	add_to_group("enemy")

	

	current_health = max_health

	

	initial_position = global_position

	

	attack_timer.wait_time = attack_cooldown

	

	windup_timer.wait_time = attack_windup_time

	windup_timer.one_shot = true

	windup_timer.timeout.connect(_on_windup_timer_timeout)

	

	acceleration_timer.wait_time = initial_walk_time

	acceleration_timer.one_shot = true

	

	exclamacao_sprite.visible = false

	exclamacao_timer.wait_time = 0.8	

	exclamacao_timer.one_shot = true

	exclamacao_timer.timeout.connect(_on_exclamacao_timer_timeout)

	

	vision_area.body_entered.connect(_on_visao_body_entered)

	vision_area.body_exited.connect(_on_visao_body_exited)

	state_timer.timeout.connect(_on_timer_timeout)

	attack_timer.timeout.connect(_on_attack_timer_timeout)

	

	animated_sprite.animation_finished.connect(_on_attack_animation_finished) 

	

	attack_hitbox.body_entered.connect(_on_hitbox_body_entered)

	

	attack_hitbox.monitorable = false	

	attack_hitbox.monitoring = false	

	

	set_state_patrol()



# --- FUNÇÕES PRINCIPAIS DO JOGO ---



func _physics_process(delta):

	var current_velocity = velocity

	var direction_to_target = Vector2.ZERO

	var distance_to_target = 0.0



	if is_instance_valid(target):

		direction_to_target = (target.global_position - global_position)

		distance_to_target = direction_to_target.length()



	match current_state:

		State.MOVING:

			current_velocity.x = 0 

			animated_sprite.play("idle")

			

		State.IDLE:

			current_velocity.x = 0

			animated_sprite.play("idle")

			

		State.OBSERVING:	

			current_velocity.x = 0

			animated_sprite.play("idle")

			

		State.CHASING:

			

			if is_instance_valid(target):

				

				if distance_to_target <= attack_distance:

					current_velocity.x = move_toward(current_velocity.x, 0, chase_acceleration * 3 * delta)

					animated_sprite.play("idle")	

					update_flip(direction_to_target.x)	

					set_state_attacking()	

					

					acceleration_timer.stop()	

						

				else:

					

					var direction_x = direction_to_target.normalized().x

					var target_speed_x = direction_x * chase_speed

					

					current_velocity.x = move_toward(current_velocity.x, target_speed_x, chase_acceleration * delta)

					

					if acceleration_timer.time_left > 0:

						animated_sprite.play("andar")

					else:

						animated_sprite.play("run")

						

					if abs(current_velocity.x) < 5.0:

						animated_sprite.play("idle")

					

					if abs(current_velocity.x) > 5.0:

						update_flip(current_velocity.x)	

					

			else:

				current_state = State.RETURNING

				acceleration_timer.stop()

		

		State.RECOVERING:	

			current_velocity.x = move_toward(current_velocity.x, 0, chase_acceleration * 5 * delta)	

			animated_sprite.play("idle")

		

		State.ATTACKING:

			current_velocity.x = move_toward(current_velocity.x, 0, chase_acceleration * 5 * delta)	

			

			if attack_timer.time_left == 0 and not animated_sprite.is_playing():

				attack_hitbox.monitorable = false	

				attack_hitbox.monitoring = false

				current_state = State.CHASING	

				

		State.RETURNING:

			var direction_to_start = (initial_position - global_position)

			

			if direction_to_start.length() < 5: 

				current_velocity.x = 0

				set_state_patrol()

				

			else:

				var direction_x = direction_to_start.normalized().x

				var target_speed_x = direction_x * patrol_speed 

				

				current_velocity.x = move_toward(current_velocity.x, target_speed_x, chase_acceleration * delta)

				

				update_movement_and_animation(current_velocity.x)

			

	velocity = current_velocity

	move_and_slide()





# --- FUNÇÕES DE CONTROLE DE ESTADO ---



func set_state_patrol():

	target = null

	velocity = Vector2.ZERO	

	

	state_timer.stop()

	acceleration_timer.stop()	

	

	current_state = State.IDLE

	print("Voltando para IDLE na posição inicial.")





func set_state_attacking():

	if current_state == State.ATTACKING or current_state == State.RECOVERING or attack_timer.time_left > 0:

		return

	

	if is_instance_valid(target) and global_position.distance_to(target.global_position) <= attack_distance:

		

		current_state = State.ATTACKING

		animated_sprite.play("ataque")	

		

		attack_hitbox.monitorable = true	

		

		windup_timer.start()

		attack_timer.start()	

		

		print("ATAQUE INICIADO (Delay Ativado)")





# --- FUNÇÕES DE TIMERS E EVENTOS DE ANIMAÇÃO ---



func _on_timer_timeout():

	pass





func _on_attack_timer_timeout():

	if current_state == State.RECOVERING:

		current_state = State.CHASING

		

		acceleration_timer.start()

		

		print("Fim da recuperação. Voltando a CHASE.")





func _on_windup_timer_timeout():

	if current_state == State.ATTACKING:

		attack_hitbox.monitoring = true

		print("Hitbox Ativada!")





func _on_attack_animation_finished():

	if current_state == State.ATTACKING:

		

		attack_hitbox.monitorable = false	

		attack_hitbox.monitoring = false	

		

		current_state = State.RECOVERING

		print("Fim da animação de ataque. Entrando em RECOVERING.")





func _on_exclamacao_timer_timeout():

	exclamacao_sprite.visible = false

	

	if current_state == State.OBSERVING:

		current_state = State.CHASING

		acceleration_timer.start()

		print("Fim da observação. Iniciando CHASE.")

		

# --------------------------------------------------------------------------

# --- FUNÇÃO DE DANO (APLICA O DANO) ---

# --------------------------------------------------------------------------



func _on_hitbox_body_entered(body: Node2D):

	if current_state != State.ATTACKING:

		return

		

	if body.is_in_group("player"):

		

		if body.has_method("take_damage"):

			body.take_damage(attack_damage)

		

		attack_hitbox.set_deferred("monitoring", false)	

		

		print("Dano ", attack_damage, " aplicado ao Player.")



# --------------------------------------------------------------------------

# --- FUNÇÃO DE DANO RECEBIDO E MORTE (CORRIGIDA) ---

# --------------------------------------------------------------------------



func take_damage(amount: float):

	# 🛑 IMPEDE DANO SE JÁ ESTÁ MORTO

	if current_health <= 0:

		return

		

	current_health -= amount

	print("Inimigo recebeu ", amount, " de dano. Vida restante: ", current_health)

	

	# 🛑 CHECA MORTE E CHAMA DIE IMEDIATAMENTE

	if current_health <= 0:

		current_health = 0.0

		die() 

		return # Sai da função imediatamente

	

	# Efeito visual de Dano (Sem await para evitar bloqueio)

	modulate = Color.RED	

	get_tree().create_timer(0.1).timeout.connect(func(): modulate = Color.WHITE)

	

# 🛑 FUNÇÃO DIE CORRIGIDA E COMPLETA (Para drop e animação)

func die():
	# 1. 🛑 ANIMAÇÃO DE MORTE
	if animated_sprite: 
		
		# Pausa o inimigo (movimento/física) enquanto a animação toca
		set_physics_process(false) 
		set_process(false)
		
		# 🛑 CORREÇÃO: Removemos a chamada 'has_animation' que não existe no Godot 4.
		animated_sprite.play("death")
		
		# Espera a animação de morte terminar.
		await animated_sprite.animation_finished
	
	# 2. Lógica de Drop (Só se o cartão ainda não foi pego)
	if Globals.has_access_card == false: 
		
		var card = ACCESS_CARD_SCENE.instantiate()
		
		# CALCULA POSIÇÃO DE SPAWN DISTANTE E CORRETA
		var flip_direction = -1 if animated_sprite.flip_h else 1
		var drop_offset_x = 50
		
		var drop_position = global_position + Vector2(drop_offset_x * flip_direction, 0)
		
		get_parent().add_child(card) 
		card.global_position = drop_position 

		# Inicia a função de queda (requer a função drop() no AccessCard.gd)
		card.drop(randf_range(100, 150) * flip_direction) 
		
		print("Inimigo morreu, dropou o Cartão de Acesso!")

	# 3. Emite o sinal para o mundo (Mantido do código original)
	emit_signal("jaula_pode_abrir") 

	# 4. Remove o inimigo da cena
	queue_free()



# --- FUNÇÕES DE DETECÇÃO (Visão) ---



func _on_visao_body_entered(body: Node2D):

	if body.is_in_group("player") and target == null and current_state != State.ATTACKING and current_state != State.RECOVERING:

		target = body as CharacterBody2D

		

		current_state = State.OBSERVING

		state_timer.stop()

		

		exclamacao_sprite.visible = true

		exclamacao_timer.start()

		

		print("Player detectado! Observando.")



func _on_visao_body_exited(body: Node2D):

	if body.is_in_group("player") and body == target:

		print("Player fugiu. Iniciando RETORNO.")

		

		target = null 

		

		current_state = State.RETURNING

		

		state_timer.stop()

		acceleration_timer.stop()





# --- FUNÇÕES AUXILIARES ---



func update_movement_and_animation(x_velocity: float):

	if x_velocity != 0:

		animated_sprite.play("andar")

		update_flip(x_velocity)

	else:

		animated_sprite.play("idle")



func update_flip(x_value: float):

	if x_value < 0:

		animated_sprite.flip_h = true

	elif x_value > 0:

		animated_sprite.flip_h = false
