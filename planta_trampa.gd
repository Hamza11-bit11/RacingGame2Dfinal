extends Area2D

@onready var sprite = $AnimatedSprite2D
@onready var colision_boca = $BocaColision

func _ready():
	sprite.play("Stand")
	# La boca empieza desactivada para que no te mate antes de tiempo
	colision_boca.set_deferred("disabled", true)

# 1. El detector largo (Rectángulo azul) activa la animación
func _on_area_deteccion_body_entered(body):
	# Si lo que entra es un RigidBody2D (como tu coche), activamos
	if body is RigidBody2D:
		if sprite.animation != "chomp":
			print("¡PLANTA: Detectado cuerpo físico, muerde!")
			sprite.play("chomp")
	else:
		print("¡PLANTA: Algo entró pero no es el coche (es un: ", body.name, ")")

# 2. Control de los frames: la boca solo muerde cuando está abierta
func _on_animated_sprite_2d_animation_finished():
	if sprite.animation == "chomp":
		# Opción A: Vuelve a esperar (boca abierta)
		sprite.play("Stand") 
		
		# Opción B: Si quieres que se quede un rato quieta antes de volver:
		# await get_tree().create_timer(2.0).timeout
		# sprite.play("Stand")

# 3. Cuando el coche toca la BocaColision
# En el script de la planta (planta_trampa.gd)
func _on_boca_colision_body_entered(body):
	if body.has_method("ser_devorado"):
		# El coche desaparece y la cámara se clava
		body.ser_devorado() 
		
		# Hacemos que la planta trague
		sprite.play("Tragar")
		
		# ESPERAMOS a que la animación termine (solo funciona si Loop está apagado)
		await sprite.animation_finished
		
		# Un pequeño respiro de 0.3 segundos para que no sea tan brusco
		await get_tree().create_timer(0.3).timeout
		
		# ¡RESPAWN!
		get_tree().reload_current_scene()
