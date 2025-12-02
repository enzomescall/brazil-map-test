extends RefCounted
class_name ProvinceData

# --- Data Properties ---
var province_id: int
var province_name: String
var province_polygons: List[List[Tuple[float, float]]
var color: Color
var population: int
var gdp_billions: float # GDP stored in billions
var stability: float = 0.85 # 85% starting stability

func _init(
		province_id,
		p_name: String = "",
		p_color: Color = Color.WHITE,
		p_pop: int = 0,
		p_gdp: float = 0.0
	) -> void:
	province_name = p_name
	color = p_color
	population = p_pop
	gdp_billions = p_gdp

# Calculates daily tax income and returns it to the GameManager for the national treasury.
func process_turn(tax_rate: float) -> float:
	# Daily income calculation: (GDP * tax_rate) / 360 days
	var daily_income: float = (gdp_billions * 1_000_000_000.0) * (tax_rate / 360.0)
	
	# Stability reduces income (e.g., stability of 0.85 means 15% loss)
	daily_income *= stability
	
	return daily_income
