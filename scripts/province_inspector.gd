extends PanelContainer

# --- EXPORTED REFERENCES ---
@export var name_label: Label
@export var pop_label: Label
@export var gdp_label: Label
@export var stability_label: Label
@export var resources_label: Label # Repurposed to show daily income

func _ready() -> void:
	# Start invisible
	hide()

# Public function called by map_manager when the player clicks a province
func update_province_data(data: ProvinceData) -> void:
	if data == null:
		hide()
		return
		
	if not is_instance_valid(name_label):
		return
		
	var province_data: ProvinceData = data
		
	# 1. Update the UI Text
	name_label.text = province_data.name.to_upper()
	
	# FIX: Correct formatting for thousands separator (e.g., 4,200,000)
	pop_label.text = "Population: " + "{:,}".format([province_data.population])
	
	# GDP is fixed for now
	gdp_label.text = "GDP: R$ %.1f Billion" % province_data.gdp_billions
	
	# Stability (e.g., 98.5%)
	stability_label.text = "Stability: %.1f%%" % (province_data.stability * 100.0)
	
	# Calculate Daily Income for display
	var tax_rate: float = 0.15 # 15% tax rate, matching GameManager
	var daily_income: float = province_data.process_turn(tax_rate)
	
	# Format to show the exact daily BRL contribution from this state
	resources_label.text = "Daily Income: R$ %s" % "{:,}".format([int(daily_income)])
	
	# 2. Make the panel visible
	show()
