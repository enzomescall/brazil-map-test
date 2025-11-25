extends Node

# This script acts as the "Grand Strategy" engine running in the background.
# It controls time, dates, and global economy.

signal date_changed(new_date_string)
signal resources_updated(total_resources)

var day: int = 1
var month: int = 1
var year: int = 2025

var is_paused: bool = false
var game_speed: float = 1.0 # Seconds per day
var time_accumulator: float = 0.0

# Reference to map manager to access provinces
@export var map_manager: Node2D

func _process(delta):
	if is_paused:
		return
		
	time_accumulator += delta
	
	if time_accumulator >= game_speed:
		time_accumulator = 0.0
		advance_day()

func advance_day():
	day += 1
	if day > 30: # Simplified 30-day months
		day = 1
		month += 1
		if month > 12:
			month = 1
			year += 1
			
	# Process Economic Tick for all provinces
	var daily_national_income = 0.0
	
	for key in map_manager.province_registry:
		var province = map_manager.province_registry[key]
		# Run province simulation
		province.process_turn(0.15) # 15% tax rate example
		daily_national_income += province.current_resources
		
	# Emit signals for UI to update
	var date_str = str(day) + "/" + str(month) + "/" + str(year)
	date_changed.emit(date_str)
	resources_updated.emit(daily_national_income)

func set_speed(speed: int):
	game_speed = speed

func toggle_pause():
	is_paused = !is_paused
