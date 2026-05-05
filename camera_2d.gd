extends Camera2D

@export var zoom_normal := Vector2(0.1, 0.1) # 0.1 es demasiado cerca, 0.8 es más estándar
@export var zoom_acelerar := Vector2(0.2, 0.2) # En Camera2D, valores menores = Zoom In (más cerca)
@export var velocidad_zoom := 1

var coche = null

func _ready():
	# Buscamos al coche una sola vez al inicio para ahorrar recursos
	_obtener_coche()

func _process(delta):
	# Intentamos obtener el coche si aún no lo tenemos (por si aparece después)
	if not is_instance_valid(coche):
		_obtener_coche()
	
	var destino = zoom_normal
	var puede_hacer_zoom = false

	# Verificamos si el coche existe y tiene la variable 'vivo'
	if coche and "vivo" in coche and coche.vivo:
		puede_hacer_zoom = true

	# Lógica de decisión del destino
	if puede_hacer_zoom and Input.is_action_pressed("ui_right"):
		destino = zoom_acelerar
	else:
		destino = zoom_normal
	
	# Aplicamos el suavizado
	zoom = zoom.lerp(destino, velocidad_zoom * delta)

func _obtener_coche():
	# Primero intentamos por grupo (Recomendado: añade tu coche al grupo "jugador")
	coche = get_tree().get_first_node_in_group("jugador") 
	
	# Si no, buscamos por nombre en el padre
	if not coche:
		coche = get_parent().get_node_or_null("jugador")
