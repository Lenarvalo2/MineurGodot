extends Node2D

func _process(delta):
	var mouse_pos=get_local_mouse_position()+(get_viewport().size /2);
	mouse_pos = (mouse_pos /get_viewport().size)
	
	#get_parent().get_node("ColorRect").material.set_shader_param("player_position",get_parent().position)
	get_parent().get_node("ColorRect").material.set_shader_param("player_position",mouse_pos)
