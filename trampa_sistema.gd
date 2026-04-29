extends Node2D

@onready var arriba = $ParteArriba
@onready var abajo = $ParteAbajo

var activa = true

# Sube este número si quieres que se acerquen todavía más
@export var fuerza_aplastar : float = 1100.0 

func _ready():
	# Buscamos el sensor donde está ahora (dentro de ParteArriba)
	var sensor = arriba.get_node_or_null("Activar Trampa")
	if sensor:
		sensor.body_entered.connect(_on_sensor_activado)

func _on_sensor_activado(body):
	if body.name.to_lower().contains("jugador") and activa:
		activa = false
		print("🕒 Coche detectado... ¡PREPARA EL EMBESTIDA!")
		await get_tree().create_timer(1.0).timeout 
		atacar()

func atacar():
	print("🚀 ¡ZAS!")
	var tween = create_tween().set_parallel(true)
	
	# MOVIMIENTO DE CIERRE (Más distancia y más seco)
	# TRANS_QUINT hace que empiece lento y termine a toda leche
	tween.tween_property(arriba, "position:y", arriba.position.y + fuerza_aplastar, 0.12).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	tween.tween_property(abajo, "position:y", abajo.position.y - fuerza_aplastar, 0.12).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	
	# Esperamos un poco con el coche aplastado
	await get_tree().create_timer(1.0).timeout
	
	# VOLVER ABRIR (Más lento para dar tensión)
	var tween2 = create_tween().set_parallel(true)
	tween2.tween_property(arriba, "position:y", arriba.position.y - fuerza_aplastar, 0.7).set_trans(Tween.TRANS_SINE)
	tween2.tween_property(abajo, "position:y", abajo.position.y + fuerza_aplastar, 0.7).set_trans(Tween.TRANS_SINE)
	
	await tween2.finished
	activa = true
