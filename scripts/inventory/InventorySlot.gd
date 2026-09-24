class_name InventorySlot
extends RefCounted

var item: ItemData
var quantity: int

func _init(p_item: ItemData, p_quantity: int) -> void:
	item = p_item
	quantity = p_quantity
