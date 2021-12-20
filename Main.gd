extends Node2D

var Room= preload("res://Room.tscn")
var Player= preload("res://Player.tscn")
var SpawnSkel= preload("res://SkeletonSpawner.tscn")
var Door= preload("res://Door.tscn")

onready var Map = $TileMap

export (PackedScene) var Mob
export (PackedScene) var Skel


var score



var tile_size = 32
var num_rooms = 20
var min_size =9
var max_size = 16
var hspread = 500
var cull = 0.5

var path 
var start_room = null
var end_room = null
var play_mode = false
var player = null
var door = null

var upper_room=null
var lower_room=null

var music=true

func _ready():
	randomize()
	
	#new_game()

func game_over():
	$Music.play()
	$EndSound.play()
	$ScoreTimer.stop()
	$MobTimer.stop()
	$Player.hide()
	$HUD.show_game_over()
	get_tree().call_group("Mobs", "queue_free")
	yield(get_tree().create_timer(0.2),'timeout')
	get_tree().call_group("Skeleton", "queue_free")
	yield(get_tree().create_timer(0.2),'timeout')
	get_tree().call_group("Door", "queue_free")
	yield(get_tree().create_timer(0.2),'timeout')
	get_tree().call_group("SpawnSkeleton", "queue_free")
	yield(get_tree().create_timer(0.2),'timeout')
	$MobPath.curve.clear_points()

func win_game():
	$ScoreTimer.stop()
	$MobTimer.stop()
	$HUD.show_win(score)
	get_tree().call_group("Mobs", "queue_free")
	get_tree().call_group("Door", "queue_free")
	get_tree().call_group("Skeleton", "queue_free")
	get_tree().call_group("SpawnSkeleton", "queue_free")
	yield(get_tree().create_timer(0.2),'timeout')
	
func new_game():
	score = 0
	make_rooms()
	yield(get_tree().create_timer(2),'timeout')
	create_mob_path()
	create_skel_spawn()
	$StartTimer.start()
	$HUD.update_score(score)
	$HUD.show_message("Get Ready")
	turn_off_room_collisions()
	#player = Player.instance()
	#add_child(player)
	$Player.position=start_room.position
	$Player.show()
	

	
	if music:
		$Music.play()
	door = Door.instance()
	add_child(door)
	door.position=end_room.position
	play_mode = true
	
	



func make_rooms():
# warning-ignore:unused_variable
	for i in range(num_rooms) :
		var pos = Vector2(rand_range(-hspread, hspread),0)
		var r = Room.instance()
		var w = min_size + randi() % (max_size - min_size)
		var h = min_size + randi()% (max_size-min_size)
		r.make_room(pos,Vector2(w,h)*tile_size)
		$Rooms.add_child(r)
	#wait room to stop
	yield(get_tree().create_timer(.5),'timeout')
	
	var room_positions = []
	
	for room in $Rooms.get_children():
		if randf()<cull:
			room.queue_free()
		else:	
			room.mode=RigidBody2D.MODE_STATIC
			room_positions.append(Vector3(room.position.x,room.position.y,0))
	yield(get_tree(), 'idle_frame')
	path = find_mst(room_positions)
	#yield(get_tree().create_timer(1.1),'timeout')
	make_map()
	
func _draw():
	for room in $Rooms.get_children():
		draw_rect(Rect2(room.position - room.size, room.size *2),Color(32,228,0),false)
		
	if path:
		for p in path.get_points():
			for c in path.get_point_connections(p):
				var pp = path.get_point_position(p)
				var cp = path.get_point_position(c)
				draw_line(Vector2(pp.x,pp.y),Vector2(cp.x,cp.y),
							Color(1,1,0),15,true)
		
			

# warning-ignore:unused_argument
func _process(delta):
	update()

func turn_off_room_collisions():
	for room in $Rooms.get_children():
		room.get_node("CollisionShape2D").set_deferred("disabled", true)


