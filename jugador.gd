extends RigidBody2D

# =====================
# VARIABLES
# =====================
var ruedas = []

var velocidad = 120000
var torque_aire = 2000000
var torque_suelo = 500000
var fuerza_enderezar = 20000000

# 👉 BOOST REAL
var boost_activo = false
var tiempo_boost = 0.0
var duracion_boost = 1.5
var fuerza_boost = 210000

# 👉 DOBLE TAP
var ultimo_tap = 0.0
var ventana_tap = 0.25

# =====================
# READY
# =====================
func _ready():
	# Valores de peso y gravedad
	mass = 20
	gravity_scale = 5
	
	# Registro de componentes de ruedas
	if has_node("RuedasUnidas1"): ruedas.append($RuedasUnidas1)
	if has_node("RuedasUnidas2"): ruedas.append($RuedasUnidas2)
	
	for r in ruedas:
		if r is RigidBody2D:
			r.can_sleep = false
			# Evitar que las ruedas choquen con el propio chasis
			r.add_collision_exception_with(self)

# =====================
# PHYSICS
# =====================
func _physics_process(delta):
	if freeze: return

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
		if tiempo_boost <= 0:
			boost_activo = false

	# --- TRANSMISIÓN A LAS RUEDAS ---
	if right_hold:
		for r in ruedas:
			r.apply_torque_impulse(velocidad * delta * 60)
		
		if boost_activo:
			apply_central_impulse(transform.x * fuerza_boost * delta)

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
	if not _en_suelo() and Input.is_action_pressed("enderezar") and _boca_abajo():
		apply_torque_impulse(-rotation * fuerza_enderezar * delta)

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

func _boca_abajo():
	var angle = posmod(rotation, TAU)
	return angle > PI * 0.5 and angle < PI * 1.5

# =====================
# SISTEMA DE MUERTE Y EXPLOSIÓN
# =====================

func _on_detector_de_muerte_area_entered(area: Area2D) -> void:
	# Filtro de colisiones para evitar muertes accidentales
	if area.name == "Activar Trampa" or "diamante" in area.name.to_lower():
		return 
	
	explotar()

func explotar():
	if freeze: return
	freeze = true
	
	# 1. Fijar la cámara para que no siga al coche invisible
	var cam = get_viewport().get_camera_2d()
	if cam:
		var pos_actual_cam = cam.global_position
		cam.top_level = true 
		cam.global_position = pos_actual_cam

	# 2. Generar explosión de partículas
	if has_node("CPUParticles2D"):
		var p = $CPUParticles2D
		p.top_level = true
		p.global_position = global_position
		p.emitting = true
		p.restart()

	# 3. Ocultar el vehículo
	self.modulate.a = 0 
	self.global_position = Vector2(-9999, -9999) 

	# 4. Reinicio de nivel con retardo
	await get_tree().create_timer(1.2).timeout
	get_tree().reload_current_scene()
