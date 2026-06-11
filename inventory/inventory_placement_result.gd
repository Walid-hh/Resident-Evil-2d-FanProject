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


static func ok(p_item: RefCounted = null) -> InventoryPlacementResult:
	return InventoryPlacementResult.new(true, Reason.OK, p_item)


static func fail(p_reason: Reason, p_item: RefCounted = null) -> InventoryPlacementResult:
	return InventoryPlacementResult.new(false, p_reason, p_item)


func _init(p_success := false, p_reason := Reason.OK, p_item: RefCounted = null) -> void:
	success = p_success
	reason = p_reason
	item = p_item
