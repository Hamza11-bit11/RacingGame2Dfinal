extends RigidBody2D

# =====================
# VARIABLES
# =====================
var ruedas = []

var velocidad = 50000          # torque de las ruedas (avance)
var torque_aire = 1500000      # control de giro en el aire
var torque_suelo = 300000      # pequeño giro en el suelo

var fuerza_enderezar = 3500000 # ayuda para enderezar

# =====================
# READY
# =====================
func _ready():
	ruedas = get_tree().get_nodes_in_group("ruedas")

# =====================
# PHYSICS PROCESS
# =====================
func _physics_process(delta):
	# --- INPUTS ---
	var right = Input.is_action_pressed("ui_right")
	var left  = Input.is_action_pressed("ui_left")

	# --- AVANCE (RUEDAS) ---
	if right:
		for r in ruedas:
			r.apply_torque_impulse(velocidad * delta * 60)
	if left:
		for r in ruedas:
			r.apply_torque_impulse(-velocidad * delta * 60)

	# --- GIRO DEL COCHE ---
	if right:
		if _en_suelo():
			apply_torque_impulse(torque_suelo * delta)
		else:
			apply_torque_impulse(torque_aire * delta)

	if left:
		if _en_suelo():
			apply_torque_impulse(-torque_suelo * delta)
		else:
			apply_torque_impulse(-torque_aire * delta)

	# --- ENDEREZAR SUAVE EN EL AIRE (R) ---
	if not _en_suelo() and Input.is_action_pressed("enderezar") and _boca_abajo():
		apply_torque_impulse(-rotation * fuerza_enderezar * delta)


# =====================
# FUNCIONES
# =====================

# Detecta si alguna rueda toca el suelo
func _en_suelo():
	for r in ruedas:
		if r.get_contact_count() > 0:
			return true
	return false

# Detecta si el coche está volteado
func _boca_abajo():
	return abs(rotation) > PI * 0.5
