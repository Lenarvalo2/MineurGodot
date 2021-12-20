extends Node2D
signal hit

# Nodes references
var tilemap
var player

# Spawner variables
export var spawn_area : Rect2 = Rect2(50, 150, 700, 700)
export var max_skeletons = 50
export var start_skeletons = 0
var skeleton_count = 0
var skeleton_scene = preload("res://Skeleton.tscn")

# Random number generator
var rng = RandomNumberGenerator.new()

func instance_skeleton():
	# Instance the skeleton scene and add it to the scene tree
	var skeleton = skeleton_scene.instance()
	get_parent().add_child(skeleton)
	skeleton.connect("hit",self,"hit")
	# Place the skeleton in a valid position
	var valid_position = false
	while not valid_position:
		skeleton.position.x = spawn_area.position.x + rng.randf_range(0, spawn_area.size.x)
		skeleton.position.y = spawn_area.position.y + rng.randf_range(0, spawn_area.size.y)
		valid_position = test_position(skeleton.position)
	print("paf")
	# Play skeleton's birth animation
	skeleton.arise()
	

func hit():
	emit_signal("hit")

func test_position(position : Vector2):
	# Check if the cell type in this position is grass or sand
	var cell_coord = tilemap.world_to_map(position)
	var cell_type_id = tilemap.get_cellv(cell_coord)
	var grass_or_sand = (cell_type_id == 0) 
	
	# Check if there's a tree in this position


	
	# If the two conditions are true, the position is valid
	return grass_or_sand 


func _ready():
	# Get tilemaps references
	tilemap = get_parent().get_node("TileMap")
	player = get_parent().get_node("Player")
	
	# Initialize random number generator
	rng.randomize()
	
	# Create skeletons
	for i in range(start_skeletons):
		instance_skeleton()
	skeleton_count = start_skeletons


func _on_Timer_timeout():
	var player_relative_position = player.position - position
	
	# Every second, check if we need to instantiate a skeleton
	if skeleton_count < max_skeletons and player_relative_position.length() <= spawn_area.size.x:
		instance_skeleton()
		skeleton_count = skeleton_count + 1
