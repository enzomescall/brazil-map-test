extends Node2D

# NOTE: ProvinceData is now a global class defined in province_data.gd.

# SIGNALS
signal province_selected(province_data: ProvinceData)

# CONFIGURATION
@export var province_map_texture: Texture2D # The distinct color map
@export var visual_map_sprite: Sprite2D     # The pretty map the user sees
@export var province_inspector: PanelContainer # Reference to the UI Panel

# STATE
var map_image: Image
var province_registry: Dictionary = {}
var selected_province: ProvinceData = null

func _ready() -> void:
	if province_map_texture:
		map_image = province_map_texture.get_image()
	
	setup_brazil_data()
	
	if province_inspector:
		province_selected.connect(province_inspector.update_province_data)

func setup_brazil_data() -> void:
	# Use colors from your map image (Amazonas, Sao Paulo, Rio, Minas)
	register_province("Amazonas", Color.html("#00ff00"), 4200000, 100.0)
	register_province("São Paulo", Color.html("#0000ff"), 44000000, 600.0)
	register_province("Rio de Janeiro", Color.html("#ff0000"), 17000000, 200.0)
	register_province("Minas Gerais", Color.html("#ffff00"), 21000000, 180.0)

func register_province(p_name: String, p_color: Color, p_pop: int, p_gdp: float) -> void:
	var new_prov: ProvinceData = ProvinceData.new(p_name, p_color, p_pop, p_gdp)
	province_registry[p_color.to_html(false)] = new_prov

func _unhandled_input(event: InputEvent) -> void:
	# DEBUG CHECK: This print will now only show up if the mouse input is NOT blocked by UI elements.
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("--- Input received by Map Manager ---")
		handle_click(get_global_mouse_position())

func handle_click(global_pos: Vector2) -> void:
	if not map_image:
		return

	var local_pos: Vector2 = visual_map_sprite.to_local(global_pos)
	
	var texture_size: Vector2 = province_map_texture.get_size()
	var pixel_x: float = local_pos.x + (texture_size.x / 2.0)
	var pixel_y: float = local_pos.y + (texture_size.y / 2.0)
	
	if pixel_x < 0.0 or pixel_x >= texture_size.x or pixel_y < 0.0 or pixel_y >= texture_size.y:
		province_selected.emit(null) 
		return 
	
	var clicked_color: Color = map_image.get_pixel(int(pixel_x), int(pixel_y))
	var color_key: String = clicked_color.to_html(false)
	
	if province_registry.has(color_key):
		selected_province = province_registry[color_key] as ProvinceData
		print("Selected Province: " + selected_province.name)
		province_selected.emit(selected_province) 
	else:
		selected_province = null
		print("Selected Province: None (Water/Unclaimed) - Clicked Color: " + clicked_color.to_html(false))
		province_selected.emit(null)
