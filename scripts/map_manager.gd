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
	
	var data = DataLoader.load_provinces_from_json()
	if data.has("provinces"):
		for p in data["provinces"]:
			_register_province_from_json(p)
	
	if province_inspector:
		province_selected.connect(province_inspector.update_province_data)

func _register_province_from_json(entry: Dictionary) -> void:
	# --- Required fields ---
	var name: String = entry.get("name", "")
	var color_html: String = entry.get("color_html", "")

	if name == "" or color_html == "":
		push_warning("Skipping province due to missing name or color_html: %s" % entry)
		return

	var color: Color = Color.html(color_html)

	if color == null:
		push_warning("Invalid color hex '%s' for province %s" % [color_html, name])
		return

	# --- Optional fields with defaults ---
	var population: int = entry.get("population", 0)
	var gdp_billions: float = entry.get("gdp_billions", 0.0)

	register_province(name, color, population, gdp_billions)

func register_province(
		name: String,
		color: Color,
		population: int,
		gdp_billions: float
	) -> void:

	var province := ProvinceData.new()
	province.name = name
	province.population = population
	province.gdp_billions = gdp_billions
	province.color = color

	# Convert color to the same key format your SVG parsing uses
	var html_key := color.to_html(false)  # "rrggbb"

	# Store in registry > key: "rrggbb"
	province_registry[html_key] = province

	# Optional: if you track a list of provinces
	if not provinces.has(province):
		provinces.append(province)


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
