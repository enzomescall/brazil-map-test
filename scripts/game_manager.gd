extends Node

# This script acts as the "Grand Strategy" engine running in the background.

signal date_changed(new_date_string: String)
signal resources_updated(total_treasury: float)

var day: int = 1
var month: int = 1
var year: int = 2025

var is_paused: bool = false
var game_speed_setting: int = 1 
var time_accumulator: float = 0.0
var national_treasury: float = 10_000_000_000.0 # Starting with R$ 10 Billion

# MAPPING: Seconds per day (lower = faster)
const SPEED_MAP: Dictionary = {
	1: 1.0,  # 1 second per day
	2: 0.5,  # 2 days per second
	5: 0.1,  # 10 days per second
}

# Reference to map manager to access provinces
@export var map_manager: Node2D

func _process(delta: float) -> void:
	if is_paused:
		return
	
	var game_speed: float = SPEED_MAP.get(game_speed_setting, 1.0)
		
	time_accumulator += delta
	
	if time_accumulator >= game_speed:
		time_accumulator -= game_speed
		advance_day()

func advance_day() -> void:
	day += 1
	if day > 30: # Simplified 30-day months
		day = 1
		month += 1
		if month > 12:
			month = 1
			year += 1
			
	# Process Economic Tick for all provinces
	var daily_national_income: float = 0.0
	var tax_rate: float = 0.15 # 15% tax rate
	
	if map_manager and map_manager.province_registry:
		for key in map_manager.province_registry:
			# The province object is an instance of the global ProvinceData class
			var province = map_manager.province_registry[key] 
			
			# Run province simulation: calculates provincial income
			var daily_income_from_province: float = province.process_turn(tax_rate)
			
			# Collect income from province into the national treasury
			daily_national_income += daily_income_from_province
		
	# ACCUMULATE: Add daily income to the national treasury
	national_treasury += daily_national_income
	
	# Emit signals for UI to update
	var date_str: String = "%02d/%02d/%d" % [day, month, year] 
	date_changed.emit(date_str)
	resources_updated.emit(national_treasury)
	
# --- Control Functions for the UI ---

func toggle_pause() -> void:
	is_paused = not is_paused

func set_speed(speed: int) -> void:
	if SPEED_MAP.has(speed):
		game_speed_setting = speed
	if is_paused:
		is_paused = true
