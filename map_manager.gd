extends Node2D

# SIGNALS
signal province_selected(province_data)

# CONFIGURATION
@export var province_map_texture: Texture2D # The distinct color map
@export var visual_map_sprite: Sprite2D     # The pretty map the user sees

# STATE
var map_image: Image
var province_registry: Dictionary = {}
var selected_province: ProvinceData = null

func _ready():
	# 1. Load the image data from the texture for pixel reading
	# NOTE: In Godot Import settings for the texture, enable "Read/Write" access!
	if province_map_texture:
		map_image = province_map_texture.get_image()
	
	# 2. Initialize Brazil Data (Mock Data)
	# In a real game, this would loop through a CSV file
	setup_brazil_data()

func setup_brazil_data():
	# Define colors matching your distinct color map image
	# Example: Amazonas is Green, Sao Paulo is Blue, etc.
	
	# Amazonas (Pure Green)
	register_province("Amazonas", Color(0, 1, 0, 1), 4200000, 100.0)
	
	# São Paulo (Pure Blue)
	register_province("São Paulo", Color(0, 0, 1, 1), 44000000, 600.0)
	
	# Rio de Janeiro (Pure Red)
	register_province("Rio de Janeiro", Color(1, 0, 0, 1), 17000000, 200.0)
	
	# Minas Gerais (Yellow)
	register_province("Minas Gerais", Color(1, 1, 0, 1), 21000000, 180.0)

func register_province(p_name, p_color, p_pop, p_gdp):
	var new_prov = ProvinceData.new(p_name, p_color, p_pop, p_gdp)
	# We use the color string as the key for fast lookup
	province_registry[p_color.to_html(false)] = new_prov

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		handle_click(get_global_mouse_position())

func handle_click(global_pos: Vector2):
	# Convert global world position to local sprite pixel coordinates
	var local_pos = visual_map_sprite.to_local(global_pos)
	
	# Adjust for sprite centering logic if necessary. 
	# Assuming Sprite is centered:
	var texture_size = province_map_texture.get_size()
	var pixel_x = local_pos.x + (texture_size.x / 2)
	var pixel_y = local_pos.y + (texture_size.y / 2)
	
	# Check bounds
	if pixel_x < 0 or pixel_x >= texture_size.x or pixel_y < 0 or pixel_y >= texture_size.y:
		return # Clicked outside map
	
	# Get color from the data map
	var clicked_color = map_image.get_pixel(int(pixel_x), int(pixel_y))
	
	# Lookup province
	var color_key = clicked_color.to_html(false) # Convert to Hex String (e.g. "ff0000")
	
	if province_registry.has(color_key):
		selected_province = province_registry[color_key]
		province_selected.emit(selected_province)
		print("Selected: " + selected_province.name)
	else:
		print("Clicked unidentified territory. Color: " + color_key)
		selected_province = null
