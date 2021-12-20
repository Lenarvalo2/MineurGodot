extends KinematicBody2D
signal hit
export var min_speed = 4  # Minimum speed range.
export var max_speed = 4  # Maximum speed range.
var vitesse = Vector2.ZERO


func _ready():
	var mob_types = $AnimatedSprite.frames.get_animation_names()
	$AnimatedSprite.animation = mob_types[randi() % mob_types.size()]
	
func _process(delta):
	
	#print(vitesse)
	var collision = move_and_collide(vitesse)
	if collision:
		if (collision.collider.name=="Player"):
			emit_signal("hit")
			print("paf")
	
	
	
	
	
	
	
	
	
	
