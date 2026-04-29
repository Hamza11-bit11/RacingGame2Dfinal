extends RigidBody2D
#
## Called when the node enters the scene tree for the first time.
#@export var SPEED = 1000
#
#func _physics_process(delta):
	#if Input.is_action_pressed("ui_right"):
		## Usamos "../" para salir de la rueda actual y buscar en el padre (jugador)
		#get_node("../RuedasAdelante").angular_velocity = SPEED
		#get_node("../RuedasAtras").angular_velocity = SPEED
		#
	#elif Input.is_action_pressed("ui_left"):
		#get_node("../RuedasAdelante").angular_velocity = -SPEED
		#get_node("../RuedasAtras").angular_velocity = -SPEED
