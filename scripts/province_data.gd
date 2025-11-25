class_name ProvinceData
extends Resource

# This is a data container for a single Brazilian state/province
# In a full game, you might load these from a JSON or CSV file

var id: int
var name: String
var color_code: Color # The unique color on the lookup map
var population: int
var gdp_billions: float
var stability: float # 0.0 to 1.0

# Dynamic Data
var current_resources: float = 0.0

func _init(_name: String, _color: Color, _pop: int, _gdp: float):
	name = _name
	color_code = _color
	population = _pop
	gdp_billions = _gdp
	stability = 1.0

# Simple simulation tick for this specific province
func process_turn(tax_rate: float):
	# Simple formula: GDP generates resources based on population efficiency
	var productivity = (gdp_billions / 100.0) * stability
	current_resources += productivity * tax_rate
