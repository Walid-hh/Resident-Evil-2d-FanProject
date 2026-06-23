class_name InventoryQuantityResult extends RefCounted

enum Reason {
	OK,
	INVALID_ITEM,
	UNKNOWN_ITEM,
	NOT_ENOUGH_QUANTITY,
	MAX_QUANTITY_REACHED,
}

var success := false
var reason := Reason.OK
var accepted_quantity := 0
var leftover_quantity := 0


func _init(
	p_success := false,
	p_reason := Reason.OK,
	p_accepted_quantity := 0,
	p_leftover_quantity := 0
) -> void:
	success = p_success
	reason = p_reason
	accepted_quantity = maxi(p_accepted_quantity, 0)
	leftover_quantity = maxi(p_leftover_quantity, 0)
