extends Camera2D

@export var zoom_normal: Vector2 = Vector2(0.6, 0.6)
@export var zoom_acelerar: Vector2 = Vector2(0.4, 0.4)
@export var velocidad_zoom: float = 5.0

# ESTO ES LO QUE TIENES QUE AÑADIR:
func _ready():
	# Al empezar, ponemos el zoom directamente en el valor normal
	# sin animaciones ni esperas.
	zoom = zoom_normal

func _process(delta):
	var destino = zoom_normal
	if Input.is_action_pressed("ui_right"):
		destino = zoom_acelerar
	
	zoom = zoom.lerp(destino, velocidad_zoom * delta)
