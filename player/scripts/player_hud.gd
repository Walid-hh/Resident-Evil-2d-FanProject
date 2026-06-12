class_name PlayerHUD extends Control

const PLAYER_HUD_WEAPON_SLOT_SCENE := preload("res://player/ui/player_hud_weapon_slot.tscn")

@export var weapon_slots_container: HBoxContainer
@export var health_bar: ProgressBar

var _weapon_slots: Array = []
var _active_weapon_config: WeaponConfig
var _weapon_ammo_counts := {}


func _ready() -> void:
	if weapon_slots_container == null:
		weapon_slots_container = get_node_or_null("%WeaponSlotsContainer") as HBoxContainer
	if health_bar == null:
		health_bar = get_node_or_null("%HealthBar") as ProgressBar


func set_weapon_slots(weapon_configs: Array[WeaponConfig]) -> void:
	if weapon_slots_container == null:
		return

	_clear_weapon_slots()

	for weapon_config: WeaponConfig in weapon_configs:
		if weapon_config == null:
			continue

		var weapon_slot = PLAYER_HUD_WEAPON_SLOT_SCENE.instantiate()
		weapon_slots_container.add_child(weapon_slot)
		weapon_slot.setup(weapon_config)
		_weapon_slots.append(weapon_slot)

	_sync_active_weapon_slots()


func set_active_weapon_config(active_weapon_config: WeaponConfig) -> void:
	_active_weapon_config = active_weapon_config
	_sync_active_weapon_slots()


func set_weapon_ammo_counts(weapon_ammo_counts: Dictionary) -> void:
	_weapon_ammo_counts = weapon_ammo_counts.duplicate()
	_sync_weapon_ammo_counts()


func set_health_values(current_health: int, max_health: int) -> void:
	if health_bar == null:
		return

	health_bar.max_value = max_health
	health_bar.value = current_health


func _clear_weapon_slots() -> void:
	for weapon_slot in _weapon_slots:
		if weapon_slot != null:
			weapon_slot.free()

	_weapon_slots.clear()


func _sync_active_weapon_slots() -> void:
	for weapon_slot in _weapon_slots:
		if weapon_slot == null:
			continue

		weapon_slot.set_active(weapon_slot.get_weapon_config() == _active_weapon_config)

	_sync_weapon_ammo_counts()


func _sync_weapon_ammo_counts() -> void:
	for weapon_slot in _weapon_slots:
		if weapon_slot == null:
			continue

		var weapon_config: WeaponConfig = weapon_slot.get_weapon_config()
		if weapon_config == null:
			weapon_slot.set_ammo_quantity(0, false)
			continue

		var ammo_quantity := int(_weapon_ammo_counts.get(weapon_config.weapon_key, -1 if weapon_config.ammo_item_key == &"" else 0))
		weapon_slot.set_ammo_quantity(ammo_quantity, weapon_config.ammo_item_key == &"")
