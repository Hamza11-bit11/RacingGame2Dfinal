extends Area2D

@onready var anim = $Diamanteanimated
func _ready():
	anim.play("idle")

func _on_body_entered(body):
	if body.is_in_group("jugador"):
		print("Diamante 1")
		anim.play("cojer")
		await (anim.animation_finished)
		RayanGay.Diamantes += 1
		queue_free()
	pass
