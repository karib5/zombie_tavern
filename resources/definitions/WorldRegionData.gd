class_name WorldRegionData
extends Resource

## Foundational metadata for one world region - the current prototype map
## is logically split into a handful of these as a test of the
## architecture, not a redesign. A future large hand-designed world would
## have many more instances of this exact same Resource, one per region.
enum RegionType { CENTRAL, FOREST, FARMLAND, MINING, WILDERNESS, TOWN, RIVER, RUINS }

## Matches the world_region value persistent objects in this region use
## for their save keys (see ResourceNode.save_id, FarmPlot.save_id, ...).
@export var region_id: String = ""
@export var display_name: String = ""
@export var region_type: RegionType = RegionType.WILDERNESS

## Coarse difficulty rating - not consumed by any system yet, just data
## for future spawn/encounter tuning.
@export var difficulty: int = 1

## Region bounds in world (global) coordinates. Local-coordinate support
## (position relative to the region's own origin) is provided by
## to_local()/to_global() below rather than a second stored coordinate.
@export var bounds: Rect2 = Rect2()

## Whether a future starting-location system may offer this region as a
## spawn choice. Data only - no selection UI/logic reads this yet.
@export var starting_location_allowed: bool = false

func contains_point(world_position: Vector2) -> bool:
	return bounds.has_point(world_position)

## Local/global coordinate foundation: a position expressed relative to
## this region's own origin (bounds.position), and back. Trivial today
## (regions share one coordinate space with the prototype map), but this
## is the seam a future region that isn't just a sub-rect of one shared
## map would need.
func to_local(world_position: Vector2) -> Vector2:
	return world_position - bounds.position

func to_global(local_position: Vector2) -> Vector2:
	return local_position + bounds.position