func _input(event):
	# Spacebar restarts and creates a new set of rooms
	#if event.is_action_pressed('ui_select'):
		
		#Map.clear()
		#for n in $Rooms.get_children():
		#	n.queue_free()
		#path = null
	#	start_room = null
	#	end_room = null
	#	upper_room=null
	#	lower_room=null
	#	door=null
		
	#	make_rooms()
	#	new_game()
	# Tab generates the TileMap
	if event.is_action_pressed('ui_focus_next'):
		make_map()
	# Esc spawns a player to explore the map
	if event.is_action_pressed('ui_cancel'):
		turn_off_room_collisions()
		player = Player.instance()
		add_child(player)
		player.position = start_room.position
		play_mode = true
	
	
func find_mst(nodes):
	
	var path = AStar.new()
	path.add_point(path.get_available_point_id(), nodes.pop_front())
	
	while nodes:
		var min_dist = INF
		var min_p = null
		var p = null
		for p1 in path.get_points():
			p1 = path.get_point_position(p1)
			
			for p2 in nodes:
				if p1.distance_to(p2) < min_dist:
					min_dist = p1.distance_to(p2)
					min_p = p2
					p=p1
		var n = path.get_available_point_id()
		path.add_point(n,min_p)
		path.connect_points(path.get_closest_point(p),n)
		nodes.erase(min_p)
	return path
	
		
		
func make_map():
	find_start_room()
	find_end_room()
	Map.clear()
	var full_rect=Rect2()
	for room in $Rooms.get_children():
		var r = Rect2(room.position-room.size,
				room.get_node("CollisionShape2D").shape.extents*2)
		full_rect = full_rect.merge(r)
	var topleft = Map.world_to_map(full_rect.position)+Vector2(-100,-100)
	var bottomright= Map.world_to_map(full_rect.end)+Vector2(100,100)
	for x in range(topleft.x, bottomright.x):
		for y in range(topleft.y,bottomright.y):
			var t = Vector2(x,y)
		
			Map.set_cell(x,y,1)
			Map.update_bitmask_area(t) 
		
	

	var corridors = []
	for room in $Rooms.get_children():
		var s = (room.size / tile_size).floor()
# warning-ignore:unused_variable
		var pos = Map.world_to_map(room.position)
		var ul = (room.position / tile_size).floor() -s
		for x in range (2, s.x * 2 - 1):
			for y in range (2, s.y * 2 - 1):
				var location = Vector2(ul.x+x,ul.y+y)
				Map.set_cellv(location, 0)
				Map.update_bitmask_area(location)
		
		var p = path.get_closest_point(Vector3(room.position.x, room.position.y,0 ))
		for conn in path.get_point_connections(p):
			if not conn in corridors:
				var start = Map.world_to_map(Vector2(path.get_point_position(p).x,
													path.get_point_position(p).y))
				var end = Map.world_to_map(Vector2(path.get_point_position(conn).x,
													path.get_point_position(conn).y))	
				carve_path(start,end)
			corridors.append(p)

func carve_path(pos1,pos2):
	
	var x_diff = sign(pos2.x - pos1.x)
	var y_diff = sign(pos2.y-pos1.y)
	if x_diff == 0:x_diff = pow(-1.0, randi()%2)
	if y_diff == 0:y_diff = pow(-1.0, randi()%2)
	
	
	
	var x_y = pos1
	var y_x = pos2
	if (randi()%2)>0:
		x_y=pos2
		y_x=pos1
	
	var lar=6 	#Largeur des coulours
	
	if(x_diff>0):
		for x in range(pos1.x-lar/2, pos2.x,x_diff):
			var location = Vector2(x,x_y.y)
			Map.set_cellv(location, 0)
			Map.update_bitmask_area(location)	
		
			for i in range(0,lar):
				location = Vector2(x, x_y.y+y_diff+i)
				Map.set_cellv(location, 0)
				Map.update_bitmask_area(location)
	if(x_diff<0):
		for x in range(pos1.x+lar/2, pos2.x,x_diff):
			var location = Vector2(x,x_y.y)
			Map.set_cellv(location, 0)
			Map.update_bitmask_area(location)	
		
			for i in range(0,lar):
				location = Vector2(x, x_y.y+y_diff+i)
				Map.set_cellv(location, 0)
				Map.update_bitmask_area(location)		
		
	if (y_diff>0):
		for y in range(pos1.y-lar/2, pos2.y, y_diff):
			var location = Vector2(y_x.x,y)
			Map.set_cellv(location, 0)
			Map.update_bitmask_area(location)	
			for i in range(0,lar):
				location = Vector2(y_x.x + x_diff+i, y)
				Map.set_cellv(location, 0)
				Map.update_bitmask_area(location)
	if (y_diff<0):
		for y in range(pos1.y+lar/2, pos2.y, y_diff):
			var location = Vector2(y_x.x,y)
			Map.set_cellv(location, 0)
			Map.update_bitmask_area(location)	
			for i in range(0,lar):
				location = Vector2(y_x.x + x_diff+i, y)
				Map.set_cellv(location, 0)
				Map.update_bitmask_area(location)
		
		
