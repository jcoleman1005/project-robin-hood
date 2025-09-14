# res://data/HideoutProgressionData.gd
class_name HideoutProgressionData
extends Resource

## The Gold cost for each upgrade. Element 0 is the cost to go from level 1 to 2, etc.
@export var upgrade_costs: Array[int] = [100, 250]
## The maximum level the hideout can reach.
@export var max_level: int = 3
