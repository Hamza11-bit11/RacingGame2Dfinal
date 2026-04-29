extends RigidBody2D

# =====================
# VARIABLES
# =====================
var ruedas = []

var velocidad = 240000
var torque_aire = 800000
var torque_suelo = 800000
var fuerza_enderezar = 14000000

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
	# Valores de peso y gravedad de tu imagen
	mass = 20
	gravity_scale = 5
	
	# Referencia a tus nodos por nombre
	if has_node("RuedasAdelante"): ruedas.append($RuedasAdelante)
	if has_node("RuedasAtras"): ruedas.append($RuedasAtras)
	
	for r in ruedas:
		if r is RigidBody2D:
			r.can_sleep = false

# =====================
# PHYSICS
# =====================
func _physics_process(delta):
	if freeze: return

	var right_pressed = Input.is_action_just_pressed("ui_right")
	var right_hold = Input.is_action_pressed("ui_right")
	var left = Input.is_action_pressed("ui_left")

	# --- DOBLE TAP ---
	if right_pressed:
		var ahora = Time.get_ticks_msec() / 1000.0
		if ahora - ultimo_tap < ventana_tap:
			_activar_boost()
		ultimo_tap = ahora

	if boost_activo:
		tiempo_boost -= delta
		if tiempo_boost <= 0: boost_activo = false

	# --- MOVIMIENTO RUEDAS ---
	if right_hold:
		for r in ruedas:
			r.apply_torque_impulse(velocidad * delta * 60)
		if boost_activo:
			apply_central_impulse(transform.x * fuerza_boost * delta)

	if left:
		for r in ruedas:
			r.apply_torque_impulse(-velocidad * delta * 60)

	# --- GIRO ---
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

	# --- ENDEREZAR ---
	if not _en_suelo() and Input.is_action_pressed("enderezar") and _boca_abajo():
		apply_torque_impulse(-rotation * fuerza_enderezar * delta)

# =====================
# FUNCIONES
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
# SISTEMA DE EXPLOSIÓN
# =====================

# SUSTITUYE TU FUNCIÓN DE MUERTE POR ESTA:

func _on_detector_de_muerte_area_entered(area: Area2D) -> void:
	print("🔍 He tocado un Area2D llamada: ", area.name)
	
	# 1. LISTA BLANCA: Cosas que NO matan al jugador
	# Añadimos "diamante" (o como se llame tu nodo de diamante)
	if area.name == "Activar Trampa" or "diamante" in area.name.to_lower():
		print("🛡️ Es un objeto seguro (Activador o Diamante).")
		return 
	
	# 2. Si NO es nada de lo anterior, entonces sí explota
	print("💀 EXPLOTANDO POR: ", area.name)
	explotar()
	if area.is_in_group("trampas"):
		explotar()

func explotar():
	if freeze: return
	freeze = true
	
	# 1. CONGELAR LA CÁMARA (Sea cual sea la que estés usando)
	# Obtenemos la cámara que está usando el juego en este momento
	var cam = get_viewport().get_camera_2d()
	if cam:
		var pos_actual_cam = cam.global_position
		cam.top_level = true # La soltamos de cualquier movimiento
		cam.global_position = pos_actual_cam
		print("Cámara externa congelada en: ", pos_actual_cam)

	# 2. ACTIVAR ANIMACIÓN (Las partículas sí están en el coche)
	# 1. CONGELAR CÁMARA (Restaurado)
	if has_node("Camera2D"):
		var cam = $Camera2D
		var pos_cam = cam.global_position
		cam.top_level = true
		cam.global_position = pos_cam

	# 2. ACTIVAR ANIMACIÓN / PARTÍCULAS (Restaurado)
	if has_node("CPUParticles2D"):
		var p = $CPUParticles2D
		p.top_level = true
		p.global_position = global_position
		p.emitting = true
		p.restart()

	# 3. EL COCHE DESAPARECE
	# 3. HACER DESAPARECER EL COCHE
	self.modulate.a = 0 
	self.global_position = Vector2(-9999, -9999) 

	# 4. REINICIAR
	await get_tree().create_timer(1.2).timeout
	get_tree().reload_current_scene()
