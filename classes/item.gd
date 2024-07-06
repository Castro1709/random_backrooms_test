extends RefCounted

class_name Item

enum ItemIDs {AlmondWater}
##Item's volume
const ItemsVolume := {
	ItemIDs.AlmondWater:10
}
##Item's weights on kilos
const ItemsWeight := {
	ItemIDs.AlmondWater:2000
}

var amount : int
var id : ItemIDs

func _init(_id:ItemIDs,_amount:int) -> void:
	id = _id
	amount = _amount

func get_weight() -> int:
	return ItemsWeight[id] * amount

func get_volume() -> int:
	return ItemsVolume[id] * amount
