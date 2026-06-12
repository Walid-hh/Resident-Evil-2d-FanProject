class_name InventoryPlacementResult extends RefCounted

enum Reason {
	OK,
	INVALID_ITEM,
	OUT_OF_BOUNDS,
	OCCUPIED,
	NOT_FOUND,
	CANNOT_ROTATE,
	NOT_ENOUGH_SPACE,
}

var success := false
var reason := Reason.OK
var item: RefCounted
var leftover_quantity := 0


static func ok(p_item: RefCounted = null, p_leftover_quantity := 0) -> InventoryPlacementResult:
	return InventoryPlacementResult.new(true, Reason.OK, p_item, p_leftover_quantity)


static func fail(p_reason: Reason, p_item: RefCounted = null, p_leftover_quantity := 0) -> InventoryPlacementResult:
	return InventoryPlacementResult.new(false, p_reason, p_item, p_leftover_quantity)


func _init(
	p_success := false,
	p_reason := Reason.OK,
	p_item: RefCounted = null,
	p_leftover_quantity := 0
) -> void:
	success = p_success
	reason = p_reason
	item = p_item
	leftover_quantity = maxi(p_leftover_quantity, 0)