func find_start_room():
	var min_x = INF
	for room in $Rooms.get_children():
		if room.position.x < min_x:
			start_room = room
			min_x = room.position.x
			
func find_upper_room():
	var max_y = INF
	for room in $Rooms.get_children():
		if room.position.y < max_y:
			upper_room = room
			max_y = room.position.y

func find_lower_room():
	var min_y = -INF
	for room in $Rooms.get_children():
		if room.position.y > min_y:
			lower_room = room
			min_y = room.position.y

func find_end_room():
	var max_x = -INF
	for room in $Rooms.get_children():
		if room.position.x > max_x:
			end_room = room
			max_x = room.position.x

func _on_MobTimer_timeout():
	# Choose a random location on Path2D.
	$MobPath/MobSpawnLocation.offset = randi()
	# Create a Mob instance and add it to the scene.
	var linear_velocity = Vector2.ZERO
	var mob = Mob.instance()
	add_child(mob)
	# Set the mob's direction perpendicular to the path direction.
	var direction= $MobPath/MobSpawnLocation.rotation + PI / 2
	# Set the mob's position to a random location.
	mob.position = $MobPath/MobSpawnLocation.position
	# Add some randomness to the direction.
	direction += rand_range(-PI/4, PI/4)
	mob.rotation = direction
	# Set the velocity (speed & direction).
	if(linear_velocity==Vector2.ZERO):
		
		linear_velocity = Vector2(rand_range(mob.min_speed, mob.max_speed), 0)
		linear_velocity = linear_velocity.rotated(direction)
		#print(linear_velocity)
		mob.vitesse=linear_velocity
	mob.connect("hit",self,"game_over")	
	#remove_child(mob)

func create_mob_path():
	find_lower_room()
	find_upper_room()
		
	$MobPath.curve.add_point(Vector2(start_room.position.x+1000,upper_room.position.y-1000))
	$MobPath.curve.add_point(Vector2(end_room.position.x,upper_room.position.y-1000))
	$MobPath.curve.add_point(Vector2(end_room.position.x+1000,lower_room.position.y+1000))
	$MobPath.curve.add_point(Vector2(start_room.position.x,lower_room.position.y+1000))

func create_skel_spawn():
	
	for room in $Rooms.get_children():
		if room!=start_room :
			var skel=SpawnSkel.instance()
			add_child(skel)
			skel.connect("hit",self,"game_over")
			skel.position=room.position
			skel.spawn_area=Rect2(room.position-room.size+Vector2(100,100),(room.get_node("CollisionShape2D").shape.extents*2)+Vector2(-200,-200))
	
func _on_StartTimer_timeout():
	$MobTimer.start()
	$ScoreTimer.start()





func _on_ScoreTimer_timeout():
	score += 1
	$HUD.update_score(score)




func _on_HUD_musicon():
	music=true
	print("on")
	#pass # Replace with function body.


func _on_HUD_musicoff():
	$Music.stop()
	music=false
	print("off")
	#pass # Replace with function body.
