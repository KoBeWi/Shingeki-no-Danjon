extends YSort

var leave_menu = false

func _ready():
	VisualServer.set_default_clear_color(Color(0.05, 0.05, 0.07))
	randomize()
	var siid = randi()
	print("Seed: ", siid)
	seed(siid)
#	seed(3352953944) ##DEBUG
#	seed(3136793389) #NEEDDEBUG
#   seed(3037373601)
#	seed(3179678355)
	seed(1361251209)
	$"Generator".generate(10, 10)

func _process(delta):
	if Input.is_action_just_pressed("Menu") and !leave_menu:
		$Player/Camera/UI.enable()
		get_tree().paused = true
	elif Input.is_action_just_released("Menu"):
		leave_menu = false
	
	update()

#ta funkcja to hack i ma być usunięta razem z update, gdy set_default_clear_color() będzie naprawiony
func _draw():
	var camera = $"Player/Camera"
	draw_rect(Rect2(camera.get_camera_position() - OS.get_window_size()/2, OS.get_window_size()), Color(0.05, 0.05, 0.07))