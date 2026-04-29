extends Area2D

@onready var punto_salida = $"Punto de salida"
@onready var sonido_teleport = $SonidoTP

static var viajando = false 

func _ready():
	$AnimatedSprite2D.play("default")
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.name == "jugador" and not viajando:
		viajar(body)

func viajar(body):
	viajando = true 
	
	# --- SONIDO ---
	# Reproduce el sonido justo cuando empieza la acción
	sonido_teleport.play() 
	
	# 1. CONGELAR
	if body is RigidBody2D: body.freeze = true
	
	# 2. ABSORCIÓN (Tu animación original)
	var tween = create_tween().set_parallel(true)
	tween.tween_property(body, "scale", Vector2(0, 0), 0.6).set_trans(Tween.TRANS_BACK)
	tween.tween_property(body, "global_position", global_position, 0.6)
	
	await tween.finished
	
	# 3. TELETRANSPORTE
	body.global_position = punto_salida.global_position
	
	# 4. SALIDA (Tu animación original)
	var tween_out = create_tween()
	tween_out.tween_property(body, "scale", Vector2(1, 1), 0.7).set_trans(Tween.TRANS_ELASTIC)
	
	await tween_out.finished
	
	# 5. ACTIVAR JUGADOR
	if body is RigidBody2D: body.freeze = false
	
	# 6. PARCHE DE 4 SEGUNDOS
	await get_tree().create_timer(4.0).timeout
	viajando = false

func _on_body_exited(body):
	if body.name == "jugador":
		viajando = false
