extends Camera2D

# Paradox-style RTS Camera
# 1. WASD or Arrow Keys to Pan
# 2. Scroll Wheel to Zoom (clamped)
# 3. Middle Mouse Drag to Pan

@export var pan_speed: float = 500.0
@export var zoom_speed: float = 0.1
@export var min_zoom: float = 0.5
@export var max_zoom: float = 3.0

var target_zoom: Vector2 = Vector2.ONE
var is_dragging: bool = false
var drag_start: Vector2

func _ready():
	target_zoom = zoom

func _process(delta):
	# Keyboard Panning
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	position += input_dir * pan_speed * (1.0 / zoom.x) * delta
	
	# Smooth Zoom
	zoom = zoom.lerp(target_zoom, 10.0 * delta)

func _unhandled_input(event):
	# Zooming
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_zoom += Vector2(zoom_speed, zoom_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_zoom -= Vector2(zoom_speed, zoom_speed)
		
		# Clamp Zoom
		target_zoom.x = clamp(target_zoom.x, min_zoom, max_zoom)
		target_zoom.y = clamp(target_zoom.y, min_zoom, max_zoom)

		# Middle Mouse Pan
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				is_dragging = true
				drag_start = event.position
			else:
				is_dragging = false
	
	if event is InputEventMouseMotion and is_dragging:
		var delta = drag_start - event.position
		position += delta * (1.0 / zoom.x)
		drag_start = event.position
