extends RigidBody2D

# =====================
# VARIABLES DE DISPARO
# =====================
@export var misil_escena = preload("res://misil.tscn")
var puede_disparar = true 

# Referencia al punto de salida (Marker2D)
@onready var punto_disparo = get_node_or_null("CarBody/PuntoDisparo")

# =====================
# VARIABLES DE MOVIMIENTO
# =====================
var ruedas = []
var vivo = true 

var velocidad = 120000
var torque_aire = 1800000    
var torque_suelo = 500000
var fuerza_enderezar = 4000000000 

# 👉 BOOST
var boost_activo = false
var tiempo_boost = 0.0
var duracion_boost = 1.5
var fuerza_boost = 240000

# 👉 DOBLE TAP
var ultimo_tap = 0.0
var ventana_tap = 0.25

# =====================
# READY
# =====================
func _ready():
	mass = 17
	gravity_scale = 7
	angular_damp = 3.0 
	
	if has_node("RuedasUnidas1"): ruedas.append($RuedasUnidas1)
	if has_node("RuedasUnidas2"): ruedas.append($RuedasUnidas2)
	
	for r in ruedas:
		if r is RigidBody2D:
			r.can_sleep = false
			r.add_collision_exception_with(self)

# =====================
# PHYSICS (Movimiento y Disparo)
# =====================
func _physics_process(delta):
	if freeze or not vivo: return 

	# --- LÓGICA DE DISPARO (ESPACIO) ---
	if Input.is_action_just_pressed("ui_accept") and puede_disparar:
		disparar_misil()

	var right_pressed = Input.is_action_just_pressed("ui_right")
	var right_hold = Input.is_action_pressed("ui_right")
	var left = Input.is_action_pressed("ui_left")

	# --- LÓGICA DOBLE TAP (BOOST) ---
	if right_pressed:
		var ahora = Time.get_ticks_msec() / 1000.0
		if ahora - ultimo_tap < ventana_tap:
			_activar_boost()
		ultimo_tap = ahora

	if boost_activo:
		tiempo_boost -= delta
		if tiempo_boost <= 0: boost_activo = false

	# --- TRANSMISIÓN A LAS RUEDAS ---
	if right_hold:
		for r in ruedas:
			r.apply_torque_impulse(velocidad * delta * 60)
		
		if boost_activo:
			var fuerza_dir = Vector2(transform.x.x, 0).normalized()
			apply_central_impulse(fuerza_dir * fuerza_boost * delta)

	elif left:
		for r in ruedas:
			r.apply_torque_impulse(-velocidad * delta * 60)

	# --- SISTEMA DE BALANCE (GIRO) ---
	if right_hold:
		if _en_suelo():
			apply_torque_impulse(torque_suelo * delta)
		else:
			apply_torque_impulse(torque_aire * delta)

	if left:
		if _en_suelo():
			apply_torque_impulse(-torque_suelo * delta)
		else:
			apply_torque_impulse(-torque_aire * delta)

	# --- SISTEMA DE EMERGENCIA (ENDEREZAR) ---
	if not _en_suelo() and Input.is_action_pressed("enderezar"):
		var target_rotation = 0 
		var diferencia = wrapf(target_rotation - rotation, -PI, PI)
		apply_torque(diferencia * fuerza_enderezar * delta)

# =====================
# FUNCIONES DE DISPARO
# =====================
func disparar_misil():
	puede_disparar = false
	var m = misil_escena.instantiate()
	
	m.scale = Vector2(5, 5) # Tamaño medio
	
	# Lo posicionamos en el capó
	if punto_disparo:
		m.global_position = punto_disparo.global_position
	else:
		# Si no tienes Marker2D, adelántalo un poco
		var offset = Vector2(150, 0).rotated(rotation)
		m.global_position = global_position + offset
	
	m.rotation = rotation 
	
	# ¡YA NO HAY LÍNEAS DE EXCEPCIÓN AQUÍ!
	
	get_parent().add_child(m)
	
	await get_tree().create_timer(0.6).timeout
	puede_disparar = true 
# =====================
# FUNCIONES AUXILIARES
# =====================
func _activar_boost():
	boost_activo = true
	tiempo_boost = duracion_boost

func _en_suelo():
	for r in ruedas:
		if r.get_contact_count() > 0: return true
	return false

# =====================
# SISTEMA DE MUERTE
# =====================
func _on_detector_de_muerte_area_entered(area: Area2D) -> void:
	if not vivo: return
	var nombre = area.name.to_lower()
	
	if "deteccion" in nombre or "activar" in nombre or "diamante" in nombre or "portal" in nombre or "punto" in nombre:
		return 
	
	if area.name == "BocaColision":
		ser_devorado()
		return

	explotar()

func explotar():
	# 1. Guardamos la posición antes del caos
	var pos_impacto = global_position
	
	_preparar_muerte()
	
	# 2. INSTANCIAR EXPLOSIÓN
	var exp = misil_escena.instantiate()
	get_parent().add_child(exp)
	exp.global_position = pos_impacto
	exp.scale = Vector2(8, 8)
	if exp.has_method("explotar"):
		exp.explotar()

	# 3. CÁMARA CON ZOOM MÍNIMO
	var cam = get_viewport().get_camera_2d()
	if cam:
		cam.position_smoothing_enabled = false 
		cam.top_level = true 
		cam.global_position = pos_impacto
		
		# Forzamos que empiece en el zoom normal (1, 1)
		cam.zoom = Vector2(0.3, 0.3)
		
		var tw = create_tween().set_parallel(true)
		
		# --- ZOOM MUY PEQUEÑO (1.05) ---
		# Es solo un 5% de acercamiento. Casi nada.
		tw.tween_property(cam, "zoom", Vector2(0.2, 0.2), 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
		# Centramos la cámara suavemente
		tw.tween_property(cam, "global_position", pos_impacto, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	await get_tree().create_timer(1.8).timeout
	get_tree().reload_current_scene()

func ser_devorado():
	_preparar_muerte()
	if has_node("EfectoMuerte"):
		$EfectoMuerte.visible = true
		var tw = create_tween().set_parallel(true)
		tw.tween_property($EfectoMuerte/TrozoDelantero, "position", Vector2(30, 10), 0.6)
		tw.tween_property($EfectoMuerte/TrozoTrasero, "position", Vector2(-30, 10), 0.6)
		tw.tween_property($EfectoMuerte, "modulate:a", 0, 0.5).set_delay(0.8)

func _preparar_muerte():
	if not vivo: return
	vivo = false 
	freeze = true
	linear_velocity = Vector2.ZERO 
	angular_velocity = 0
	
	# --- AQUÍ YA NO HAY NADA DE CÁMARA (LIMPIO) ---
	
	if has_node("CarBody"): 
		$CarBody.visible = false
	else: 
		self.modulate.a = 0
	
	for r in ruedas:
		r.visible = false
		r.freeze = true
		r.process_mode = PROCESS_MODE_DISABLED
	
	set_physics_process(false)
	set_process(false)
	collision_layer = 0
	collision_mask = 0
