extends CanvasLayer

# --- EXPORTED REFERENCES (MANDATORY TO DRAG IN EDITOR) ---
# These are exported to prevent the "null instance" crash. They must be linked
# manually in the Inspector after attaching the script to the TopBar node.
@export var game_manager: Node
@export var date_label: Label
@export var resources_label: Label

# --- UI References ---
# This uses the internal path lookup, which is safe since the node is inside the HUD scene.
@onready var pause_button = $HBoxContainer/SpeedControls/PauseButton

# Called when the scene is loaded
func _ready():
	# Check 1: Did the user link the GameManager?
	if not game_manager:
		print("FATAL ERROR: HUD is missing the GameManager reference! Please link it in the Inspector.")
		return
	
	# Check 2: Did the user link the Labels? (The source of the "null instance" crash)
	if not date_label or not resources_label:
		print("FATAL ERROR: UI Labels are missing! Please drag DateLabel and ResourcesLabel nodes into the Inspector slots.")
		return
		
	# Connect signals from the GameManager to update the UI
	game_manager.date_changed.connect(_on_date_changed)
	game_manager.resources_updated.connect(_on_resources_updated)
	
	# Initial UI update
	date_label.text = "DATE: 01/01/2025"
	resources_label.text = "BRL: R$ 0.0 B"

func _on_date_changed(new_date_string: String):
	# Using is_instance_valid() provides an extra layer of crash protection
	if is_instance_valid(date_label):
		date_label.text = "DATE: " + new_date_string

func _on_resources_updated(total_resources):
	if is_instance_valid(resources_label):
		# Format total resources to billions (BRL)
		var formatted_resources = "BRL: R$ %.2f B" % (total_resources / 1_000_000_000.0)
		resources_label.text = formatted_resources

# --- Button Handlers (Connected via the editor) ---

func _on_pause_button_pressed():
	game_manager.toggle_pause()
	if game_manager.is_paused:
		pause_button.text = "Resume (" + str(game_manager.game_speed) + "x)"  
	else:
		pause_button.text = "Pause"
		game_manager.set_speed(1) 

func _on_speed_1x_button_pressed():
	game_manager.set_speed(5)
	if game_manager.is_paused:
		game_manager.toggle_pause()

func _on_speed_2x_button_pressed():
	game_manager.set_speed(2)
	if game_manager.is_paused:
		game_manager.toggle_pause()

func _on_speed_5x_button_pressed():
	game_manager.set_speed(1)
	if game_manager.is_paused:
		game_manager.toggle_pause()
