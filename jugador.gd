extends RigidBody2D

# =====================
# VARIABLES (Valores del Script 1)
# =====================
var ruedas = []
var vivo = true # De Script 2: Control de vida

var velocidad = 120000
var torque_aire = 1800000    # Script 1: Más suave
var torque_suelo = 500000
var fuerza_enderezar = 4000000000 # Script 1: Mucho más potente

# 👉 BOOST REAL (Valores del Script 1)
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
	# Valores de masa y gravedad del Script 1
	mass = 17
	gravity_scale = 7
	angular_damp = 3.0 # De Script 1: Para evitar giros locos
	
	if has_node("RuedasUnidas1"): ruedas.append($RuedasUnidas1)
	if has_node("RuedasUnidas2"): ruedas.append($RuedasUnidas2)
	
	for r in ruedas:
		if r is RigidBody2D:
			r.can_sleep = false
			r.add_collision_exception_with(self)

# =====================
# PHYSICS (Movimiento combinado)
# =====================
func _physics_process(delta):
	if freeze or not vivo: return # De Script 2: Bloqueo si está muerto

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
			# Lógica de dirección del Script 1 (más precisa)
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
	# He puesto la lógica del Script 1 que es mejor (usa lerp/wrapf)
	if not _en_suelo() and Input.is_action_pressed("enderezar"):
		var target_rotation = 0 
		var diferencia = wrapf(target_rotation - rotation, -PI, PI)
		apply_torque(diferencia * fuerza_enderezar * delta)

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
# SISTEMA DE MUERTE (Estructura del Script 2)
# =====================

func _on_detector_de_muerte_area_entered(area: Area2D) -> void:
	if not vivo: return
	var nombre = area.name.to_lower()
	
	# Filtros de colisión de Script 2
	if "deteccion" in nombre or "activar" in nombre or "diamante" in nombre:
		return 
	
	if area.name == "BocaColision":
		ser_devorado()
		return

	explotar()

func explotar():
	_preparar_muerte()
	
	var particulas = get_node_or_null("CPUParticles2D")
	if particulas:
		particulas.process_mode = PROCESS_MODE_ALWAYS
		particulas.top_level = true 
		particulas.global_position = global_position
		particulas.emitting = true
		particulas.restart()

	await get_tree().create_timer(1.2).timeout
	get_tree().reload_current_scene()

func ser_devorado():
	_preparar_muerte()
	
	# Lógica visual de Script 2
	if has_node("EfectoMuerte"):
		$EfectoMuerte.visible = true
		var tw = create_tween().set_parallel(true)
		tw.tween_property($EfectoMuerte/TrozoDelantero, "position", Vector2(30, 10), 0.6)
		tw.tween_property($EfectoMuerte/TrozoTrasero, "position", Vector2(-30, 10), 0.6)
		tw.tween_property($EfectoMuerte, "modulate:a", 0, 0.5).set_delay(0.8)

	print("¡El coche ha sido partido y devorado!")

func _preparar_muerte():
	if not vivo: return
	vivo = false 
	freeze = true
	linear_velocity = Vector2.ZERO 
	angular_velocity = 0
	
	# Manejo de Cámara y Zoom (Script 2)
	var cam = get_viewport().get_camera_2d()
	if cam:
		cam.top_level = true 
		cam.global_position = cam.get_screen_center_position()
		var tw_cam = create_tween()
		tw_cam.tween_property(cam, "zoom", Vector2(1, 1), 0.3)

	# Ocultar coche
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
