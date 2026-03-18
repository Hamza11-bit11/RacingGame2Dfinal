extends Node2D

func _on_button_2_pressed() -> void:
	get_tree().change_scene_to_file("res://interface.tscn")



func _on_area_2d_body_entered_world2(_body: Node2D) -> void:
		get_tree().change_scene_to_file("res://Interface3.tscn")
